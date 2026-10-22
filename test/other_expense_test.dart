import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/other_expense_entry.dart';
import 'package:rig_ledger/core/services/sync_service.dart';

OtherExpenseEntry expense(String id, String vehicleId,
    {double total = 500, DateTime? updated}) {
  final now = updated ?? DateTime(2026, 3, 1);
  return OtherExpenseEntry(
    id: id,
    vehicleId: vehicleId,
    date: DateTime(2026, 3, 1),
    description: 'Tea and food',
    total: total,
    paid: 200,
    pending: total - 200,
    balance: total - 200,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('json round trip keeps every field, billNumber optional', () {
    final e = expense('o1', 'v1').copyWith(notes: 'site visit');
    final back = OtherExpenseEntry.fromJson(e.toJson());
    expect(back.description, 'Tea and food');
    expect(back.billNumber, '');
    expect(back.notes, 'site visit');
    expect(back.balance, 300);
    final legacy = e.toJson()..remove('billNumber');
    expect(OtherExpenseEntry.fromJson(legacy).billNumber, '');
  });

  test('sync merge keeps the newest copy of an entry', () {
    final older = expense('o1', 'v1', total: 100).toJson();
    final newer =
        expense('o1', 'v1', total: 900, updated: DateTime(2026, 4, 1)).toJson();
    final merged = SyncService.mergeSnapshots(
      {
        'otherExpenseEntries': [older]
      },
      {
        'otherExpenseEntries': [newer]
      },
    );
    final list = merged['otherExpenseEntries'] as List;
    expect(list.length, 1);
    expect(list.first['total'], 900);
  });

  group('database', () {
    late Directory dir;
    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('other_expense_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });
    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('save, list by rig, delete leaves a tombstone, backup round trip',
        () async {
      await DatabaseService.saveOtherExpenseEntry(expense('a', 'v1'));
      await DatabaseService.saveOtherExpenseEntry(expense('b', 'v2'));
      expect(DatabaseService.getOtherExpenseEntriesByVehicle('v1').length, 1);

      final backup = await DatabaseService.createBackup();
      expect((backup['otherExpenseEntries'] as List).length, 2);

      await DatabaseService.deleteOtherExpenseEntry('a');
      expect(DatabaseService.getOtherExpenseEntriesByVehicle('v1'), isEmpty);

      await DatabaseService.restoreBackup(backup);
      expect(DatabaseService.getAllOtherExpenseEntries().length, 2);

      // A backup from before 2.0.1 has no key and restores to none.
      final old = Map<String, dynamic>.from(backup)
        ..remove('otherExpenseEntries');
      await DatabaseService.restoreBackup(old);
      expect(DatabaseService.getAllOtherExpenseEntries(), isEmpty);
    });
  });
}
