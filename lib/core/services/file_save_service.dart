import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';

enum SaveOption { share, saveToFiles }

/// Saves exported files (PDF, CSV, backup JSON).
///
/// Android: "Save to Files" goes through the system file picker (Storage Access
/// Framework). The picker writes the bytes itself and needs no storage
/// permission on any Android version, so nothing is requested at runtime and
/// the app does not write to the returned path a second time (that second
/// write used to fail with "Permission denied" on Android 11 and later).
/// If the picker fails, the file is shared instead so the export is never lost.
class FileSaveService {
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
              subtitle: const Text('Choose a folder on this device'),
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

    if (option == SaveOption.share) {
      return _share(bytes, fileName, shareSubject);
    }

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save File',
        fileName: fileName,
        bytes: bytes,
      );
      if (result == null) return false; // user cancelled
      // Android writes the bytes through the picker itself. iOS needs the
      // manual write; desktop behaviour is unchanged.
      if (Platform.isIOS) {
        await File(result).writeAsBytes(bytes);
      }
      return true;
    } catch (e) {
      debugPrint('saveFile failed, falling back to share: $e');
      return _shareAfterFailure(context, bytes, fileName, shareSubject);
    }
  }

  /// Save string content (CSV, JSON) as UTF-8 with option to share or save
  static Future<bool> saveStringFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String shareSubject,
    String? dialogTitle,
  }) {
    // UTF-8, not UTF-16 code units: the rupee sign and Tamil text survive.
    return saveFile(
      context: context,
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileName: fileName,
      shareSubject: shareSubject,
      dialogTitle: dialogTitle,
    );
  }

  static Future<bool> _share(
      Uint8List bytes, String fileName, String shareSubject) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: shareSubject,
    );
    return true;
  }

  static Future<bool> _shareAfterFailure(BuildContext context, Uint8List bytes,
      String fileName, String shareSubject) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not save to the chosen location. Share the file instead.'),
        ),
      );
    }
    return _share(bytes, fileName, shareSubject);
  }
}
