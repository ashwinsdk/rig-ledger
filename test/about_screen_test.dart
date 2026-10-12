import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rig_ledger/features/settings/about_screen.dart';

void main() {
  testWidgets('About shows version, data facts and the license text',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        packageInfoProvider.overrideWith((ref) async => PackageInfo(
              appName: 'RigLedger',
              packageName: 'com.rigledger.app',
              version: '2.0.0',
              buildNumber: '5',
            )),
      ],
      child: const MaterialApp(home: AboutScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Version 2.0.0 (build 5)'), findsOneWidget);
    expect(find.text('com.rigledger.app'), findsOneWidget);
    expect(find.textContaining('rigledger_backup.json'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Open source licenses'), 200);
    expect(find.text('Open source licenses'), findsOneWidget);

    await tester.tap(find.text('License'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('RigLedger Proprietary License'), findsOneWidget);
    expect(find.textContaining('All rights reserved'), findsWidgets);
  });
}
