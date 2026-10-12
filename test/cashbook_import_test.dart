import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/services/cashbook_import_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds a synthetic file with the reference app's schema. [oldOrder] uses
/// the column order of an upgraded database (isDeleted after accounts).
int _n = 0;

String makeDb(Directory dir, {bool oldOrder = true, bool broken = false}) {
  final path =
      '${dir.path}/${oldOrder ? 'old' : 'new'}${broken ? '_broken' : ''}_${_n++}.db';
  final db = sqlite3.open(path);
  if (broken) {
    db.execute('create table other(a)');
    db.close();
    return path;
  }
  db.execute(
      'create table accounts (_id integer primary key autoincrement not null, name text not null)');
  db.execute(oldOrder
      ? 'create table cashTransaction (id integer primary key autoincrement not null, date integer not null, cash_out real not null, cash_in real not null, balance real not null, notes text, description text, bill text, accounts text, isDeleted integer default 0 not null, deletedDate integer default 0 not null, bill2 text, bill3 text, transactionType integer not null default 2)'
      : 'create table cashTransaction (id integer primary key autoincrement not null, date integer not null, cash_out real not null, cash_in real not null, balance real not null, notes text, description text, bill text, bill2 text, bill3 text, accounts text, isDeleted integer not null, deletedDate integer not null, transactionType integer not null default 2)');
  db.execute(
      'create table notebook (id integer primary key autoincrement not null, date integer not null, note text, completed text)');
  db.execute(
      "insert into accounts(name) values ('Cash Book'), ('Site A'), ('Empty book')");
  final t0 = DateTime(2026, 3, 1, 10).millisecondsSinceEpoch;
  void tx(int id, int ms, double inn, double out, String notes, String book,
      {int deleted = 0, int type = 0}) {
    final t = type != 0 ? type : (inn > 0 ? 1 : 2);
    db.execute(
        'insert into cashTransaction(id,date,cash_out,cash_in,balance,notes,accounts,isDeleted,deletedDate,transactionType) values (?,?,?,?,0,?,?,?,?,?)',
        [id, ms, out, inn, notes, book, deleted, deleted == 1 ? ms : 0, t]);
  }

  tx(1, t0, 1000, 0, 'Opening', 'Site A');
  tx(2, t0 + 60000, 0, 400.5, 'Diesel', 'Site A');
  tx(3, t0 + 120000, 250, 0, 'Cash entry', 'Cash Book');
  tx(4, t0 + 180000, 0, 99, 'Trashed', 'Site A', deleted: 1);
  tx(5, t0 + 240000, 70, 0, 'Book not in accounts table', 'Ghost');
  db.execute(
      "insert into notebook(date,note,completed) values ($t0,'Call supplier','true'), ($t0,'Pay rent','false'), ($t0,'','true')");
  db.close();
  return path;
}

void main() {
  late Directory dir;
  late Directory data;

  setUpAll(() async {
    data = Directory.systemTemp.createTempSync('import_hive');
    dir = Directory.systemTemp.createTempSync('import_src');
    Hive.init(data.path);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.clearAllData();
  });

  tearDownAll(() async {
    await Hive.close();
    data.deleteSync(recursive: true);
    dir.deleteSync(recursive: true);
  });

  test('preview (dry run) reports counts and writes nothing', () {
    final p = CashbookImportService.preview(makeDb(dir));
    expect(p.activeEntries, 4);
    expect(p.trashedEntries, 1);
    expect(p.bookNames,
        containsAll(['Cash Book', 'Site A', 'Empty book', 'Ghost']));
    expect(p.entriesPerBook['Site A'], 2);
    expect(p.totalIn, 1320);
    expect(p.totalOut, 400.5);
    expect(p.notes, 3);
    expect(p.firstDate, DateTime(2026, 3, 1, 10));
    expect(DatabaseService.cashEntryBox.isEmpty, isTrue);
    expect(DatabaseService.getAllCashBooks().length, 1); // default only
  });

  test('import maps books, entries, trash and notes', () async {
    final r = await CashbookImportService.run(makeDb(dir));
    expect(r.entriesImported, 4);
    expect(r.trashedImported, 1);
    expect(r.booksMerged, 1); // default "Cash Book"
    expect(r.booksCreated, 3); // Site A, Empty book, Ghost
    expect(r.notesImported, 2); // empty note skipped

    final books = {
      for (final b in DatabaseService.getAllCashBooks()) b.name: b.id
    };
    final site = DatabaseService.getCashEntries(bookId: books['Site A']);
    expect(site.length, 2);
    final income = site.firstWhere((e) => e.notes == 'Opening');
    expect(income.isCashIn, isTrue);
    expect(income.amount, 1000);
    expect(income.date, DateTime(2026, 3, 1, 10));
    expect(income.importedLegacyId, 1);
    expect(site.firstWhere((e) => e.notes == 'Diesel').amount, 400.5);

    final trash = DatabaseService.getCashTrash();
    expect(trash.single.notes, 'Trashed');
    expect(trash.single.bookNameSnapshot, 'Site A');
    expect(
        trash.single.deletedAt!
            .isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
        isTrue);

    final notes = DatabaseService.getAllCashNotes();
    expect(
        notes.firstWhere((n) => n.text == 'Call supplier').isCompleted, isTrue);
    expect(notes.firstWhere((n) => n.text == 'Pay rent').isCompleted, isFalse);
  });

  test('running the import again skips what was imported', () async {
    final path = makeDb(dir);
    await CashbookImportService.run(path);
    final again = await CashbookImportService.run(path, includeNotes: false);
    expect(again.entriesImported, 0);
    expect(again.trashedImported, 0);
    expect(again.entriesSkipped, 5);
    expect(DatabaseService.cashEntryBox.length, 5);
    expect(CashbookImportService.preview(path).alreadyImported, 5);
  });

  test('both column orders import identically', () async {
    final r = await CashbookImportService.run(makeDb(dir, oldOrder: false));
    expect(r.entriesImported, 4);
    expect(r.trashedImported, 1);
  });

  test('unrelated or missing files give clear errors', () {
    expect(() => CashbookImportService.preview(makeDb(dir, broken: true)),
        throwsA(isA<CashImportException>()));
    expect(() => CashbookImportService.preview('${dir.path}/nope.db'),
        throwsA(isA<CashImportException>()));
    final txt = File('${dir.path}/not_a_db.db')
      ..writeAsStringSync('hello world, not sqlite');
    expect(() => CashbookImportService.preview(txt.path), throwsA(anything));
  });

  test('the source file is never modified', () async {
    final path = makeDb(dir);
    final before = File(path).readAsBytesSync();
    await CashbookImportService.run(path);
    expect(File(path).readAsBytesSync(), before);
  });
}
