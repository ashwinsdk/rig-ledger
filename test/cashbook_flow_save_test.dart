import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/features/cashbook/cashbook_hub_screen.dart';

/// Save and Save and add another on the entry form (bug 10, v2.0.1).
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

  testWidgets('Save returns to the ledger, Save and add another stays',
      (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const CashbookRootScreen()));
    await settle(t);
    await t.tap(find.widgetWithText(ElevatedButton, 'Income').first);
    await settle(t);
    final before = DatabaseService.getCashEntries().length;
    await t.enterText(find.byType(TextField).first, '100');
    await t.tap(find.text('Save and add another'));
    // The save has finished when the 'Saved' snackbar shows.
    await pumpUntil(t, () => find.text('Saved').evaluate().isNotEmpty);
    expect(find.text('Add Income'), findsOneWidget); // form stays open
    expect(DatabaseService.getCashEntries().length, before + 1);
    ScaffoldMessenger.of(t.element(find.byType(Scaffold).first))
        .clearSnackBars();
    await settle(t);
    await t.enterText(find.byType(TextField).first, '50');
    await t.tap(find.text('Save'));
    await pumpUntil(t, () => find.text('Add Income').evaluate().isEmpty);
    expect(find.text('Add Income'), findsNothing); // back on the ledger
    expect(DatabaseService.getCashEntries().length, before + 2);
  });
}
