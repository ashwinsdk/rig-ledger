import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:rig_ledger/features/portfolio/portfolio_view.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('agent_filter_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('agent filter is a pill with a searchable list', (t) async {
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() async {
      await container.read(agentsProvider.notifier).addAgent('Zed');
      await container.read(agentsProvider.notifier).addAgent('Mani');
    });
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Agent: '), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await t.tap(find.text('Agent: '));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Filter by agent'), findsOneWidget);
    expect(find.text('Zed'), findsNWidgets(2)); // section row and list
    await t.enterText(find.widgetWithText(TextField, 'Search agents'), 'ze');
    await t.pump();
    expect(find.text('Mani'), findsOneWidget); // only the Agents section row
    await t.tap(find.text('Zed').last);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    // the pill shows the chosen agent even though Zed has no bills
    expect(find.text('Zed'), findsWidgets);
    // the agent view opens, with a way back to all agents
    expect(find.text('Commission earned'), findsOneWidget);
    expect(find.text('No bills for Zed in this period'), findsOneWidget);
  });
}
