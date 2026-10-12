import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/models/cash_entry.dart';
import 'package:rig_ledger/core/utils/cashbook_calculator.dart';

CashEntry e(String id, DateTime date, double amount, bool isIn,
    {bool deleted = false}) {
  return CashEntry(
    id: id,
    bookId: 'b',
    date: date,
    amount: amount,
    isCashIn: isIn,
    isDeleted: deleted,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('roundMoney rounds to 2 decimals (PARITY-020)', () {
    expect(CashbookCalculator.roundMoney(1.239), 1.24);
    expect(CashbookCalculator.roundMoney(2500.5), 2500.5);
  });

  test('totals ignore trashed entries and avoid drift (PARITY-034)', () {
    final list = [
      for (var i = 0; i < 10; i++) e('i$i', DateTime(2026, 1, 1), 0.1, true),
      e('o', DateTime(2026, 1, 1), 0.3, false),
      e('x', DateTime(2026, 1, 1), 999, true, deleted: true),
    ];
    final t = CashbookCalculator.totals(list);
    expect(t.cashIn, 1.0);
    expect(t.cashOut, 0.3);
    expect(t.balance, 0.7);
  });

  test('negative balance (PARITY-038)', () {
    final t =
        CashbookCalculator.totals([e('o', DateTime(2026, 1, 1), 800, false)]);
    expect(t.balance, -800);
    expect(CashbookCalculator.formatMoney(t.balance), '-Rs. 800');
  });

  test('running balance is chronological and newest first (PARITY-033)', () {
    final rows = CashbookCalculator.buildRows([
      e('c', DateTime(2026, 1, 3), 400, false),
      e('a', DateTime(2026, 1, 1), 1000, true),
      e('b', DateTime(2026, 1, 2), 2500.5, true),
    ]);
    expect(rows.map((r) => r.entry.id), ['c', 'b', 'a']);
    expect(rows.map((r) => r.balance), [3100.5, 3500.5, 1000]);
  });

  test('previous balance seeds the running balance (PARITY-037)', () {
    final all = [
      e('p', DateTime(2026, 9, 30, 15, 35), 20, true),
      e('a', DateTime(2026, 10, 12), 10, true),
    ];
    final range = CashbookCalculator.periodRange(
        CashPeriod.monthly, DateTime(2026, 10, 12))!;
    final prev = CashbookCalculator.previousBalance(all, range.start);
    expect(prev, 20);
    final rows = CashbookCalculator.buildRows(
        all.where((x) => range.contains(x.date)),
        openingBalance: prev);
    expect(rows.single.balance, 30);
  });

  test('same timestamp ties are stable by createdAt then id', () {
    final d = DateTime(2026, 1, 1);
    final rows = CashbookCalculator.buildRows([
      e('b', d, 1, true),
      e('a', d, 1, true),
    ], ascending: true);
    expect(rows.map((r) => r.entry.id), ['a', 'b']);
  });

  test('groupByDay keeps order', () {
    final rows = CashbookCalculator.buildRows([
      e('1', DateTime(2026, 1, 1, 9), 1, true),
      e('2', DateTime(2026, 1, 1, 10), 1, true),
      e('3', DateTime(2026, 1, 2, 9), 1, true),
    ]);
    final groups = CashbookCalculator.groupByDay(rows);
    expect(groups.length, 2);
    expect(groups.first.day, DateTime(2026, 1, 2));
    expect(groups.last.rows.length, 2);
  });

  test('period ranges', () {
    final monthly = CashbookCalculator.periodRange(
        CashPeriod.monthly, DateTime(2026, 10, 12))!;
    expect(monthly.start, DateTime(2026, 10, 1));
    expect(monthly.lastDay, DateTime(2026, 10, 31));
    expect(
        CashbookCalculator.rangeLabel(monthly), 'Oct-01-2026 -> Oct-31-2026');
    // 2026-10-12 is a Monday; week starts Sunday Oct 11.
    final weekly = CashbookCalculator.periodRange(
        CashPeriod.weekly, DateTime(2026, 10, 12))!;
    expect(weekly.start, DateTime(2026, 10, 11));
    expect(weekly.end, DateTime(2026, 10, 18));
    final yearly = CashbookCalculator.periodRange(
        CashPeriod.yearly, DateTime(2026, 12, 31))!;
    expect(yearly.end, DateTime(2027));
    expect(
        CashbookCalculator.periodRange(CashPeriod.all, DateTime(2026)), isNull);
  });

  test('shiftAnchor crosses month and year boundaries', () {
    expect(
        CashbookCalculator.shiftAnchor(
            CashPeriod.monthly, DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28));
    expect(
        CashbookCalculator.shiftAnchor(
            CashPeriod.monthly, DateTime(2026, 1, 15), -1),
        DateTime(2025, 12, 15));
    expect(
        CashbookCalculator.shiftAnchor(
            CashPeriod.daily, DateTime(2026, 9, 30), 1),
        DateTime(2026, 10, 1));
  });

  test('number formatting (PARITY-035)', () {
    expect(CashbookCalculator.formatNumber(1000), '1,000');
    expect(CashbookCalculator.formatNumber(2500.5), '2,500.50');
    expect(CashbookCalculator.formatNumber(1.239), '1.24');
    expect(CashbookCalculator.formatNumber(99999999999), '99,999,999,999');
    expect(CashbookCalculator.formatNumber(1234, fixed2: true), '1,234.00');
    expect(CashbookCalculator.formatMoney(2500.5), 'Rs. 2,500.50');
    expect(CashbookCalculator.formatNumber(1234, group: false), '1234');
    expect(CashbookCalculator.formatNumber(1234.5, group: false), '1234.50');
    expect(CashbookCalculator.formatMoney(-1234, fixed2: true, group: false),
        '-Rs. 1234.00');
  });
}
