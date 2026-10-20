import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:rig_ledger/features/ledger_form/ledger_form_screen.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('bill_lines_form_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
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

  testWidgets('a bill with two depth lines of different types', (t) async {
    t.view.physicalSize = const Size(900, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() async {
      await container.read(agentsProvider.notifier).addAgent('Karthik',
          commissionRatesJson: Agent.encodeRates({
            'depth:7inch': 12,
            'depth:8inch': 14,
            'pvc:7inch': 40,
          }));
    });
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LedgerFormScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));

    await t.enterText(
        find.widgetWithText(TextFormField, 'Enter bill number'), 'B-100');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Enter city/address'), 'Salem');
    await t.tap(find.byType(DropdownButtonFormField<Agent>));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Karthik').last);
    await t.pump(const Duration(milliseconds: 300));

    // first depth line: 200 ft of 7inch at 100
    await t.enterText(field('Depth (feet)'), '200');
    await t.enterText(field('Depth rate per feet (₹)'), '100');
    // add a second depth line and make it 8inch
    await t.tap(find.text('Add Depth line'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Depth line 2'), findsOneWidget);
    await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('8inch').last);
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(field('Depth (feet)', at: 1), '150');
    await t.enterText(field('Depth rate per feet (₹)', at: 1), '120');
    await t.enterText(field('PVC (feet)'), '50');
    await t.enterText(field('PVC rate per feet (₹)'), '30');
    await t.pump(const Duration(milliseconds: 300));

    String text(Finder f) => (t.widget(f) as TextField).controller!.text;
    // 200 x 100 + 150 x 120 + 50 x 30, no step rate (each line under 300 ft)
    expect(find.text('Total'), findsWidgets);
    final totalField = find.byWidgetPredicate((w) =>
        w is TextField &&
        (w.controller?.text ?? '') == '39500.00' &&
        w.decoration?.prefixIcon != null);
    expect(totalField, findsWidgets);
    // commission follows the agent price of each line: 2400 + 2100 + 2000
    expect(
        find.byWidgetPredicate(
            (w) => w is TextField && (w.controller?.text ?? '') == '6500.00'),
        findsOneWidget);
    expect(text(field('Step Rate, all depth lines (₹)')), '0.00');

    await t.ensureVisible(find.text('Save Entry'));
    await t.tap(find.text('Save Entry'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 400));

    final saved = DatabaseService.getAllLedgerEntries().single;
    expect(saved.linesOf('depth').length, 2);
    expect(saved.typesOf('depth'), {'7inch', '8inch'});
    expect(saved.depthInFeet, 350);
    expect(saved.total, 39500);
    expect(saved.commission, 6500);
    expect(saved.pvcInFeet, 50);
  });
}
