import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/features/side_ledger/other/other_expense_form_screen.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('other_expense_form_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('form needs a description and saves with pending amount',
      (t) async {
    t.view.physicalSize = const Size(900, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OtherExpenseFormScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Save Entry'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Please enter a description'), findsOneWidget);

    await t.enterText(
        find.widgetWithText(TextFormField, 'Description *'), 'Site food');
    await t.enterText(find.widgetWithText(TextFormField, 'Amount *'), '800');
    await t.enterText(find.widgetWithText(TextFormField, 'Paid Amount'), '300');
    await t.pump(const Duration(milliseconds: 300));
    await t.ensureVisible(find.text('Save Entry'));
    await t.tap(find.text('Save Entry'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 300));

    final saved = DatabaseService.getAllOtherExpenseEntries();
    expect(saved.length, 1);
    expect(saved.first.description, 'Site food');
    expect(saved.first.total, 800);
    expect(saved.first.pending, 500);
    expect(saved.first.billNumber, '');
  });
}
