import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/theme/app_theme.dart';

void main() {
  testWidgets('light theme builds a Material app', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: Text('RigLedger')),
    ));
    expect(find.text('RigLedger'), findsOneWidget);
  });
}
