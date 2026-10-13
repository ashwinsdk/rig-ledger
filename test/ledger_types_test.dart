import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/models/vehicle.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';
import 'package:rig_ledger/core/services/sync_service.dart';

LedgerEntry bill(String id,
    {String depth = '7inch',
    String pvc = '7inch',
    String ms = '6inch',
    String vehicleId = 'default_vehicle'}) {
  final now = DateTime(2026, 1, 1);
  return LedgerEntry(
    id: id,
    date: now,
    billNumber: id,
    agentId: 'a',
    agentName: 'A',
    address: 'X',
    depth: depth,
    depthInFeet: 100,
    depthPerFeetRate: 10,
    pvc: pvc,
    msPipe: ms,
    extraCharges: 0,
    total: 1000,
    isTotalManuallyEdited: false,
    received: 0,
    balance: 1000,
    less: 0,
    createdAt: now,
    updatedAt: now,
    vehicleId: vehicleId,
  );
}

void main() {
  group('LedgerTypes model', () {
    test('size input becomes a type name', () {
      expect(LedgerTypes.nameFromInches('9'), '9inch');
      expect(LedgerTypes.nameFromInches(' 9.5 '), '9.5inch');
      expect(LedgerTypes.nameFromInches('9.50 inch'), '9.5inch');
      expect(LedgerTypes.nameFromInches('10'), '10inch');
      expect(LedgerTypes.nameFromInches('0'), isNull);
      expect(LedgerTypes.nameFromInches('abc'), isNull);
      expect(LedgerTypes.nameFromInches('100'), isNull);
      expect(LedgerTypes.nameFromInches(''), isNull);
    });

    test('defaults, json round trip and damaged input', () {
      final d = LedgerTypes.defaults();
      expect(d.depth, ['7inch', '8inch']);
      expect(d.pvc, ['7inch', '8inch']);
      expect(d.ms, ['6inch']);
      final t = LedgerTypes(
        depth: const ['7inch', '9inch'],
        pvc: const ['8inch'],
        ms: const ['6inch', '8inch'],
        steps: const {'9inch': '8inch', '7inch': 'none'},
        updatedAt: DateTime(2026, 5, 1),
      );
      final back = LedgerTypes.fromJson(t.encode());
      expect(back.depth, t.depth);
      expect(back.ms, t.ms);
      expect(back.steps, t.steps);
      expect(back.updatedAt, t.updatedAt);
      expect(LedgerTypes.fromJson('not json').depth, d.depth);
      expect(LedgerTypes.fromJson(null).depth, d.depth);
      expect(LedgerTypes.fromJson({'depth': 'x'}).depth, d.depth);
    });

    test('step table lookup', () {
      final t = LedgerTypes(
        depth: const ['7inch', '8inch', '9inch', '10inch'],
        pvc: const [],
        ms: const [],
        steps: const {'9inch': '8inch', '7inch': 'none'},
        updatedAt: DateTime(2026),
      );
      expect(t.stepTableFor('8inch'), '8inch'); // built in
      expect(t.stepTableFor('7inch'), isNull); // explicitly none
      expect(t.stepTableFor('9inch'), '8inch'); // chosen
      expect(t.stepTableFor('10inch'), isNull); // new type: none
    });

    test('withCurrent keeps an unlisted type selectable', () {
      final d = LedgerTypes.defaults();
      expect(d.withCurrent(LedgerTypeCategory.depth, '12inch'),
          ['7inch', '8inch', '12inch']);
      expect(
          d.withCurrent(LedgerTypeCategory.depth, '8inch'), ['7inch', '8inch']);
    });
  });

  group('step rate tables', () {
    double step(String type, double ft, {String? table}) =>
        LedgerEntry.calculateStepRate(
            depthType: type, depthInFeet: ft, baseRate: 100, stepTable: table);

    test('7inch and 8inch are unchanged', () {
      expect(step('7inch', 350), 500); // 50 ft x 10
      expect(step('8inch', 420), 1400); // 100 x 10 + 20 x 20
      expect(step('7inch', 250), 0);
    });

    test('a new type has no step rate unless a table is chosen', () {
      expect(step('9inch', 420), 0);
      expect(step('9inch', 420, table: '8inch'), step('8inch', 420));
      expect(step('9inch', 420, table: '7inch'), step('7inch', 420));
    });
  });

  group('provider rules with a real database', () {
    late Directory dir;
    late ProviderContainer c;

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('ledger_types_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });

    setUp(() async {
      await DatabaseService.settingsBox.delete('ledgerTypes');
      await DatabaseService.ledgerBox.clear();
      c = ProviderContainer();
      addTearDown(c.dispose);
    });

    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    LedgerTypesNotifier n() => c.read(ledgerTypesProvider.notifier);

    test('add: sorted, validated, no duplicates, stored', () async {
      expect((await n().addType(LedgerTypeCategory.depth, '9')).$1, isTrue);
      expect((await n().addType(LedgerTypeCategory.depth, '6.5')).$1, isTrue);
      expect(c.read(ledgerTypesProvider).depth,
          ['6.5inch', '7inch', '8inch', '9inch']);
      final dup = await n().addType(LedgerTypeCategory.depth, '9');
      expect(dup.$1, isFalse);
      expect(dup.$2, contains('already exists'));
      expect((await n().addType(LedgerTypeCategory.depth, 'x')).$1, isFalse);
      // stored: a fresh notifier reads it back
      final again = ProviderContainer();
      addTearDown(again.dispose);
      expect(again.read(ledgerTypesProvider).depth, contains('9inch'));
    });

    test('rename updates every bill and carries the step table', () async {
      await DatabaseService.saveLedgerEntry(bill('b1', depth: '8inch'));
      await DatabaseService.saveLedgerEntry(bill('b2', depth: '8inch'));
      await DatabaseService.saveLedgerEntry(bill('b3', depth: '7inch'));
      final r = await n().renameType(LedgerTypeCategory.depth, '8inch', '8.5');
      expect(r.$1, isTrue);
      expect(DatabaseService.ledgerBox.get('b1')!.depth, '8.5inch');
      expect(DatabaseService.ledgerBox.get('b2')!.depth, '8.5inch');
      expect(DatabaseService.ledgerBox.get('b3')!.depth, '7inch');
      final t = c.read(ledgerTypesProvider);
      expect(t.depth, ['7inch', '8.5inch']);
      expect(t.stepTableFor('8.5inch'), '8inch'); // still the 8 inch table
      // renaming onto an existing size is refused
      final clash =
          await n().renameType(LedgerTypeCategory.depth, '8.5inch', '7');
      expect(clash.$1, isFalse);
    });

    test('delete is blocked while bills use the type, and for the last one',
        () async {
      await DatabaseService.saveLedgerEntry(bill('b1', depth: '8inch'));
      final blocked = await n().deleteType(LedgerTypeCategory.depth, '8inch');
      expect(blocked.$1, isFalse);
      expect(blocked.$2, contains('1 bill uses 8inch'));
      expect(c.read(ledgerTypesProvider).depth, contains('8inch'));

      await DatabaseService.ledgerBox.clear();
      expect(
          (await n().deleteType(LedgerTypeCategory.depth, '8inch')).$1, isTrue);
      expect(c.read(ledgerTypesProvider).depth, ['7inch']);
      final last = await n().deleteType(LedgerTypeCategory.depth, '7inch');
      expect(last.$1, isFalse);
      expect(last.$2, contains('at least one'));
    });

    test('side bore bills do not count as using a type', () async {
      await DatabaseService.saveVehicle(Vehicle(
        id: 'side_rig',
        name: 'Side Rig',
        vehicleTypeIndex: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ));
      await DatabaseService.saveLedgerEntry(
          bill('s1', depth: '8inch', vehicleId: 'side_rig'));
      expect(
          DatabaseService.countBillsWithType(LedgerTypeCategory.depth, '8inch'),
          0);
    });

    test('a type used by bills but missing from the list is shown anyway',
        () async {
      await DatabaseService.saveLedgerEntry(bill('b1', depth: '12inch'));
      c.read(ledgerTypesProvider.notifier).refresh();
      expect(c.read(ledgerTypesProvider).depth, contains('12inch'));
    });

    test('step choice, including none for 7inch', () async {
      await n().setStepTable('7inch', null);
      expect(c.read(ledgerTypesProvider).stepTableFor('7inch'), isNull);
      await n().addType(LedgerTypeCategory.depth, '9');
      await n().setStepTable('9inch', '8inch');
      expect(c.read(ledgerTypesProvider).stepTableFor('9inch'), '8inch');
      await n().setStepTable('9inch', null);
      expect(c.read(ledgerTypesProvider).stepTableFor('9inch'), isNull);
    });

    test('backup carries the lists and an old backup keeps the local ones',
        () async {
      await n().addType(LedgerTypeCategory.ms, '8');
      final backup = await DatabaseService.createBackup();
      expect(backup['version'], DatabaseService.schemaVersion);
      expect((backup['ledgerTypes'] as Map)['ms'], contains('8inch'));

      await DatabaseService.settingsBox.delete('ledgerTypes');
      await DatabaseService.restoreBackup(backup);
      expect(DatabaseService.getLedgerTypes().ms, contains('8inch'));

      final old = Map<String, dynamic>.from(backup)..remove('ledgerTypes');
      await DatabaseService.restoreBackup(old);
      expect(DatabaseService.getLedgerTypes().ms, contains('8inch'));
    });
  });

  group('sync merge', () {
    Map<String, dynamic> snap(Map<String, dynamic>? types) => {
          'version': 6,
          if (types != null) 'ledgerTypes': types,
        };

    test('the newer lists win, one sided is kept, none stays absent', () {
      final older = LedgerTypes(
              depth: const ['7inch'],
              pvc: const ['7inch'],
              ms: const ['6inch'],
              updatedAt: DateTime(2026, 1, 1))
          .toJson();
      final newer = LedgerTypes(
              depth: const ['7inch', '9inch'],
              pvc: const ['7inch'],
              ms: const ['6inch'],
              updatedAt: DateTime(2026, 2, 1))
          .toJson();
      final a = SyncService.mergeSnapshots(snap(older), snap(newer));
      expect((a['ledgerTypes'] as Map)['depth'], ['7inch', '9inch']);
      final b = SyncService.mergeSnapshots(snap(newer), snap(older));
      expect((b['ledgerTypes'] as Map)['depth'], ['7inch', '9inch']);
      final one = SyncService.mergeSnapshots(snap(null), snap(newer));
      expect((one['ledgerTypes'] as Map)['depth'], ['7inch', '9inch']);
      final none = SyncService.mergeSnapshots(snap(null), snap(null));
      expect(none.containsKey('ledgerTypes'), isFalse);
    });
  });
}
