import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_line.dart';
import 'package:rig_ledger/features/portfolio/portfolio_view.dart';

LedgerEntry bill(String no, DateTime date, double feet, double comm,
    {String agentId = 'a1', bool manual = false}) {
  final b = LedgerEntry(
    id: 'id-$no',
    date: date,
    billNumber: no,
    agentId: agentId,
    agentName: agentId == 'a1' ? 'Karthik' : 'Zed',
    address: 'Town $no',
    depth: '7inch',
    depthInFeet: 0,
    depthPerFeetRate: 0,
    pvc: '7inch',
    msPipe: '6inch',
    extraCharges: 0,
    total: feet * 100,
    isTotalManuallyEdited: false,
    received: feet * 60,
    balance: feet * 40,
    less: 0,
    createdAt: date,
    updatedAt: date,
    vehicleId: 'default_vehicle',
    isCommissionManuallyEdited: manual,
    commission: feet * comm,
  );
  return b.withLines([
    LedgerLine(
        category: 'depth',
        type: '7inch',
        feet: feet,
        rate: 100,
        commissionRate: comm),
  ]).copyWith(commission: feet * comm);
}

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('agent_view_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
    final now = DateTime(2026, 1, 1);
    await DatabaseService.saveAgent(Agent(
        id: 'a1',
        name: 'Karthik',
        vehicleId: 'default_vehicle',
        phone: '99999',
        createdAt: now,
        updatedAt: now));
    await DatabaseService.saveAgent(Agent(
        id: 'a2',
        name: 'Zed',
        vehicleId: 'default_vehicle',
        createdAt: now,
        updatedAt: now));
    await DatabaseService.saveLedgerEntry(
        bill('B1', DateTime(2026, 8, 10), 100, 10));
    await DatabaseService.saveLedgerEntry(
        bill('B2', DateTime(2026, 9, 5), 200, 10));
    await DatabaseService.saveLedgerEntry(
        bill('B3', DateTime(2026, 10, 2), 50, 12, manual: true));
    await DatabaseService.saveLedgerEntry(
        bill('Z1', DateTime(2026, 9, 9), 70, 10, agentId: 'a2'));
    await DatabaseService.saveLedgerEntry(
        bill('OLD', DateTime(2026, 2, 1), 10, 10));
  });
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('one agent over three months: totals, months and every bill',
      (t) async {
    t.view.physicalSize = const Size(412, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: PortfolioView(
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 10, 31, 23, 59, 59),
          ),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 300));

    // pick the agent from the Agents section
    await t.ensureVisible(find.text('Karthik'));
    await t.tap(find.text('Karthik'));
    await t.pump(const Duration(milliseconds: 400));

    expect(find.text('Commission earned'), findsOneWidget);
    // 100 x 10 + 200 x 10 + 50 x 12 = 3600, three bills, the Feb bill is out
    expect(find.text('₹3,600.00'), findsWidgets);
    // profit stays visible: received 6000 + 12000 + 3000 = 21000 minus 3600
    expect(find.text('Profit from this agent (received - commission)'),
        findsOneWidget);
    expect(find.text('₹17,400.00'), findsOneWidget);
    expect(find.textContaining('All agents, after expenses'), findsOneWidget);
    // feet by type: 100 + 200 + 50 ft of 7inch depth
    expect(find.text('Feet by type'), findsOneWidget);
    expect(find.text('Total 350 ft'), findsOneWidget);
    expect(find.text('7"  350 ft', findRichText: true), findsOneWidget);
    expect(find.text('By month'), findsOneWidget);
    for (final m in ['Aug 2026', 'Sep 2026', 'Oct 2026']) {
      expect(find.text(m), findsOneWidget);
    }
    for (final no in ['#B1', '#B2', '#B3']) {
      expect(find.text(no), findsOneWidget);
    }
    expect(find.text('#Z1'), findsNothing);
    expect(find.text('#OLD'), findsNothing);
    expect(find.text('Commission (manual)'), findsOneWidget); // B3
    expect(find.text('3 bills'), findsOneWidget);

    // back to everybody
    await t.tap(find.text('All agents').first);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Commission earned'), findsNothing);
  });
}
