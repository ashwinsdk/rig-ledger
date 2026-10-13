import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';

Agent agent(
    {String json = '', double depth = 0, double pvc = 0, double ms = 0}) {
  final now = DateTime(2026, 1, 1);
  return Agent(
    id: 'a1',
    name: 'Murugan',
    createdAt: now,
    updatedAt: now,
    depthCommissionRate: depth,
    pvcCommissionRate: pvc,
    msPipeCommissionRate: ms,
    commissionRatesJson: json,
  );
}

void main() {
  group('Agent prices by type', () {
    test('the price of the type, else the default of the category', () {
      final a = agent(
        json: Agent.encodeRates({'depth:9inch': 15, 'pvc:7inch': 40}),
        depth: 10,
        pvc: 5,
        ms: 2,
      );
      expect(a.rateFor('depth', '9inch'), 15);
      expect(a.rateFor('depth', '7inch'), 10); // no price: default
      expect(a.rateFor('pvc', '7inch'), 40);
      expect(a.rateFor('pvc', '8inch'), 5);
      expect(a.rateFor('ms', '6inch'), 2);
    });

    test('map round trip, old maps and damaged json', () {
      final a = agent(json: Agent.encodeRates({'depth:9inch': 15.5}));
      final back = Agent.fromMap(a.toMap());
      expect(back.commissionRates, {'depth:9inch': 15.5});
      final old = a.toMap()..remove('commissionRates');
      expect(Agent.fromMap(old).commissionRatesJson, '');
      expect(Agent.fromMap(old).commissionRates, isEmpty);
      expect(agent(json: 'not json').commissionRates, isEmpty);
      expect(agent(json: 'not json').rateFor('depth', '9inch'), 0);
      expect(Agent.encodeRates({}), '');
    });
  });

  group('with a real database', () {
    late Directory dir;

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('agent_commission_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });

    setUp(() async {
      await DatabaseService.settingsBox.delete('ledgerTypes');
      await DatabaseService.ledgerBox.clear();
      await DatabaseService.agentBox.clear();
    });

    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('renaming a type moves the agent price, deleting removes it',
        () async {
      await DatabaseService.saveAgent(agent(
          json: Agent.encodeRates({'depth:8inch': 12, 'pvc:8inch': 44}),
          depth: 9));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(ledgerTypesProvider.notifier);

      await n.renameType(LedgerTypeCategory.depth, '8inch', '8.5');
      var rates = DatabaseService.getAgent('a1')!.commissionRates;
      expect(rates['depth:8.5inch'], 12);
      expect(rates.containsKey('depth:8inch'), isFalse);
      expect(rates['pvc:8inch'], 44); // other category untouched

      await n.deleteType(LedgerTypeCategory.pvc, '8inch');
      rates = DatabaseService.getAgent('a1')!.commissionRates;
      expect(rates.containsKey('pvc:8inch'), isFalse);
      expect(rates['depth:8.5inch'], 12);
    });
  });
}
