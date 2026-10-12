import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Facts shown in Settings > About. Every value here is verifiable in the
/// repository (see the comments); nothing is invented.
class AppInfo {
  AppInfo._();

  static const String name =
      'RigLedger'; // AndroidManifest label, AppInfo.xcconfig
  static const String copyright =
      '2025-2026 Ashwin Sudhakar'; // LICENSE, git history
  static const String developerLink =
      'github.com/ashwinsdk'; // existing About dialog
  static const String developerUrl = 'https://github.com/ashwinsdk';
  static const String driveFolder = 'RigLedger Backups'; // GoogleDriveService
  static const String driveFile = 'rigledger_backup.json'; // GoogleDriveService
  static const String licenseAsset = 'LICENSE';
}

bool _licensesRegistered = false;

/// Adds the bundled font licenses to Flutter's license page.
void registerAppLicenses() {
  if (_licensesRegistered) return;
  _licensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Noto Sans': 'assets/fonts/OFL-NotoSans.txt',
      'Noto Sans Tamil': 'assets/fonts/OFL-NotoSansTamil.txt',
    }.entries) {
      try {
        final text = await rootBundle.loadString(entry.value);
        yield LicenseEntryWithLineBreaks([entry.key], text);
      } catch (e) {
        debugPrint('License asset missing: ${entry.value}');
      }
    }
  });
}
