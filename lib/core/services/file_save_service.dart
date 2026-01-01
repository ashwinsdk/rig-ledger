import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../theme/app_colors.dart';

enum SaveOption { share, saveToFiles }

class FileSaveService {
  /// Request storage permissions based on Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+: No broad storage permission needed
          // File picker uses SAF which doesn't require runtime permissions
          debugPrint('Android 13+: Using SAF, no storage permission needed');
          return true;
        } else if (sdkInt >= 30) {
          // Android 11-12: Need MANAGE_EXTERNAL_STORAGE
          final status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            final result = await Permission.manageExternalStorage.request();
            return result.isGranted;
          }
          return true;
        } else {
          // Android 10 and below: Use legacy storage permission
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      } catch (e) {
        // Fallback if device_info_plus fails
        debugPrint('Error detecting SDK version: $e');
        try {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        } catch (_) {
          return true; // Proceed anyway, file picker may work
        }
      }
    }
    return true; // iOS handles permissions differently via file picker
  }

  /// Shows a dialog to choose between sharing or saving to files
  static Future<SaveOption?> showSaveOptionsDialog(BuildContext context) async {
    return showDialog<SaveOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: const Text('Share'),
              subtitle: const Text('Share via apps'),
              onTap: () => Navigator.pop(context, SaveOption.share),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: AppColors.success),
              title: const Text('Save to Files'),
              subtitle: const Text('Save to device storage'),
              onTap: () => Navigator.pop(context, SaveOption.saveToFiles),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Save bytes to a file with option to share or save to files
  static Future<bool> saveFile({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
    required String shareSubject,
    String? dialogTitle,
  }) async {
    final option = await showSaveOptionsDialog(context);
    if (option == null) return false;

    try {
      if (option == SaveOption.share) {
        // Save to temp and share
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: shareSubject,
        );
        return true;
      } else {
        // Check permissions first
        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Storage permission required. Please grant permission in Settings.'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return false;
        }

        // Save to user-selected location
        final result = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? 'Save File',
          fileName: fileName,
          bytes: bytes,
        );

        if (result != null) {
          // On some platforms, bytes are written automatically
          // On others, we need to write manually
          if (Platform.isAndroid || Platform.isIOS) {
            final file = File(result);
            await file.writeAsBytes(bytes);
          }
          return true;
        }
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save string content to a file with option to share or save to files
  static Future<bool> saveStringFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String shareSubject,
    String? dialogTitle,
  }) async {
    final option = await showSaveOptionsDialog(context);
    if (option == null) return false;

    try {
      if (option == SaveOption.share) {
        // Save to temp and share
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(content);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: shareSubject,
        );
        return true;
      } else {
        // Check permissions first
        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Storage permission required. Please grant permission in Settings.'),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return false;
        }

        // Save to user-selected location
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? 'Save File',
          fileName: fileName,
          bytes: bytes,
        );

        if (result != null) {
          // On some platforms, bytes are written automatically
          // On others, we need to write manually
          if (Platform.isAndroid || Platform.isIOS) {
            final file = File(result);
            await file.writeAsString(content);
          }
          return true;
        }
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }
}
