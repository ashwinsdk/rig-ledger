import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:rig_ledger/features/ledger_form/side_bore_form_screen.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('side_bore_lines_test');
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

  testWidgets('side bore bill with two depth lines', (t) async {
    t.view.physicalSize = const Size(900, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() => container
        .read(agentsProvider.notifier)
        .addAgent('Ravi', depthCommissionRate: 5));
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SideBoreFormScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));

    await t.enterText(
        find.widgetWithText(TextFormField, 'Enter bill number'), 'S-1');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Enter city name'), 'Erode');
    await t.tap(find.byType(DropdownButtonFormField<Agent>));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Ravi').last);
    await t.pump(const Duration(milliseconds: 300));

    await t.enterText(field('Depth (ft)'), '100');
    await t.enterText(field('Rate/ft (₹)'), '80');
    await t.tap(find.text('Add Depth line'));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(field('Depth (ft)', at: 1), '50');
    await t.enterText(field('Rate/ft (₹)', at: 1), '90');
    await t.pump(const Duration(milliseconds: 300));

    await t.ensureVisible(find.text('Save Entry'));
    await t.tap(find.text('Save Entry'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 400));

    final saved = DatabaseService.getAllLedgerEntries().single;
    expect(saved.linesOf('depth').length, 2);
    expect(saved.depthInFeet, 150);
    expect(saved.total, 100 * 80 + 50 * 90);
    expect(saved.commission, 150 * 5);
  });
}
