import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/features/cashbook/cashbook_hub_screen.dart';
import 'package:rig_ledger/features/cashbook/cashbook_trash_screen.dart';

/// Drives the real Account Ledger screens with a real Hive database.
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

  testWidgets('delete goes to trash and can be restored', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const CashbookRootScreen()));
    await settle(t);
    await addEntry(t, button: 'Income', amount: '100', notes: 'To delete');

    await t.tap(find.text('To delete'));
    await settle(t);
    expect(find.text('Edit Transaction'), findsOneWidget);
    await t.tap(find.text('Delete'));
    await settle(t);
    await t.tap(find.widgetWithText(TextButton, 'Delete'));
    await pumpUntil(
        t,
        () =>
            DatabaseService.getCashTrash().isNotEmpty &&
            find.text('Edit Transaction').evaluate().isEmpty);
    expect(find.text('To delete'), findsNothing);
    expect(DatabaseService.getCashTrash().length, 1);

    // Trash screen shows it and restores it.
    await t.pumpWidget(app(const CashbookTrashScreen()));
    await settle(t);
    expect(find.text('To delete'), findsOneWidget);
    await t.tap(find.text('To delete'));
    await settle(t);
    await t.tap(find.text('Restore'));
    await pumpUntil(t, () => DatabaseService.getCashTrash().isEmpty);
    expect(DatabaseService.getCashTrash(), isEmpty);
    expect(DatabaseService.getCashEntries().length, 1);
  });
}
