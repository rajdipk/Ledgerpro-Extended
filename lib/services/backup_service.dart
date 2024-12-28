// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:archive/archive.dart';
import '../database/database_helper.dart';
import 'google_drive_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const _maxLocalBackups = 5; // Keep last 5 backups
  static const _localBackupKey = 'lastLocalBackup';
  static const _localBackupIntervalKey = 'localBackupIntervalHours';
  static const _defaultLocalBackupInterval = 24; // Daily backups by default
  static const _backupVersionKey = 'backupVersion';
  static const _currentBackupVersion = 2; // Increment when backup format changes
  static const _compressionEnabled = true;
  static const _encryptionEnabled = true;
  static const _chunkSize = 1024 * 1024; // 1MB chunks for large backups

  Timer? _backupTimer;
  final _googleDriveService = GoogleDriveService();

  Future<String> get _backupDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  void startAutoBackup() {
    stopAutoBackup();
    _backupTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkAndPerformBackup();
    });
  }

  void stopAutoBackup() {
    _backupTimer?.cancel();
    _backupTimer = null;
  }

  Future<bool> createLocalBackup() async {
    try {
      print('Starting local backup creation...');
      final directory = await _backupDirectory;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'ledgerpro_backup_$timestamp.lpb';
      final file = File('$directory/$fileName');

      print('Backup file will be created at: ${file.path}');

      // Export all businesses
      print('Connecting to database...');
      final db = await DatabaseHelper.instance.database;
      final businesses = await db.query('businesses');
      print('Found ${businesses.length} businesses to backup');
      
      // Create backup metadata
      print('Creating backup metadata...');
      final metadata = {
        'version': _currentBackupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'device': await _getDeviceInfo(),
        'checksum': '',
        'compressed': _compressionEnabled,
        'encrypted': _encryptionEnabled,
      };

      print('Backup metadata: ${jsonEncode(metadata)}');

      // Export each business
      print('Exporting business data...');
      final businessData = <Map<String, dynamic>>[];
      for (final business in businesses) {
        final businessId = business['id'] as int;
        print('Exporting business ID: $businessId');
        final data = await DatabaseHelper.instance.exportData(businessId);
        businessData.add(data);
      }

      // Create the final backup structure
      final backupData = {
        'metadata': metadata,
        'businesses': businessData,
      };

      print('Calculating checksum...');
      metadata['checksum'] = await _calculateChecksum(jsonEncode(backupData));
      backupData['metadata'] = metadata;
      print('Checksum: ${metadata['checksum']}');

      // Convert to bytes
      print('Converting data to bytes...');
      Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(backupData)));
      print('Initial data size: ${bytes.length} bytes');

      // Compress if enabled
      if (_compressionEnabled) {
        print('Compressing backup data...');
        final compressedBytes = GZipEncoder().encode(bytes);
        if (compressedBytes == null) {
          throw Exception('Compression failed');
        }
        bytes = Uint8List.fromList(compressedBytes);
        print('Compressed size: ${bytes.length} bytes (${((bytes.length / backupData.length) * 100).toStringAsFixed(1)}%)');
      }

      // Encrypt if enabled
      if (_encryptionEnabled) {
        print('Encrypting backup data...');
        bytes = await _encryptData(bytes);
        print('Encrypted size: ${bytes.length} bytes');
      }

      // Write backup file in chunks
      print('Writing backup file in chunks...');
      final sink = file.openWrite();
      var bytesWritten = 0;
      for (var i = 0; i < bytes.length; i += _chunkSize) {
        final end = (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        sink.add(chunk);
        bytesWritten += chunk.length;
        if (bytesWritten % (1024 * 1024) == 0) { // Log every MB
          print('Written: ${bytesWritten ~/ (1024 * 1024)}MB / ${bytes.length ~/ (1024 * 1024)}MB');
        }
      }
      await sink.close();
      print('Backup file written successfully: ${file.path}');

      // Update last backup time
      print('Updating backup preferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localBackupKey, DateTime.now().toIso8601String());
      await prefs.setInt(_backupVersionKey, _currentBackupVersion);

      // Clean up old backups
      print('Cleaning up old backups...');
      await _cleanupOldBackups();

      print('Local backup completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('Error creating local backup: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final directory = await _backupDirectory;
      final dir = Directory(directory);
      if (!await dir.exists()) return;

      print('Scanning backup directory: $directory');
      final files = await dir.list().where((f) => f.path.endsWith('.lpb')).toList();
      print('Found ${files.length} backup files');

      if (files.length <= _maxLocalBackups) {
        print('No cleanup needed (${files.length} <= $_maxLocalBackups)');
        return;
      }

      // Sort files by modification time, newest first
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Delete oldest files
      print('Deleting ${files.length - _maxLocalBackups} old backups');
      for (var i = _maxLocalBackups; i < files.length; i++) {
        final file = files[i];
        print('Deleting old backup: ${file.path}');
        await file.delete();
      }

      print('Cleanup completed. Remaining backups: $_maxLocalBackups');
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }

  Future<bool> restoreFromLocalBackup(String backupPath) async {
    try {
      print('Starting backup restoration from: $backupPath');
      final file = File(backupPath);
      if (!await file.exists()) {
        print('Backup file does not exist: $backupPath');
        return false;
      }

      print('Reading backup file...');
      Uint8List bytes = await file.readAsBytes();
      print('Read ${bytes.length} bytes');
      
      // Decrypt if encrypted
      if (_encryptionEnabled) {
        print('Decrypting backup data...');
        bytes = await _decryptData(bytes);
        print('Decrypted size: ${bytes.length} bytes');
      }

      // Decompress if compressed
      if (_compressionEnabled) {
        print('Decompressing backup data...');
        bytes = Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
        print('Decompressed size: ${bytes.length} bytes');
      }

      print('Parsing backup data...');
      final content = utf8.decode(bytes);
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      // Verify backup version
      print('Verifying backup version...');
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      final version = metadata['version'] as int;
      print('Backup version: $version, Current version: $_currentBackupVersion');
      
      if (version > _currentBackupVersion) {
        print('Error: Backup version $version is newer than current version $_currentBackupVersion');
        throw Exception('Backup version $version is newer than current version $_currentBackupVersion');
      }

      // Verify checksum
      print('Verifying backup integrity...');
      final storedChecksum = metadata['checksum'] as String;
      final calculatedChecksum = await _calculateChecksum(
        jsonEncode({...backupData, 'metadata': {...metadata, 'checksum': ''}})
      );
      
      print('Stored checksum: $storedChecksum');
      print('Calculated checksum: $calculatedChecksum');
      
      if (storedChecksum != calculatedChecksum) {
        print('Error: Backup file is corrupted (checksum mismatch)');
        throw Exception('Backup file is corrupted: checksum mismatch');
      }

      print('Backup integrity verified');

      // Restore each business
      final businesses = backupData['businesses'] as List;
      print('Restoring ${businesses.length} businesses...');
      
      for (final businessData in businesses) {
        if (businessData is! Map<String, dynamic>) {
          print('Invalid business data format');
          continue;
        }
        print('Restoring business: ${businessData['name']}');
        await DatabaseHelper.instance.importData(businessData);
      }

      print('Backup restoration completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('Error restoring from local backup: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<String> _calculateChecksum(String data) async {
    final bytes = utf8.encode(data);
    final digest = crypto.sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  Future<Uint8List> _encryptData(Uint8List data) async {
    // TODO: Implement proper encryption
    return data;
  }

  Future<Uint8List> _decryptData(Uint8List data) async {
    // TODO: Implement proper decryption
    return data;
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    // TODO: Implement device info gathering
    return {
      'type': 'unknown',
      'name': 'unknown',
      'os': 'unknown',
    };
  }

  Future<void> _checkAndPerformBackup() async {
    try {
      // Check and perform local backup
      if (await _shouldPerformLocalBackup()) {
        await createLocalBackup();
      }

      // Check and perform Google Drive backup
      if (await _googleDriveService.shouldPerformAutoBackup()) {
        final localBackups = await getLocalBackups();
        if (localBackups.isNotEmpty) {
          await _googleDriveService.uploadBackup(localBackups.first);
        }
      }
    } catch (e) {
      print('Error performing auto backup: $e');
    }
  }

  Future<bool> _shouldPerformLocalBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString(_localBackupKey);
    if (lastBackup == null) return true;

    final interval = prefs.getInt(_localBackupIntervalKey) ?? _defaultLocalBackupInterval;
    final lastBackupTime = DateTime.parse(lastBackup);
    final nextBackupDue = lastBackupTime.add(Duration(hours: interval));
    return DateTime.now().isAfter(nextBackupDue);
  }

  Future<void> setLocalBackupInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localBackupIntervalKey, hours);
  }

  Future<int> getLocalBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localBackupIntervalKey) ?? _defaultLocalBackupInterval;
  }

  Future<DateTime?> getLastLocalBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString(_localBackupKey);
    return lastBackup != null ? DateTime.parse(lastBackup) : null;
  }

  Future<List<String>> getLocalBackups() async {
    try {
      final directory = Directory(await _backupDirectory);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.lpb'))
          .map((e) => e.path)
          .toList();

      // Sort by creation time, newest first
      files.sort((a, b) => File(b).statSync().changed.compareTo(File(a).statSync().changed));
      return files;
    } catch (e) {
      print('Error listing local backups: $e');
      return [];
    }
  }

  Future<void> deleteLocalBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting local backup: $e');
    }
  }
}
