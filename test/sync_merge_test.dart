import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/services/sync_service.dart';

Map<String, dynamic> cashEntry(String id, double amount, DateTime updated) => {
      'id': id,
      'bookId': 'b1',
      'date': DateTime(2026, 1, 1).toIso8601String(),
      'amount': amount,
      'isCashIn': true,
      'notes': '',
      'isDeleted': false,
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': updated.toIso8601String(),
    };

Map<String, dynamic> snapshot(
        {List<Map<String, dynamic>>? cash,
        List<Map<String, dynamic>> tombstones = const [],
        bool withCashKeys = true}) =>
    {
      'version': 5,
      'vehicles': [],
      'agents': [],
      'ledgerEntries': [],
      'dieselEntries': [],
      'pvcEntries': [],
      'bitEntries': [],
      'hammerEntries': [],
      'miniLedgerEntries': [],
      if (withCashKeys) 'cashBooks': [],
      if (withCashKeys) 'cashEntries': cash ?? [],
      if (withCashKeys) 'cashNotes': [],
      'tombstones': tombstones,
    };

void main() {
  final t1 = DateTime(2026, 2, 1);
  final t2 = DateTime(2026, 3, 1);

  test('newest cash entry wins and union of ids is kept', () {
    final local = snapshot(
        cash: [cashEntry('a', 100, t1), cashEntry('only-local', 1, t1)]);
    final remote = snapshot(
        cash: [cashEntry('a', 250, t2), cashEntry('only-remote', 2, t1)]);
    final merged = SyncService.mergeSnapshots(local, remote);
    final byId = {for (final e in merged['cashEntries'] as List) e['id']: e};
    expect(byId.keys, containsAll(['a', 'only-local', 'only-remote']));
    expect(byId['a']['amount'], 250);
  });

  test('a tombstone newer than the entry removes it', () {
    final local = snapshot(cash: [cashEntry('gone', 5, t1)]);
    final remote = snapshot(tombstones: [
      {
        'entityId': 'gone',
        'collection': 'cash_entries',
        'deletedAt': t2.toIso8601String(),
      }
    ]);
    final merged = SyncService.mergeSnapshots(local, remote);
    expect((merged['cashEntries'] as List), isEmpty);
  });

  test('snapshots from older versions without cash keys merge fine', () {
    final local = snapshot(cash: [cashEntry('a', 1, t1)]);
    final old = snapshot(withCashKeys: false);
    final merged = SyncService.mergeSnapshots(local, old);
    expect((merged['cashEntries'] as List).length, 1);
    expect(merged['cashBooks'], isEmpty);
    final merged2 = SyncService.mergeSnapshots(old, local);
    expect((merged2['cashEntries'] as List).length, 1);
  });
}
