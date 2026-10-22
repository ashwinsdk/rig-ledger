import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/cash_entry.dart';
import 'package:rig_ledger/features/cashbook/cashbook_hub_screen.dart';

/// The optional rig of an Account Ledger entry (v2.0.4).
void main() {
  late Directory dir;

  Future<void> pumpUntil(WidgetTester t, bool Function() cond,
      {int maxMs = 8000}) async {
    var waited = 0;
    while (!cond() && waited < maxMs) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 25)));
      await t.pump(const Duration(milliseconds: 100));
      waited += 25;
    }
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> settle(WidgetTester t) => pumpUntil(t, () => false, maxMs: 150);

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('cashbook_rig_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('json keeps the rig, older json has none', () {
    final now = DateTime(2026, 5, 1);
    final e = CashEntry(
        id: 'c1',
        bookId: 'b',
        date: now,
        amount: 10,
        isCashIn: true,
        createdAt: now,
        updatedAt: now,
        vehicleId: 'rig1');
    expect(CashEntry.fromJson(e.toJson()).vehicleId, 'rig1');
    final old = e.toJson()..remove('vehicleId');
    expect(CashEntry.fromJson(old).vehicleId, isNull);
    expect(e.copyWith(clearVehicle: true).vehicleId, isNull);
    expect(e.copyWith(amount: 5).vehicleId, 'rig1');
  });

  testWidgets('choose a rig on a new entry; it is saved and shown on the row',
      (t) async {
    t.view.physicalSize = const Size(900, 2200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CashbookRootScreen())));
    await settle(t);
    await t.tap(find.widgetWithText(ElevatedButton, 'Income').first);
    await settle(t);
    final before = DatabaseService.getCashEntries().length;
    await t.enterText(find.byType(TextField).first, '250');
    expect(find.text('Rig (optional)'), findsOneWidget);
    await t.tap(find.text('Rig (optional)'));
    await settle(t);
    await t.tap(find.text('Main Rig').last);
    await settle(t);
    await t.tap(find.text('Save'));
    await pumpUntil(t, () => find.text('Add Income').evaluate().isEmpty);

    final all = DatabaseService.getCashEntries();
    expect(all.length, before + 1);
    expect(all.firstWhere((e) => e.amount == 250).vehicleId, 'default_vehicle');
    expect(find.text('Main Rig'), findsWidgets); // on the ledger row
  });
}
