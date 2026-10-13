import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:rig_ledger/features/portfolio/portfolio_view.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('portfolio_agents_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('Portfolio lists agents without bills and opens a detail sheet',
      (t) async {
    t.view.physicalSize = const Size(900, 3600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() => container.read(agentsProvider.notifier).addAgent(
        'Karthik',
        phone: '99999',
        depthCommissionRate: 10,
        commissionRatesJson: Agent.encodeRates({'depth:7inch': 12})));

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('Add agent'), findsOneWidget);
    expect(find.text('Karthik'), findsOneWidget);
    expect(find.text('no bills'), findsOneWidget);

    await t.ensureVisible(find.text('Karthik'));
    await t.tap(find.text('Karthik'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Commission per foot'), findsOneWidget);
    expect(find.text('Depth 7"'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
