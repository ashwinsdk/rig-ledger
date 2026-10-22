import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_line.dart';
import 'package:rig_ledger/core/models/step_rates.dart';
import 'package:rig_ledger/features/ledger_form/ledger_form_screen.dart';
import 'package:rig_ledger/features/settings/step_rates_screen.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('step_rates_flow_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
    final now = DateTime(2026, 1, 1);
    await DatabaseService.saveAgent(Agent(
        id: 'a1',
        name: 'Karthik',
        vehicleId: 'default_vehicle',
        createdAt: now,
        updatedAt: now));
    // a saved bill: 350 ft of 7inch with the step rate of the old table (500)
    final b = LedgerEntry(
      id: 'old',
      date: DateTime(2026, 5, 1),
      billNumber: 'OLD-1',
      agentId: 'a1',
      agentName: 'Karthik',
      address: 'Salem',
      depth: '7inch',
      depthInFeet: 0,
      depthPerFeetRate: 0,
      pvc: '7inch',
      msPipe: '6inch',
      extraCharges: 0,
      total: 35500,
      isTotalManuallyEdited: false,
      received: 0,
      balance: 35500,
      less: 0,
      stepRate: 500,
      createdAt: now,
      updatedAt: now,
      vehicleId: 'default_vehicle',
    ).withLines(const [
      LedgerLine(category: 'depth', type: '7inch', feet: 350, rate: 100),
    ]);
    await DatabaseService.saveLedgerEntry(b);
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Finder field(String label, {int at = 0}) => find
      .byWidgetPredicate(
          (w) => w is TextField && (w.decoration?.labelText ?? '') == label)
      .at(at);

  testWidgets('edit the 7 inch table in Settings and save', (t) async {
    t.view.physicalSize = const Size(412, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StepRatesScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('7 inch table'), findsOneWidget);
    expect(find.text('8 inch table'), findsOneWidget);

    // 300 to 400 ft of the 7 inch table: 10 becomes 25
    await t.enterText(field('300 to 400 ft, extra per ft'), '25');
    await t.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Example'), findsWidgets);
    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 300));

    final saved = DatabaseService.getStepRates().forRig('default_vehicle');
    expect(saved.table7.extras.first, 25);
    expect(saved.table7.extras.length, 6);
    expect(saved.table8, StepTable.builtin8); // untouched
  });

  testWidgets('a new bill uses the table, a saved bill keeps its step rate',
      (t) async {
    t.view.physicalSize = const Size(900, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // new bill, 350 ft of 7inch: 50 ft x 25 = 1250 with the edited table
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LedgerFormScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(field('Depth (feet)'), '350');
    await t.pump(const Duration(milliseconds: 300));
    expect((t.widget(field('Step Rate (₹)')) as TextField).controller!.text,
        '1250.00');

    // the saved bill is opened and saved without touching its depth
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: LedgerFormScreen(
              entry: DatabaseService.getAllLedgerEntries().single)),
    ));
    await t.pump(const Duration(milliseconds: 400));
    await t.ensureVisible(find.text('Update Entry'));
    await t.tap(find.text('Update Entry'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 300));
    final old = DatabaseService.getAllLedgerEntries().single;
    expect(old.stepRate, 500);
    expect(old.total, 35500);
  });
}
