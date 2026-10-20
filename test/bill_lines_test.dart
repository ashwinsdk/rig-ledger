import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_line.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/utils/feet_totals.dart';

LedgerEntry bill({String id = 'b1', String? linesJson}) {
  final now = DateTime(2026, 5, 1);
  return LedgerEntry(
    id: id,
    date: now,
    billNumber: id,
    agentId: 'a',
    agentName: 'A',
    address: 'X',
    depth: '7inch',
    depthInFeet: 100,
    depthPerFeetRate: 10,
    pvc: '8inch',
    pvcInFeet: 20,
    pvcPerFeetRate: 5,
    msPipe: '6inch',
    extraCharges: 0,
    total: 1100,
    isTotalManuallyEdited: false,
    received: 0,
    balance: 1100,
    less: 0,
    createdAt: now,
    updatedAt: now,
    vehicleId: 'default_vehicle',
    depthCommissionRate: 2,
    pvcCommissionRate: 1,
    linesJson: linesJson,
  );
}

void main() {
  group('lines model', () {
    test('an old bill gets one line per used category', () {
      final b = bill();
      expect(b.lines.length, 2); // depth and pvc, no ms feet
      expect(b.linesOf('depth').single.type, '7inch');
      expect(b.linesOf('depth').single.feet, 100);
      expect(b.linesOf('pvc').single.type, '8inch');
      expect(b.typesOf('ms'), {'6inch'}); // falls back to the type field
    });

    test('withLines keeps feet, average rate and first type in step', () {
      final lines = [
        const LedgerLine(
            category: 'depth',
            type: '7inch',
            feet: 200,
            rate: 10,
            commissionRate: 2),
        const LedgerLine(
            category: 'depth',
            type: '8inch',
            feet: 100,
            rate: 16,
            commissionRate: 3),
        const LedgerLine(category: 'pvc', type: '8inch', feet: 20, rate: 5),
      ];
      final b = bill().withLines(lines);
      expect(b.depth, '7inch');
      expect(b.depthInFeet, 300);
      // 200 x 10 + 100 x 16 = 3600 -> average 12
      expect(b.depthPerFeetRate, closeTo(12, 1e-9));
      expect(b.depthInFeet * b.depthPerFeetRate, closeTo(3600, 1e-6));
      expect(b.depthCommissionRate, closeTo((400 + 300) / 300, 1e-9));
      expect(b.pvcInFeet, 20);
      expect(b.typesOf('depth'), {'7inch', '8inch'});
      expect(b.feetOf('depth'), 300);
      expect(b.commissionOf('depth'), 700);
      expect(LedgerEntry.calculateLinesCommission(b.lines), 700);
      expect(
          LedgerEntry.calculateLinesTotal(
              lines: b.lines, stepRate: 0, extraCharges: 50),
          3600 + 100 + 50);
    });

    test('step rate is worked out per depth line with its own table', () {
      final types = LedgerTypes.defaults();
      final lines = [
        const LedgerLine(category: 'depth', type: '7inch', feet: 350, rate: 10),
        const LedgerLine(category: 'depth', type: '8inch', feet: 350, rate: 10),
        const LedgerLine(category: 'pvc', type: '7inch', feet: 999, rate: 10),
      ];
      // 7inch: 50 ft x 10 = 500, 8inch: 50 ft x 10 = 500; PVC is ignored
      expect(LedgerEntry.calculateLinesStepRate(lines, types), 1000);
      // each line alone is 350 ft, not one 700 ft run
      expect(LedgerEntry.calculateLinesStepRate([lines[0]], types), 500);
    });

    test('toMap and fromMap keep the lines, old maps load without them', () {
      final b = bill().withLines(const [
        LedgerLine(category: 'depth', type: '9inch', feet: 50, rate: 12),
      ]);
      final back = LedgerEntry.fromMap(b.toMap());
      expect(back.linesOf('depth').single.type, '9inch');
      final old = bill().toMap()..remove('linesJson');
      expect(LedgerEntry.fromMap(old).linesJson, isNull);
      expect(LedgerEntry.fromMap(old).lines.length, 2);
    });
  });

  group('lines elsewhere', () {
    final two = bill().withLines(const [
      LedgerLine(category: 'depth', type: '7inch', feet: 200, rate: 10),
      LedgerLine(category: 'depth', type: '8inch', feet: 150, rate: 12),
      LedgerLine(category: 'pvc', type: '7inch', feet: 30, rate: 5),
      LedgerLine(category: 'pvc', type: '8inch', feet: 20, rate: 5),
      LedgerLine(category: 'ms', type: '6inch', feet: 10, rate: 50),
    ]);

    test('feet totals count every line under its own type', () {
      final t =
          FeetTotals.compute([two, bill(id: 'b2')], LedgerTypes.defaults());
      expect(t.depth['7inch'], 300); // 200 + the old bill's 100
      expect(t.depth['8inch'], 150);
      expect(t.pvc['7inch'], 30);
      expect(t.pvc['8inch'], 40); // 20 + the old bill's 20
      expect(t.ms['6inch'], 10);
      expect(t.depthTotal, 450);
      expect(t.msPipeTotal, 10);
    });

    test('type text and csv show every type', () {
      expect(two.typeLabel('depth'), '7inch + 8inch');
      final row = two.toCsvRow();
      expect(row[4], '7inch + 8inch');
      expect(row[5], '350.0');
      expect(bill().typeLabel('depth'), '7inch');
    });
  });

  group('database', () {
    late Directory dir;
    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('bill_lines_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });
    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('type counts, usage and rename see every line', () async {
      final b = bill().withLines(const [
        LedgerLine(category: 'depth', type: '7inch', feet: 100, rate: 10),
        LedgerLine(category: 'depth', type: '9inch', feet: 50, rate: 12),
      ]);
      await DatabaseService.saveLedgerEntry(b);
      expect(
          DatabaseService.countBillsWithType(LedgerTypeCategory.depth, '9inch'),
          1);
      expect(
          DatabaseService.usedLedgerTypes(LedgerTypeCategory.depth)
              .contains('9inch'),
          isTrue);
      await DatabaseService.renameBillType(
          LedgerTypeCategory.depth, '9inch', '10inch');
      final saved = DatabaseService.getAllLedgerEntries().single;
      expect(saved.typesOf('depth'), {'7inch', '10inch'});
      expect(saved.depth, '7inch');
      // a type used by a line cannot be deleted
      expect(
          DatabaseService.countBillsWithType(
              LedgerTypeCategory.depth, '10inch'),
          1);
    });
  });
}
