// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );

    // Check if we have stored credentials
    final credentials =
        await DatabaseHelper.instance.getGoogleDriveCredentials();
    if (credentials != null) {
      final expiryDate = DateTime.parse(credentials['expiry_date']);
      if (expiryDate.isAfter(DateTime.now())) {
        // Use stored credentials
        final client = http.Client();
        _driveApi = drive.DriveApi(client);
        _isInitialized = true;
      }
    }

    _isInitialized = true;
  }

  Future<bool> isSignedIn() async {
    await _initialize();
    final credentials =
        await DatabaseHelper.instance.getGoogleDriveCredentials();
    return credentials != null;
  }

  Future<bool> signIn() async {
    try {
      await _initialize();
      final account = await _googleSignIn?.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final client = http.Client();
      _driveApi = drive.DriveApi(client);

      // Store credentials
      await DatabaseHelper.instance.saveGoogleDriveCredentials(
        accessToken: auth.accessToken!,
        refreshToken: auth
            .idToken!, // Note: In a real app, you'd want to handle refresh tokens properly
        expiryDate: DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(), // Token typically expires in 1 hour
      );

      return true;
    } catch (e) {
      debugPrint('Error signing in to Google Drive: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _initialize();
    await _googleSignIn?.signOut();
    await DatabaseHelper.instance.clearGoogleDriveCredentials();
    _driveApi = null;
  }

  Future<bool> isAutoBackupEnabled() async {
    final credentials =
        await DatabaseHelper.instance.getGoogleDriveCredentials();
    return credentials != null && credentials['auto_backup_enabled'] == 1;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await DatabaseHelper.instance.updateGoogleDriveSettings(
      autoBackupEnabled: enabled,
    );
  }

  Future<int> getBackupInterval() async {
    final credentials =
        await DatabaseHelper.instance.getGoogleDriveCredentials();
    return credentials?['backup_interval'] ?? 24;
  }

  Future<void> setBackupInterval(int hours) async {
    await DatabaseHelper.instance.updateGoogleDriveSettings(
      backupInterval: hours,
    );
  }

  Future<bool> uploadBackup(String filePath) async {
    try {
      await _initialize();
      if (_driveApi == null) return false;

      final file = File(filePath);
      final timestamp = DateTime.now().toIso8601String();
      final fileName = 'ledgerpro_backup_$timestamp.json';

      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = 'application/json';

      await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), await file.length()),
      );

      // Update last backup date
      await DatabaseHelper.instance.updateGoogleDriveSettings(
        lastBackupDate: DateTime.now(),
      );

      return true;
    } catch (e) {
      debugPrint('Error uploading backup to Google Drive: $e');
      return false;
    }
  }

  Future<String?> downloadLatestBackup() async {
    try {
      await _initialize();
      if (_driveApi == null) return null;

      final files = await _driveApi!.files.list(
        q: "name contains 'ledgerpro_backup_' and mimeType='application/json'",
        orderBy: 'createdTime desc',
        pageSize: 1,
      );

      if (files.files == null || files.files!.isEmpty) {
        return null;
      }

      final latestBackup = files.files!.first;
      final tempDir = Directory.systemTemp;
      final tempFile =
          File(path.join(tempDir.path, latestBackup.name ?? 'backup.json'));

      final response = await _driveApi!.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Properly handle the stream
      final bytes = await response.stream.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      await tempFile.writeAsBytes(bytes);

      return tempFile.path;
    } catch (e) {
      debugPrint('Error downloading backup from Google Drive: $e');
      return null;
    }
  }

  Future<bool> shouldPerformAutoBackup() async {
    try {
      final credentials =
          await DatabaseHelper.instance.getGoogleDriveCredentials();
      if (credentials == null) return false;

      final autoBackupEnabled = credentials['auto_backup_enabled'] == 1;
      if (!autoBackupEnabled) return false;

      final lastBackupDate = credentials['last_backup_date'] != null
          ? DateTime.parse(credentials['last_backup_date'])
          : null;
      if (lastBackupDate == null) return true;

      final backupInterval = credentials['backup_interval'] ?? 24;
      final nextBackupDue = lastBackupDate.add(Duration(hours: backupInterval));

      return DateTime.now().isAfter(nextBackupDue);
    } catch (e) {
      debugPrint('Error checking auto backup status: $e');
      return false;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
