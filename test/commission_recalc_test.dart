import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_line.dart';
import 'package:rig_ledger/core/services/commission_recalc.dart';

Agent agent({double depth = 0, Map<String, double> prices = const {}}) {
  final now = DateTime(2026, 1, 1);
  return Agent(
    id: 'a1',
    name: 'Karthik',
    createdAt: now,
    updatedAt: now,
    depthCommissionRate: depth,
    commissionRatesJson: Agent.encodeRates(prices),
  );
}

LedgerEntry bill(String id,
    {List<LedgerLine>? lines, bool manual = false, String vehicle = 'v'}) {
  final now = DateTime(2026, 5, 1);
  final b = LedgerEntry(
    id: id,
    date: now,
    billNumber: id,
    agentId: 'a1',
    agentName: 'Karthik',
    address: 'X',
    depth: '7inch',
    depthInFeet: 0,
    depthPerFeetRate: 0,
    pvc: '7inch',
    msPipe: '6inch',
    extraCharges: 0,
    total: 0,
    isTotalManuallyEdited: false,
    received: 0,
    balance: 0,
    less: 0,
    createdAt: now,
    updatedAt: now,
    vehicleId: vehicle,
    isCommissionManuallyEdited: manual,
    commission: manual ? 999 : 0,
  );
  return b.withLines(lines ??
      const [
        LedgerLine(
            category: 'depth',
            type: '7inch',
            feet: 100,
            rate: 10,
            commissionRate: 12),
      ]);
}

void main() {
  final old = agent(prices: {'depth:7inch': 12, 'depth:8inch': 14});
  final updated = agent(prices: {'depth:7inch': 20, 'depth:8inch': 14});

  group('which bills change', () {
    test('a rate that came from the agent follows the new price', () {
      final out = CommissionRecalc.changedBills(
        oldAgent: old,
        newAgent: updated,
        bills: [bill('b1')],
        isSideBore: (_) => false,
      );
      expect(out.length, 1);
      expect(out.single.linesOf('depth').single.commissionRate, 20);
      expect(out.single.commission, 2000); // 100 ft x 20
      expect(out.single.depthCommissionRate, 20);
    });

    test('a hand typed rate and a hand set commission are kept', () {
      final typed = bill('typed', lines: const [
        LedgerLine(
            category: 'depth',
            type: '7inch',
            feet: 100,
            rate: 10,
            commissionRate: 15),
      ]);
      final manual = bill('manual', manual: true);
      final out = CommissionRecalc.changedBills(
        oldAgent: old,
        newAgent: updated,
        bills: [typed, manual],
        isSideBore: (_) => false,
      );
      expect(out, isEmpty);
    });

    test('each line is judged on its own and unchanged types stay', () {
      final two = bill('two', lines: const [
        LedgerLine(
            category: 'depth',
            type: '7inch',
            feet: 100,
            rate: 10,
            commissionRate: 12),
        LedgerLine(
            category: 'depth',
            type: '8inch',
            feet: 50,
            rate: 10,
            commissionRate: 14),
      ]);
      final out = CommissionRecalc.changedBills(
        oldAgent: old,
        newAgent: updated,
        bills: [two],
        isSideBore: (_) => false,
      ).single;
      expect(out.linesOf('depth')[0].commissionRate, 20);
      expect(out.linesOf('depth')[1].commissionRate, 14);
      expect(out.commission, 100 * 20 + 50 * 14);
    });

    test('a bill with no commission yet gets the first price', () {
      final none = bill('none', lines: const [
        LedgerLine(category: 'depth', type: '7inch', feet: 40, rate: 10),
      ]);
      final out = CommissionRecalc.changedBills(
        oldAgent: agent(),
        newAgent: agent(prices: {'depth:7inch': 5}),
        bills: [none],
        isSideBore: (_) => false,
      ).single;
      expect(out.commission, 200);
    });

    test('side bore bills follow the default depth rate', () {
      final side = bill('side', vehicle: 'sv', lines: const [
        LedgerLine(
            category: 'depth',
            type: '7inch',
            feet: 100,
            rate: 80,
            commissionRate: 5),
      ]);
      final out = CommissionRecalc.changedBills(
        oldAgent: agent(depth: 5),
        newAgent: agent(depth: 7),
        bills: [side],
        isSideBore: (v) => v == 'sv',
      ).single;
      expect(out.commission, 700);
    });

    test('other agents bills are ignored', () {
      final other = bill('o').copyWith(agentId: 'a2');
      expect(
          CommissionRecalc.changedBills(
            oldAgent: old,
            newAgent: updated,
            bills: [other],
            isSideBore: (_) => false,
          ),
          isEmpty);
    });
  });

  group('database', () {
    late Directory dir;
    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('commission_recalc_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });
    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('apply saves the changed bills and counts them', () async {
      await DatabaseService.saveLedgerEntry(
          bill('b1', vehicle: 'default_vehicle'));
      await DatabaseService.saveLedgerEntry(
          bill('b2', manual: true, vehicle: 'default_vehicle'));
      final n = await CommissionRecalc.apply(oldAgent: old, newAgent: updated);
      expect(n, 1);
      final saved = {
        for (final e in DatabaseService.getAllLedgerEntries()) e.id: e
      };
      expect(saved['b1']!.commission, 2000);
      expect(saved['b2']!.commission, 999);
    });

    test('saving the agent through the provider recalculates its bills',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await DatabaseService.saveAgent(old);
      await DatabaseService.saveLedgerEntry(
          bill('p1', vehicle: 'default_vehicle'));
      final changed = await container
          .read(agentsProvider.notifier)
          .updateAgent(updated.copyWith(name: 'Karthik K'));
      expect(changed, greaterThanOrEqualTo(1));
      final p1 =
          DatabaseService.getAllLedgerEntries().firstWhere((e) => e.id == 'p1');
      expect(p1.commission, 2000);
      expect(p1.agentName, 'Karthik K');
    });
  });
}
