import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/services/google_drive_service.dart';
import 'features/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide system navigation bars for immersive experience
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize database
  await DatabaseService.initialize();

  // Request storage permissions
  await _requestPermissions();

  // Initialize Google Drive (try silent sign-in)
  await GoogleDriveService.initialize();

  // Perform auto-backup if enabled
  await GoogleDriveService.performAutoBackupIfEnabled();

  runApp(
    const ProviderScope(
      child: RigLedgerApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  if (!Platform.isAndroid) return;

  try {
    // Get Android SDK version
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ (API 33+): Use granular media permissions
      // For documents/files, no runtime permission needed - uses SAF
      debugPrint(
          'Android 13+: Using scoped storage, no broad permissions needed');
    } else if (sdkInt >= 30) {
      // Android 11-12 (API 30-32): Request MANAGE_EXTERNAL_STORAGE
      final manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    } else {
      // Android 10 and below: Request legacy storage permission
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        await Permission.storage.request();
      }
    }
  } catch (e) {
    // Fallback: Try requesting storage permission the old way
    debugPrint('Error detecting SDK version: $e');
    try {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        await Permission.storage.request();
      }
    } catch (_) {
      // Ignore - permissions will be handled when needed
    }
  }
}

class RigLedgerApp extends StatelessWidget {
  const RigLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RigLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}
