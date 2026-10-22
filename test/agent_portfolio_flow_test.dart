import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';
import 'package:rig_ledger/features/portfolio/portfolio_view.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('agent_portfolio_flow_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('add agent with custom prices from Portfolio on a phone screen',
      (t) async {
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() async {
      await container
          .read(ledgerTypesProvider.notifier)
          .addType(LedgerTypeCategory.depth, '9');
      await container
          .read(ledgerTypesProvider.notifier)
          .addType(LedgerTypeCategory.pvc, '9');
    });
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 300));
    await t.ensureVisible(find.text('Add agent'));
    await t.tap(find.text('Add agent'));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.widgetWithText(TextField, 'Name *'), 'Mani');
    final fields = find.byType(TextField);
    debugPrint('fields: ${fields.evaluate().length}');
    await t.enterText(find.widgetWithText(TextField, '9inch').first, '15');
    await t.enterText(find.widgetWithText(TextField, '9inch').last, '44');
    await t.tap(find.text('Add').last);
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 400));
    final saved = DatabaseService.getAgentByName('Mani');
    expect(saved, isNotNull);
    expect(saved!.commissionRates['depth:9inch'], 15);
    expect(saved.commissionRates['pvc:9inch'], 44);
  });

  testWidgets('edit agent prices from the Portfolio detail sheet and save',
      (t) async {
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 300));
    await t.ensureVisible(find.byTooltip('Prices and details').first);
    await t.tap(find.byTooltip('Prices and details').first);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.ensureVisible(find.text('Edit'));
    await t.tap(find.text('Edit'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.widgetWithText(TextField, '9inch').first, '21');
    await t.tap(find.text('Save'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
    expect(
        DatabaseService.getAgentByName('Mani')!.commissionRates['depth:9inch'],
        21);
  });

  testWidgets('delete an agent from the Portfolio detail sheet', (t) async {
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 300));
    await t.ensureVisible(find.byTooltip('Prices and details').first);
    await t.tap(find.byTooltip('Prices and details').first);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Delete'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Delete').last);
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
    expect(DatabaseService.getAgentByName('Mani'), isNull);
  });
}
