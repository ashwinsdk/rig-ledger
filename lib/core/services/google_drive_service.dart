import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../database/database_service.dart';

class GoogleDriveService {
  static const String _backupFileName = 'rigledger_backup.json';
  static const String _backupFolderName = 'RigLedger Backups';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  static GoogleSignInAccount? _currentUser;
  static drive.DriveApi? _driveApi;
  static String? _backupFolderId;
  static String? _backupFileId;

  // Check if user is signed in
  static bool get isSignedIn => _currentUser != null;

  // Get current user email
  static String? get userEmail => _currentUser?.email;

  // Get last backup time from settings
  static DateTime? get lastBackupTime {
    final timestamp = DatabaseService.settingsBox.get('lastGoogleDriveBackup');
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Check if auto-backup is enabled
  static bool get isAutoBackupEnabled {
    return DatabaseService.settingsBox
        .get('autoGoogleDriveBackup', defaultValue: false) as bool;
  }

  // Set auto-backup enabled
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    await DatabaseService.settingsBox.put('autoGoogleDriveBackup', enabled);
  }

  // Initialize - try silent sign in
  static Future<bool> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initializeDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Drive initialization error: $e');
      return false;
    }
  }

  // Sign in
  static Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _backupFolderId = null;
    _backupFileId = null;
    await DatabaseService.settingsBox.delete('autoGoogleDriveBackup');
    await DatabaseService.settingsBox.delete('lastGoogleDriveBackup');
  }

  // Initialize Drive API
  static Future<void> _initializeDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient != null) {
      _driveApi = drive.DriveApi(httpClient);
      await _findOrCreateBackupFolder();
      await _findBackupFile();
    }
  }

  // Find or create the backup folder
  static Future<void> _findOrCreateBackupFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing folder
      final folderSearch = await _driveApi!.files.list(
        q: "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderSearch.files != null && folderSearch.files!.isNotEmpty) {
        _backupFolderId = folderSearch.files!.first.id;
      } else {
        // Create folder
        final folder = drive.File()
          ..name = _backupFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _backupFolderId = createdFolder.id;
      }
    } catch (e) {
      debugPrint('Error finding/creating backup folder: $e');
    }
  }

  // Find existing backup file
  static Future<void> _findBackupFile() async {
    if (_driveApi == null || _backupFolderId == null) return;

    try {
      final fileSearch = await _driveApi!.files.list(
        q: "name = '$_backupFileName' and '$_backupFolderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileSearch.files != null && fileSearch.files!.isNotEmpty) {
        _backupFileId = fileSearch.files!.first.id;
      }
    } catch (e) {
      debugPrint('Error finding backup file: $e');
    }
  }

  // Create or update backup
  static Future<bool> backup() async {
    if (_driveApi == null) {
      debugPrint('Drive API not initialized');
      return false;
    }

    try {
      // Get backup data
      final backupData = await DatabaseService.createBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonString);

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      if (_backupFileId != null) {
        // Update existing file
        await _driveApi!.files.update(
          drive.File()..name = _backupFileName,
          _backupFileId!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File()
          ..name = _backupFileName
          ..parents = [_backupFolderId ?? 'root'];

        final createdFile = await _driveApi!.files.create(
          file,
          uploadMedia: media,
        );
        _backupFileId = createdFile.id;
      }

      // Save backup time
      await DatabaseService.settingsBox.put(
        'lastGoogleDriveBackup',
        DateTime.now().toIso8601String(),
      );

      debugPrint('Backup to Google Drive successful');
      return true;
    } catch (e) {
      debugPrint('Backup to Google Drive failed: $e');
      return false;
    }
  }

  // Restore from backup
  static Future<Map<String, dynamic>?> restore() async {
    if (_driveApi == null || _backupFileId == null) {
      debugPrint('No backup file found');
      return null;
    }

    try {
      final response = await _driveApi!.files.get(
        _backupFileId!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      return backupData;
    } catch (e) {
      debugPrint('Restore from Google Drive failed: $e');
      return null;
    }
  }

  // Get backup info
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    if (_driveApi == null || _backupFileId == null) {
      return null;
    }

    try {
      final file = await _driveApi!.files.get(
        _backupFileId!,
        $fields: 'id, name, size, modifiedTime',
      ) as drive.File;

      return {
        'name': file.name,
        'size': file.size,
        'modifiedTime': file.modifiedTime?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      return null;
    }
  }

  // Perform auto-backup if enabled
  static Future<void> performAutoBackupIfEnabled() async {
    if (!isAutoBackupEnabled || !isSignedIn) return;

    final lastBackup = lastBackupTime;
    final now = DateTime.now();

    // Auto-backup every 6 hours
    if (lastBackup == null || now.difference(lastBackup).inHours >= 6) {
      await backup();
    }
  }
}
