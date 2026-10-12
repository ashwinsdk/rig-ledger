import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/features/cashbook/cashbook_hub_screen.dart';

/// Drives the real Account Ledger screens with a real Hive database.
/// (Each flow file uses its own database; Hive writes started inside a widget
/// test cannot be cleared mid-file, so tests here do not reset the database.)
void main() {
  late Directory dir;

  /// Pumps (fake time) and waits (real time) until [cond] holds. Hive work is
  /// real async work, so a fixed delay is not reliable under load.
  Future<void> pumpUntil(WidgetTester t, bool Function() cond,
      {int maxMs = 8000}) async {
    var waited = 0;
    while (!cond() && waited < maxMs) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 25)));
      await t.pump(const Duration(milliseconds: 100));
      waited += 25;
    }
    // A few extra frames so route animations finish.
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> settle(WidgetTester t) => pumpUntil(t, () => false, maxMs: 150);

  Widget app(Widget home) => ProviderScope(
        child: MaterialApp(home: home),
      );

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('flow_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  // Hive.close() can wait forever for writes that were started inside a widget
  // test's fake-async zone, so the box is left open; the process exit and the
  // temp directory clean-up below are enough.
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> addEntry(WidgetTester t,
      {required String button, required String amount, String? notes}) async {
    await t.tap(find.widgetWithText(ElevatedButton, button).first);
    await settle(t);
    await t.enterText(find.byType(TextField).first, amount);
    if (notes != null) {
      await t.enterText(find.widgetWithText(TextField, 'Notes'), notes);
    }
    await t.tap(find.text('Save and exit'));
    await pumpUntil(t, () => find.text('Save and exit').evaluate().isEmpty);
  }

  testWidgets('add income and expense, totals and running balance', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const CashbookRootScreen()));
    await settle(t);

    expect(find.text('Cash Book'), findsWidgets);
    expect(find.text('No transactions'), findsOneWidget);
    expect(find.text('Rs. 0'), findsNWidgets(3));

    await addEntry(t, button: 'Income', amount: '2500.5', notes: 'Advance');
    await addEntry(t, button: 'Expense', amount: '400', notes: 'Diesel');
    await addEntry(t, button: 'Expense', amount: '0');

    expect(find.text('Advance'), findsOneWidget);
    expect(find.text('Diesel'), findsOneWidget);
    // Totals strip: income 2,500.50, expense 400, balance 2,100.50.
    expect(find.text('Rs. 2,500.50'), findsWidgets);
    expect(find.text('Rs. 2,100.50'), findsWidgets);
    expect(find.text('Balance 2,100.50'), findsWidgets);
    expect(DatabaseService.getCashEntries().length, 3);
  });

  testWidgets('empty amount does not save', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const CashbookRootScreen()));
    await settle(t);
    await t.tap(find.widgetWithText(ElevatedButton, 'Income').first);
    await settle(t);
    await t.tap(find.text('Save and exit'));
    await settle(t);
    expect(find.text('Add Income'), findsOneWidget); // still on the form
    expect(DatabaseService.getCashEntries().length, 3); // unchanged
  });
}
