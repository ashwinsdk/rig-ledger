import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/providers/cashbook_provider.dart';
import 'package:rig_ledger/core/utils/cashbook_calculator.dart';

void main() {
  late Directory dir;
  late ProviderContainer c;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('cashbook_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.clearAllData();
    c = ProviderContainer();
    c.read(cashBooksProvider.notifier).refresh();
    c.read(cashEntriesProvider.notifier).refresh();
    c.read(cashViewConfigProvider.notifier).clearFilters();
  });

  tearDown(() => c.dispose());

  tearDownAll(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  String defaultBookId() => c.read(cashBooksProvider).first.id;

  test('default book exists (PARITY-001)', () {
    final books = c.read(cashBooksProvider);
    expect(books.length, 1);
    expect(books.first.name, 'Cash Book');
  });

  test('addBook: empty name creates nothing, opening balance entry', () async {
    final n = c.read(cashBooksProvider.notifier);
    final (b0, e0) = await n.addBook(name: '  ');
    expect(b0, isNull);
    expect(e0, isNotNull);
    final (book, err) = await n.addBook(
        name: 'Site', openingBalance: 1000, openingIsPositive: false);
    expect(err, isNull);
    final entries =
        c.read(cashEntriesProvider).where((e) => e.bookId == book!.id).toList();
    expect(entries.length, 1);
    expect(entries.first.notes, cashOpeningBalanceNotes);
    expect(entries.first.isCashIn, isFalse);
    expect(entries.first.amount, 1000);
    // Duplicate names (case-insensitive) are refused.
    final (dup, derr) = await n.addBook(name: 'site');
    expect(dup, isNull);
    expect(derr, isNotNull);
  });

  test('addEntry rounds and rejects negatives', () async {
    final n = c.read(cashEntriesProvider.notifier);
    final id = defaultBookId();
    final (e, err) = await n.addEntry(
        bookId: id, date: DateTime(2026, 1, 1), amount: 1.239, isCashIn: true);
    expect(err, isNull);
    expect(e!.amount, 1.24);
    final (neg, nerr) = await n.addEntry(
        bookId: id, date: DateTime(2026, 1, 1), amount: -5, isCashIn: true);
    expect(neg, isNull);
    expect(nerr, isNotNull);
    final (zero, zerr) = await n.addEntry(
        bookId: id, date: DateTime(2026, 1, 1), amount: 0, isCashIn: false);
    expect(zerr, isNull);
    expect(zero!.amount, 0);
  });

  test('trash, restore and purge', () async {
    final n = c.read(cashEntriesProvider.notifier);
    final id = defaultBookId();
    final (e, _) = await n.addEntry(
        bookId: id, date: DateTime(2026, 1, 1), amount: 400, isCashIn: false);
    await n.moveToTrash(e!.id);
    expect(c.read(cashTrashProvider).length, 1);
    expect(c.read(cashLedgerProvider).rows, isEmpty);
    await n.restore(e.id);
    expect(c.read(cashTrashProvider), isEmpty);
    expect(c.read(cashLedgerProvider).rows.length, 1);
    await n.moveToTrash(e.id);
    await n.purge(e.id);
    expect(c.read(cashEntriesProvider), isEmpty);
    expect(DatabaseService.isTombstoned(e.id), isTrue);
  });

  test('auto purge removes trash older than 30 days', () async {
    final n = c.read(cashEntriesProvider.notifier);
    final id = defaultBookId();
    final (e, _) = await n.addEntry(
        bookId: id, date: DateTime(2026, 1, 1), amount: 5, isCashIn: true);
    await n.moveToTrash(e!.id);
    final trashed = DatabaseService.getCashEntry(e.id)!;
    trashed.deletedAt = DateTime.now().subtract(const Duration(days: 31));
    await DatabaseService.saveCashEntry(trashed);
    await DatabaseService.purgeExpiredCashTrash();
    expect(DatabaseService.getCashEntry(e.id), isNull);
  });

  test('transfer creates two linked entries (PARITY-058)', () async {
    final books = c.read(cashBooksProvider.notifier);
    final (b2, _) = await books.addBook(name: 'Other');
    final from = defaultBookId();
    final (ok, err) = await c.read(cashEntriesProvider.notifier).transfer(
        fromBookId: from,
        toBookId: b2!.id,
        amount: 100,
        date: DateTime(2026, 1, 1),
        notes: 'transfer test');
    expect(ok, isTrue, reason: err);
    final all = c.read(cashEntriesProvider);
    final out = all.firstWhere((e) => e.bookId == from);
    final inn = all.firstWhere((e) => e.bookId == b2.id);
    expect(out.isCashIn, isFalse);
    expect(out.notes, 'To Other\ntransfer test');
    expect(inn.isCashIn, isTrue);
    expect(inn.notes, 'From Cash Book\ntransfer test');
    expect(out.transferGroupId, inn.transferGroupId);
    final (same, serr) = await c.read(cashEntriesProvider.notifier).transfer(
        fromBookId: from, toBookId: from, amount: 1, date: DateTime.now());
    expect(same, isFalse);
    expect(serr, isNotNull);
  });

  test('deleting a book trashes its entries with the book name', () async {
    final books = c.read(cashBooksProvider.notifier);
    final (b, _) = await books.addBook(name: 'Temp', openingBalance: 50);
    await books.deleteBook(b!.id);
    expect(c.read(cashBooksProvider).any((x) => x.id == b.id), isFalse);
    final trash = c.read(cashTrashProvider);
    expect(trash.length, 1);
    expect(trash.first.bookNameSnapshot, 'Temp');
    expect(DatabaseService.isTombstoned(b.id), isTrue);
    // Restore into another book.
    await c
        .read(cashEntriesProvider.notifier)
        .restore(trash.first.id, toBookId: defaultBookId());
    expect(c.read(cashEntriesProvider).first.bookId, defaultBookId());
    expect(c.read(cashEntriesProvider).first.bookNameSnapshot, isNull);
  });

  test('ledger view: period previous balance, search ignores period', () async {
    final n = c.read(cashEntriesProvider.notifier);
    final id = defaultBookId();
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 15, 10);
    await n.addEntry(
        bookId: id,
        date: lastMonth,
        amount: 20,
        isCashIn: true,
        notes: 'boundary');
    await n.addEntry(
        bookId: id, date: now, amount: 10, isCashIn: true, notes: 'future');
    await n.addEntry(
        bookId: id,
        date: now,
        amount: 400,
        isCashIn: false,
        notes: 'Test diesel');

    final cfg = c.read(cashViewConfigProvider.notifier);
    cfg.setPeriod(CashPeriod.monthly);
    var v = c.read(cashLedgerProvider);
    expect(v.hasPreviousBalance, isTrue);
    expect(v.previousBalance, 20);
    expect(v.rows.length, 2);
    expect(v.totals.cashIn, 10);
    expect(v.totals.cashOut, 400);
    expect(v.finalBalance, -370);
    // Running balance starts from the previous balance.
    expect(v.rows.last.balance, 30);

    // Search ignores the period and has no previous balance.
    cfg.setQuery('BOUNDARY');
    v = c.read(cashLedgerProvider);
    expect(v.hasPreviousBalance, isFalse);
    expect(v.rows.length, 1);
    expect(v.rows.first.entry.notes, 'boundary');
    cfg.setQuery('');

    // Type filter and sort.
    cfg.setPeriod(CashPeriod.all);
    cfg.setType(CashTypeFilter.expense);
    v = c.read(cashLedgerProvider);
    expect(v.rows.length, 1);
    expect(v.totals.cashIn, 0);
    cfg.setType(CashTypeFilter.all);
    cfg.setAscending(true);
    v = c.read(cashLedgerProvider);
    expect(v.rows.first.entry.notes, 'boundary');
  });

  test('setOpeningBalance edits in place', () async {
    final books = c.read(cashBooksProvider.notifier);
    final (b, _) = await books.addBook(name: 'Op', openingBalance: 1000);
    final (ok, _) = await books.setOpeningBalance(
        bookId: b!.id, amount: 1000, isPositive: false, date: DateTime.now());
    expect(ok, isTrue);
    final mine = c.read(cashEntriesProvider).where((e) => e.bookId == b.id);
    expect(mine.length, 1);
    expect(mine.first.isCashIn, isFalse);
  });

  test('backup round trip keeps cash data and tolerates old backups', () async {
    final books = c.read(cashBooksProvider.notifier);
    final (b, _) = await books.addBook(name: 'Round', openingBalance: 75);
    await c
        .read(cashNotesProvider.notifier)
        .addNote(date: DateTime(2026, 1, 1), text: 'remember');
    final backup = await DatabaseService.createBackup();
    expect(backup['version'], DatabaseService.schemaVersion);
    await DatabaseService.restoreBackup(backup);
    expect(DatabaseService.getCashBook(b!.id)?.name, 'Round');
    expect(DatabaseService.getCashEntries(bookId: b.id).length, 1);
    expect(DatabaseService.getAllCashNotes().length, 1);

    // Backup from an older app version has no cash keys.
    final old = Map<String, dynamic>.from(backup)
      ..remove('cashBooks')
      ..remove('cashEntries')
      ..remove('cashNotes');
    await DatabaseService.restoreBackup(old);
    expect(DatabaseService.getAllCashBooks().length, 1); // default book
    expect(DatabaseService.getAllCashBooks().first.name, 'Cash Book');
  });

  test('summaries per book and per day', () async {
    final books = c.read(cashBooksProvider.notifier);
    final (b2, _) = await books.addBook(name: 'Second');
    final n = c.read(cashEntriesProvider.notifier);
    final id = defaultBookId();
    final d = DateTime(2026, 3, 10, 9);
    await n.addEntry(bookId: id, date: d, amount: 100, isCashIn: true);
    await n.addEntry(bookId: b2!.id, date: d, amount: 30, isCashIn: false);
    final q = (
      bookId: null as String?,
      period: CashPeriod.monthly,
      anchor: d,
      custom: null as CashDateRange?
    );
    final s = c.read(cashSummaryProvider(q));
    expect(s.books.length, 2);
    expect(s.grand.balance, 70);
    final days = c.read(cashDaySummaryProvider(q));
    expect(days.length, 1);
    expect(days.values.first.cashIn, 100);
  });
}
