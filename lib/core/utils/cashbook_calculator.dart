import 'package:intl/intl.dart';
import '../models/cash_entry.dart';

/// Period tabs of the Account Ledger.
enum CashPeriod { all, daily, weekly, monthly, yearly }

/// Half-open date range: [start, end).
class CashDateRange {
  final DateTime start;
  final DateTime end;
  const CashDateRange(this.start, this.end);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// Last day shown to the user (inclusive).
  DateTime get lastDay => end.subtract(const Duration(days: 1));
}

/// In, out and net totals of a set of entries.
class CashTotals {
  final double cashIn;
  final double cashOut;
  const CashTotals(this.cashIn, this.cashOut);

  double get balance => CashbookCalculator.roundMoney(cashIn - cashOut);
}

/// One list row: an entry and the running balance after it.
class CashLedgerRow {
  final CashEntry entry;
  final double balance;
  const CashLedgerRow(this.entry, this.balance);
}

/// Rows of one calendar day.
class CashDayGroup {
  final DateTime day;
  final List<CashLedgerRow> rows;
  const CashDayGroup(this.day, this.rows);
}

/// Pure calculation helpers for the Account Ledger. No Hive or Riverpod here.
class CashbookCalculator {
  CashbookCalculator._();

  // ---- money ----

  /// Rounds to 2 decimals (1.239 -> 1.24).
  static double roundMoney(double v) => (v * 100).round() / 100;

  static int toPaise(double v) => (v * 100).round();

  /// Sums in integer paise so long lists do not drift.
  static double sumMoney(Iterable<double> values) {
    var paise = 0;
    for (final v in values) {
      paise += toPaise(v);
    }
    return paise / 100;
  }

  // ---- totals ----

  static CashTotals totals(Iterable<CashEntry> entries) {
    var inPaise = 0;
    var outPaise = 0;
    for (final e in entries) {
      if (e.isDeleted) continue;
      if (e.isCashIn) {
        inPaise += toPaise(e.amount);
      } else {
        outPaise += toPaise(e.amount);
      }
    }
    return CashTotals(inPaise / 100, outPaise / 100);
  }

  /// Net of all non-deleted entries dated before [before].
  static double previousBalance(Iterable<CashEntry> entries, DateTime before) {
    return totals(entries.where((e) => e.date.isBefore(before))).balance;
  }

  // ---- ordering and running balance ----

  /// Chronological order: date, then createdAt, then id.
  static int compareChronological(CashEntry a, CashEntry b) {
    final d = a.date.compareTo(b.date);
    if (d != 0) return d;
    final c = a.createdAt.compareTo(b.createdAt);
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  }

  /// Builds list rows. The running balance starts at [openingBalance]
  /// (the previous balance of a period tab, 0 for All) and accumulates over
  /// the given entries only, so searches and filters show their own running
  /// balance. Trashed entries are ignored. Result is newest first unless
  /// [ascending].
  static List<CashLedgerRow> buildRows(
    Iterable<CashEntry> entries, {
    double openingBalance = 0,
    bool ascending = false,
  }) {
    final sorted = entries.where((e) => !e.isDeleted).toList()
      ..sort(compareChronological);
    var paise = toPaise(openingBalance);
    final rows = <CashLedgerRow>[];
    for (final e in sorted) {
      paise += toPaise(e.signedAmount);
      rows.add(CashLedgerRow(e, paise / 100));
    }
    return ascending ? rows : rows.reversed.toList();
  }

  /// Groups rows by calendar day keeping the row order.
  static List<CashDayGroup> groupByDay(List<CashLedgerRow> rows) {
    final groups = <CashDayGroup>[];
    for (final row in rows) {
      final d = row.entry.date;
      final day = DateTime(d.year, d.month, d.day);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.rows.add(row);
      } else {
        groups.add(CashDayGroup(day, [row]));
      }
    }
    return groups;
  }

  /// Per-day totals, oldest day first.
  static Map<DateTime, CashTotals> totalsByDay(Iterable<CashEntry> entries) {
    final byDay = <DateTime, List<CashEntry>>{};
    for (final e in entries) {
      if (e.isDeleted) continue;
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort();
    return {for (final d in days) d: totals(byDay[d]!)};
  }

  // ---- periods ----

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Range of [period] containing [anchor]. Weeks start on Sunday.
  /// Returns null for [CashPeriod.all].
  static CashDateRange? periodRange(CashPeriod period, DateTime anchor) {
    final day = dateOnly(anchor);
    switch (period) {
      case CashPeriod.all:
        return null;
      case CashPeriod.daily:
        return CashDateRange(day, DateTime(day.year, day.month, day.day + 1));
      case CashPeriod.weekly:
        final start =
            DateTime(day.year, day.month, day.day - (day.weekday % 7));
        return CashDateRange(
            start, DateTime(start.year, start.month, start.day + 7));
      case CashPeriod.monthly:
        return CashDateRange(
            DateTime(day.year, day.month), DateTime(day.year, day.month + 1));
      case CashPeriod.yearly:
        return CashDateRange(DateTime(day.year), DateTime(day.year + 1));
    }
  }

  /// Moves the anchor by [delta] periods (previous/next arrows).
  static DateTime shiftAnchor(CashPeriod period, DateTime anchor, int delta) {
    switch (period) {
      case CashPeriod.all:
        return anchor;
      case CashPeriod.daily:
        return DateTime(anchor.year, anchor.month, anchor.day + delta);
      case CashPeriod.weekly:
        return DateTime(anchor.year, anchor.month, anchor.day + 7 * delta);
      case CashPeriod.monthly:
        // Clamp the day so Jan 31 + 1 month stays inside February.
        final first = DateTime(anchor.year, anchor.month + delta);
        final last = DateTime(first.year, first.month + 1, 0).day;
        return DateTime(first.year, first.month, anchor.day.clamp(1, last));
      case CashPeriod.yearly:
        return DateTime(anchor.year + delta, anchor.month, anchor.day);
    }
  }

  static final DateFormat _labelFormat = DateFormat('MMM-dd-yyyy');

  /// "Oct-01-2026 -> Oct-31-2026"
  static String rangeLabel(CashDateRange range) =>
      '${_labelFormat.format(range.start)} -> '
      '${_labelFormat.format(range.lastDay)}';

  // ---- formatting ----

  /// Grouped number, decimals only when present unless [fixed2].
  /// Negative values get a leading minus.
  static String formatNumber(double v, {bool fixed2 = false}) {
    final r = roundMoney(v);
    final hasFraction = toPaise(r) % 100 != 0;
    final f = (fixed2 || hasFraction)
        ? NumberFormat('#,##0.00', 'en_US')
        : NumberFormat('#,##0', 'en_US');
    return f.format(r);
  }

  /// "Rs. 1,000", "-Rs. 800", "Rs. 2,500.50".
  static String formatMoney(double v, {bool fixed2 = false}) {
    final r = roundMoney(v);
    final body = formatNumber(r.abs(), fixed2: fixed2);
    return r < 0 ? '-Rs. $body' : 'Rs. $body';
  }
}
