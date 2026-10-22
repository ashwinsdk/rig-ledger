import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_line.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/models/step_rates.dart';
import 'package:rig_ledger/core/services/sync_service.dart';

void main() {
  group('StepTable', () {
    test('the built-in tables give exactly the old numbers', () {
      double old(String t, double ft) => LedgerEntry.calculateStepRate(
          depthType: t, depthInFeet: ft, baseRate: 100);
      const feet = <double>[
        0,
        250,
        300,
        350,
        400,
        420,
        650,
        900,
        950,
        1000,
        1234.5
      ];
      for (final ft in feet) {
        expect(StepTable.builtin7.calculate(ft), old('7inch', ft),
            reason: '$ft');
        expect(StepTable.builtin8.calculate(ft), old('8inch', ft),
            reason: '$ft');
      }
      // hand computed from the old brackets
      expect(StepTable.builtin7.calculate(1000), 38000); // 27000 + 100 x 110
      expect(StepTable.builtin8.calculate(1000), 43000); // 31000 + 100 x 120
      expect(StepTable.builtin7.calculate(950), 32500); // 27000 + 50 x 110
      expect(StepTable.builtin7.calculate(350), 500); // 50 x 10
      expect(StepTable.builtin8.calculate(420), 1400); // 100 x 10 + 20 x 20
      // beyond 900: 100 x (90 + 20) for 900 to 1000 on the 7 inch table
      expect(
          StepTable.builtin7.calculate(1000) -
              StepTable.builtin7.calculate(900),
          100 * 110);
    });

    test('an edited table changes the result', () {
      const t = StepTable(threshold: 200, extras: [5, 15], beyondIncrement: 10);
      expect(t.calculate(200), 0);
      expect(t.calculate(250), 50 * 5);
      expect(t.calculate(350), 100 * 5 + 50 * 15);
      // beyond 400: first further 100 ft add 15 + 10
      expect(t.calculate(500), 100 * 5 + 100 * 15 + 100 * 25);
      expect(
          const StepTable(threshold: 300, extras: [], beyondIncrement: 5)
              .calculate(500),
          0);
    });

    test('json round trip and a broken value falls back', () {
      const t = StepTable(threshold: 250, extras: [1, 2.5], beyondIncrement: 3);
      expect(StepTable.fromJson(t.toJson(), StepTable.builtin7), t);
      expect(
          StepTable.fromJson('junk', StepTable.builtin7), StepTable.builtin7);
    });
  });

  group('StepRates per rig', () {
    final t0 = DateTime(2026, 1, 1);
    final custom = StepTable(threshold: 300, extras: [50], beyondIncrement: 0);

    test('a rig without a saved table uses the built-in ones', () {
      const rates = StepRates();
      expect(rates.forRig('r1').table7, StepTable.builtin7);
      expect(rates.forRig('r1').isStandard, isTrue);
    });

    test('lines use the rig table of the line type', () {
      final lines = [
        const LedgerLine(category: 'depth', type: '7inch', feet: 350, rate: 1),
        const LedgerLine(category: 'depth', type: '8inch', feet: 350, rate: 1),
      ];
      final types = LedgerTypes.defaults();
      expect(LedgerEntry.calculateLinesStepRate(lines, types), 1000);
      final rig =
          RigStepRates(table7: custom, updatedAt: t0); // only 7 inch edited
      // 7inch line: 50 ft x 50 = 2500, 8inch line unchanged 500
      expect(LedgerEntry.calculateLinesStepRate(lines, types, rig: rig), 3000);
    });

    test('merge keeps the newer side per rig and rigs on one side', () {
      final a = StepRates({
        'r1': RigStepRates(table7: custom, updatedAt: DateTime(2026, 3, 1)),
        'r2': RigStepRates(updatedAt: DateTime(2026, 1, 1)),
      });
      final b = StepRates({
        'r1': RigStepRates(updatedAt: DateTime(2026, 2, 1)),
        'r3': RigStepRates(table8: custom, updatedAt: DateTime(2026, 1, 1)),
      });
      final m = StepRates.merge(a, b);
      expect(m.forRig('r1').table7, custom); // a is newer
      expect(m.byRig.keys.toSet(), {'r1', 'r2', 'r3'});
      final back = StepRates.merge(b, a);
      expect(back.forRig('r1').table7, custom);
    });

    test('snapshots merge the stepRates key', () {
      final merged = SyncService.mergeSnapshots(
        {
          'stepRates': StepRates({
            'r1': RigStepRates(table7: custom, updatedAt: DateTime(2026, 3, 1))
          }).toJson()
        },
        {'stepRates': const StepRates().toJson()},
      );
      expect(
          StepRates.fromJson(merged['stepRates']).forRig('r1').table7, custom);
    });
  });

  group('database', () {
    late Directory dir;
    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('step_rates_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });
    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('save, backup, restore, and an older backup keeps local tables',
        () async {
      final custom =
          StepTable(threshold: 280, extras: [12, 22], beyondIncrement: 5);
      await DatabaseService.saveStepRates(StepRates({
        'default_vehicle':
            RigStepRates(table7: custom, updatedAt: DateTime(2026, 5, 1)),
      }));
      final backup = await DatabaseService.createBackup();
      expect(backup['stepRates'], isNotNull);
      await DatabaseService.saveStepRates(const StepRates());
      await DatabaseService.restoreBackup(backup);
      expect(DatabaseService.getStepRates().forRig('default_vehicle').table7,
          custom);
      final old = Map<String, dynamic>.from(backup)..remove('stepRates');
      await DatabaseService.restoreBackup(old);
      expect(DatabaseService.getStepRates().forRig('default_vehicle').table7,
          custom); // restore without the key leaves local tables
    });
  });
}
