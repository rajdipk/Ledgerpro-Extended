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

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  static const _scopes = [drive.DriveApi.driveFileScope];
  static const _folderName = 'LedgerPro Backups';
  static const _lastBackupKey = 'lastGoogleDriveBackup';
  static const _autoBackupEnabledKey = 'autoBackupEnabled';
  static const _backupIntervalKey = 'backupIntervalHours';
  static const _defaultBackupInterval = 24; // Default to daily backups
  static const _tokenKey = 'googleDriveAccessToken';
  static const _tokenExpiryKey = 'googleDriveTokenExpiry';

  final _googleSignIn = GoogleSignIn(scopes: _scopes);
  drive.DriveApi? _driveApi;
  String? _folderId;

  Future<bool> signIn() async {
    try {
      print('Starting Google Sign In process');
      // Check if we have stored credentials
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      final tokenExpiry = prefs.getString(_tokenExpiryKey);

      if (storedToken != null && tokenExpiry != null) {
        final expiryDate = DateTime.parse(tokenExpiry);
        if (expiryDate.isAfter(DateTime.now())) {
          // Token is still valid
          print('Using stored token (expires: $tokenExpiry)');
          final client = GoogleAuthClient({
            'Authorization': 'Bearer $storedToken',
            'Content-Type': 'application/json',
          });
          _driveApi = drive.DriveApi(client);
          return true;
        }
      }

      print('No valid stored token, requesting new sign in');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('Sign in cancelled by user');
        return false;
      }

      print('Signed in as: ${account.email}');
      final auth = await account.authentication;
      if (auth.accessToken == null) {
        print('Failed to get access token');
        return false;
      }

      print('Got access token, creating Drive API client');
      final client = GoogleAuthClient({
        'Authorization': 'Bearer ${auth.accessToken}',
        'Content-Type': 'application/json',
      });
      _driveApi = drive.DriveApi(client);
      
      // Store credentials with expiry (default to 1 hour from now)
      final expiry = DateTime.now().add(const Duration(hours: 1));
      await prefs.setString(_tokenKey, auth.accessToken!);
      await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
      
      print('Sign in completed successfully');
      return true;
    } catch (e) {
      print('Error during sign in: $e');
      return false;
    }
  }

  Future<void> _storeCredentials(String accessToken, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
  }

  Future<bool> _signInWithServiceAccount() async {
    try {
      // Load credentials from the JSON file
      final credentialsFile = File('windows/flutter/google_sign_in_windows.json');
      if (!await credentialsFile.exists()) {
        debugPrint('Credentials file not found');
        return false;
      }

      final credentials = jsonDecode(await credentialsFile.readAsString());
      final clientId = credentials['installed']['client_id'];
      final clientSecret = credentials['installed']['client_secret'];

      // Create OAuth2 client
      final client = await clientViaUserConsent(
        ClientId(clientId, clientSecret),
        _scopes,
        (url) async {
          debugPrint('Please go to the following URL and grant access:');
          debugPrint(url);
          await launchUrl(Uri.parse(url));
        },
      );

      // Store credentials with expiry
      await _storeCredentials(
        client.credentials.accessToken.data,
        DateTime.now().add(const Duration(hours: 1)), // Default to 1 hour expiry
      );

      _driveApi = drive.DriveApi(client);
      return true;
    } catch (e) {
      debugPrint('Error signing in with service account: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    
    if (!Platform.isWindows) {
      await _googleSignIn.signOut();
    }
    _driveApi = null;
    _folderId = null;
  }

  Future<bool> isSignedIn() async {
    if (_driveApi == null) return false;
    try {
      // Test the connection by making a simple API call
      await _driveApi!.files.list(pageSize: 1);
      return true;
    } catch (e) {
      debugPrint('Error checking sign-in status: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    try {
      print('Initializing Google Drive service');
      if (_driveApi != null) {
        print('Drive API already initialized');
        return true;
      }

      // Check if we have valid credentials
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      final tokenExpiry = prefs.getString(_tokenExpiryKey);

      if (storedToken != null && tokenExpiry != null) {
        final expiryDate = DateTime.parse(tokenExpiry);
        if (expiryDate.isAfter(DateTime.now())) {
          print('Using stored token (expires: $tokenExpiry)');
          final client = GoogleAuthClient({
            'Authorization': 'Bearer $storedToken',
            'Content-Type': 'application/json',
          });
          _driveApi = drive.DriveApi(client);
          
          // Test the API connection
          try {
            final about = await _driveApi!.about.get($fields: 'user');
            print('Drive API initialized successfully. User: ${about.user?.displayName}');
            return true;
          } catch (e) {
            print('Error testing Drive API connection: $e');
            _driveApi = null;
            // Token might be invalid, clear it
            await prefs.remove(_tokenKey);
            await prefs.remove(_tokenExpiryKey);
            return false;
          }
        } else {
          print('Stored token expired, clearing credentials');
          await prefs.remove(_tokenKey);
          await prefs.remove(_tokenExpiryKey);
        }
      }

      print('No valid stored credentials, need to sign in');
      return false;
    } catch (e) {
      print('Error initializing Drive API: $e');
      return false;
    }
  }

  Future<String?> _getBackupFolder() async {
    if (_driveApi == null) return null;
    if (_folderId != null) return _folderId;

    try {
      print('Searching for backup folder: $_folderName');
      final result = await _driveApi!.files.list(
        q: "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name,mimeType)',
      );

      print('Found ${result.files?.length ?? 0} folders matching name');

      if (result.files?.isNotEmpty == true) {
        _folderId = result.files!.first.id;
        print('Using existing folder: $_folderId');
        return _folderId;
      }

      // Create new folder if not found
      print('Creating new backup folder');
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(
        folder,
        $fields: 'id,name',
      );
      
      _folderId = createdFolder.id;
      print('Created new folder: $_folderId');
      return _folderId;
    } catch (e) {
      print('Error getting or creating backup folder: $e');
      return null;
    }
  }

  Future<List<drive.File>?> _listDriveFiles(String folderId, {int maxRetries = 3, int delaySeconds = 2}) async {
    if (_driveApi == null) return null;

    final query = "'$folderId' in parents and mimeType='application/octet-stream' and trashed=false";
    print('Drive query: $query');

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileList = await _driveApi!.files.list(
          q: query,
          orderBy: 'modifiedTime desc',
          spaces: 'drive',
          $fields: 'files(id,name,size,modifiedTime,mimeType)',
        );

        print('Drive API response (attempt $attempt): ${fileList.toJson()}');

        final files = fileList.files;
        if (files == null || files.isEmpty) {
          if (attempt < maxRetries) {
            print('No files found, retrying in $delaySeconds seconds...');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }
          print('No backup files found after $maxRetries attempts');
          return null;
        }

        // Verify all files are of correct type
        final driveFiles = <drive.File>[];
        for (final file in files) {
          if (file is drive.File) {
            driveFiles.add(file);
          } else {
            print('Warning: File ${file.toString()} is not a drive.File');
          }
        }

        if (driveFiles.isEmpty) {
          print('No valid drive files found');
          return null;
        }

        print('Found ${driveFiles.length} valid drive files');
        return driveFiles;
      } catch (e) {
        print('Error listing files (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }
        return null;
      }
    }
    return null;
  }

  Future<void> _cleanupOldDriveBackups() async {
    try {
      if (_driveApi == null) return;

      final folderId = await _getBackupFolder();
      if (folderId == null) return;

      print('Searching for backups in folder: $folderId');
      
      final files = await _listDriveFiles(folderId);
      if (files == null || files.isEmpty) {
        print('No backup files found to clean up');
        return;
      }

      if (files.length <= 5) {
        print('No cleanup needed (${files.length} <= 5)');
        return;
      }

      // Delete oldest files
      print('Deleting ${files.length - 5} old backups');
      for (var i = 5; i < files.length; i++) {
        final file = files[i];
        if (file.id == null) continue;
        print('Deleting old backup: ${file.name} (${file.id})');
        try {
          await _driveApi!.files.delete(file.id!);
          print('Successfully deleted ${file.name}');
        } catch (e) {
          print('Error deleting file ${file.name}: $e');
        }
      }

      print('Cleanup completed');
    } catch (e) {
      print('Error cleaning up old Drive backups: $e');
    }
  }

  Future<String?> downloadLatestBackup() async {
    try {
      if (_driveApi == null) {
        print('Drive API not initialized');
        return null;
      }

      final folderId = await _getBackupFolder();
      if (folderId == null) {
        print('Backup folder not found');
        return null;
      }

      print('Searching for backups in folder: $folderId');
      
      final files = await _listDriveFiles(folderId);
      if (files == null || files.isEmpty) {
        print('No backup files found in response');
        return null;
      }

      final latestFile = files.first;
      if (latestFile.id == null) {
        print('Latest file has no ID');
        return null;
      }

      print('Found latest backup: ${latestFile.name} (${latestFile.id})');
      
      final fileId = latestFile.id!;
      final fileName = latestFile.name ?? 'backup.lpb';
      final fileSize = int.tryParse(latestFile.size ?? '0') ?? 0;

      // Get the backup directory
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        print('Creating backup directory: ${backupDir.path}');
        await backupDir.create(recursive: true);
      }

      final localPath = '${backupDir.path}/$fileName';
      print('Downloading to: $localPath');
      
      final file = File(localPath);
      final sink = file.openWrite();

      // Download in chunks
      print('Starting download of $fileSize bytes');
      try {
        final media = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
          $fields: '*',
        ) as drive.Media;

        var bytesDownloaded = 0;
        await for (final chunk in media.stream) {
          sink.add(chunk);
          bytesDownloaded += chunk.length;
          if (bytesDownloaded % (1024 * 1024) == 0) { // Log every MB
            print('Downloaded: ${bytesDownloaded ~/ (1024 * 1024)}MB / ${fileSize ~/ (1024 * 1024)}MB');
          }
        }

        await sink.close();
        print('Download complete: $localPath');
        return localPath;
      } catch (e) {
        print('Error downloading file: $e');
        await sink.close();
        await file.delete();
        return null;
      }
    } catch (e, stackTrace) {
      print('Error downloading backup from Drive: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
  }

  Future<int> getBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_backupIntervalKey) ?? _defaultBackupInterval;
  }

  Future<void> setBackupInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupIntervalKey, hours);
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString(_lastBackupKey);
    return lastBackup != null ? DateTime.parse(lastBackup) : null;
  }

  Future<bool> shouldPerformAutoBackup() async {
    final isEnabled = await isAutoBackupEnabled();
    if (!isEnabled) return false;

    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true;

    final interval = await getBackupInterval();
    final nextBackupDue = lastBackup.add(Duration(hours: interval));
    return DateTime.now().isAfter(nextBackupDue);
  }

  Future<bool> shouldPerformBackup() async {
    if (!await isAutoBackupEnabled()) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString(_lastBackupKey);
    if (lastBackupStr == null) return true;

    final lastBackup = DateTime.parse(lastBackupStr);
    final interval = await getBackupInterval();
    return DateTime.now().difference(lastBackup).inHours >= interval;
  }

  Future<bool> uploadBackup(String localFilePath) async {
    try {
      if (_driveApi == null) {
        print('Drive API not initialized');
        return false;
      }

      final folderId = await _getBackupFolder();
      if (folderId == null) {
        print('Failed to get or create backup folder');
        return false;
      }

      print('Using backup folder: $folderId');

      final file = File(localFilePath);
      if (!await file.exists()) {
        print('Local backup file does not exist: $localFilePath');
        return false;
      }

      // Read file metadata
      final fileName = file.path.split(Platform.pathSeparator).last;
      const mimeType = 'application/octet-stream';
      final fileSize = await file.length();

      print('Uploading file: $fileName ($fileSize bytes)');

      // Create drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = mimeType
        ..description = 'LedgerPro Backup'
        ..appProperties = {
          'backupVersion': '1', // Replace with actual backup version
          'timestamp': DateTime.now().toIso8601String(),
          'size': fileSize.toString(),
        };

      print('Created Drive file metadata');

      // Upload in chunks
      const chunkSize = 1024 * 1024; // 1MB
      final totalChunks = (fileSize / chunkSize).ceil();
      
      print('Starting upload in $totalChunks chunks');

      // Create a stream transformer to handle progress updates
      final controller = StreamController<List<int>>();
      var bytesUploaded = 0;
      
      file.openRead().listen(
        (chunk) {
          bytesUploaded += chunk.length;
          controller.add(chunk);
          if (bytesUploaded % (1024 * 1024) == 0) { // Log every MB
            print('Uploaded: ${bytesUploaded ~/ (1024 * 1024)}MB / ${fileSize ~/ (1024 * 1024)}MB');
          }
        },
        onDone: () => controller.close(),
        onError: (error) {
          print('Error reading file: $error');
          controller.addError(error);
        },
      );

      final media = drive.Media(controller.stream, fileSize);
      
      // Start upload
      print('Starting Drive API upload');
      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        uploadOptions: drive.UploadOptions.resumable,
        $fields: 'id,name,size,modifiedTime',
      );

      if (response.id == null) {
        print('Error: Upload response has no file ID');
        return false;
      }

      print('Upload complete. File ID: ${response.id}');

      // Verify the file exists
      print('Verifying uploaded file...');
      try {
        final uploadedFile = await _driveApi!.files.get(
          response.id!,
          $fields: 'id,name,size,modifiedTime',
        );

        if (uploadedFile is! drive.File) {
          print('Error: Unable to cast uploaded file to drive.File');
          return false;
        }

        if (uploadedFile.id == null) {
          print('Error: Uploaded file not found');
          return false;
        }

        print('File verified: ${uploadedFile.name} (${uploadedFile.id})');
      } catch (e) {
        print('Error verifying uploaded file: $e');
        return false;
      }

      // Clean up old backups in Drive
      await _cleanupOldDriveBackups();

      // Update last backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      return true;
    } catch (e, stackTrace) {
      print('Error uploading backup to Drive: $e');
      print('Stack trace: $stackTrace');
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
