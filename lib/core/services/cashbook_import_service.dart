import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/cash_book.dart';
import '../models/cash_entry.dart';
import '../models/cash_note.dart';

const _uuid = Uuid();

/// What an import would do (dry run result). Nothing is written.
class CashImportPreview {
  final List<String> bookNames; // books found in the file
  final Map<String, int> entriesPerBook; // active entries per book name
  final int activeEntries;
  final int trashedEntries;
  final int alreadyImported; // entries already present (re-run)
  final int notes;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final double totalIn;
  final double totalOut;
  final List<String> warnings;

  const CashImportPreview({
    required this.bookNames,
    required this.entriesPerBook,
    required this.activeEntries,
    required this.trashedEntries,
    required this.alreadyImported,
    required this.notes,
    required this.firstDate,
    required this.lastDate,
    required this.totalIn,
    required this.totalOut,
    required this.warnings,
  });

  int get totalEntries => activeEntries + trashedEntries;
}

class CashImportResult {
  final int booksCreated;
  final int booksMerged;
  final int entriesImported;
  final int entriesSkipped; // already imported earlier
  final int trashedImported;
  final int notesImported;
  final int attachmentsDropped;

  const CashImportResult({
    required this.booksCreated,
    required this.booksMerged,
    required this.entriesImported,
    required this.entriesSkipped,
    required this.trashedImported,
    required this.notesImported,
    required this.attachmentsDropped,
  });
}

class CashImportException implements Exception {
  final String message;
  CashImportException(this.message);
  @override
  String toString() => message;
}

/// One-time import of a backup .db written by the reference cashbook app
/// (tables accounts, cashTransaction, notebook). Columns are read by name so
/// both the old and the new column order work. The source file is opened
/// read-only and never modified.
///
/// Mapping (docs/features/cashbook/SPEC.md section 6):
///   accounts.name                  -> CashBook (merged by name, case-insensitive)
///   cashTransaction.accounts       -> book by name
///   cashTransaction.id             -> importedLegacyId (re-running skips it)
///   date (epoch ms)                -> local DateTime
///   transactionType / cash_in/out  -> isCashIn + amount
///   balance                        -> ignored (always 0 in the reference app)
///   notes, description             -> notes, description
///   bill, bill2, bill3             -> attachmentPaths when the file exists
///   isDeleted, deletedDate         -> trash; deletedAt = import time so the
///                                     30 day window starts at the import
///   notebook                       -> CashNote
class CashbookImportService {
  CashbookImportService._();

  static Database _open(String path) {
    if (!File(path).existsSync()) {
      throw CashImportException('File not found');
    }
    try {
      return sqlite3.open(path, mode: OpenMode.readOnly);
    } catch (e) {
      throw CashImportException('This file is not a readable database');
    }
  }

  static bool _hasTable(Database db, String name) => db.select(
      "select 1 from sqlite_master where type='table' and name=?",
      [name]).isNotEmpty;

  static Set<String> _columns(Database db, String table) => db
      .select('pragma table_info("$table")')
      .map((r) => r['name'] as String)
      .toSet();

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

  static bool _truthy(Object? v) {
    if (v == null) return false;
    final s = v.toString().trim().toLowerCase();
    return s == '1' ||
        s == 'true' ||
        s == 'yes' ||
        s == 'completed' ||
        s == 'done';
  }

  static void _validate(Database db) {
    if (!_hasTable(db, 'cashTransaction')) {
      throw CashImportException(
          'No cashTransaction table found. Choose a backup made by the cashbook app.');
    }
    final cols = _columns(db, 'cashTransaction');
    const required = {'id', 'date', 'cash_in', 'cash_out', 'accounts'};
    final missing = required.difference(cols);
    if (missing.isNotEmpty) {
      throw CashImportException(
          'Unsupported database: missing columns ${missing.join(', ')}');
    }
  }

  /// Dry run: reads the file and reports what would be imported.
  static CashImportPreview preview(String path) {
    final db = _open(path);
    try {
      _validate(db);
      final cols = _columns(db, 'cashTransaction');
      final hasDeleted = cols.contains('isDeleted');
      final hasType = cols.contains('transactionType');
      final warnings = <String>[];

      final names = <String>{};
      if (_hasTable(db, 'accounts')) {
        for (final r in db.select('select name from accounts')) {
          final n = (r['name'] as String?)?.trim() ?? '';
          if (n.isNotEmpty) names.add(n);
        }
      }
      final perBook = <String, int>{};
      var active = 0, trashed = 0, already = 0;
      double totalIn = 0, totalOut = 0;
      int? minMs, maxMs;

      final existing = _existingLegacyKeys();
      final rows = db.select(
          'select id, date, cash_in, cash_out, accounts${hasDeleted ? ', isDeleted' : ''}${hasType ? ', transactionType' : ''} from cashTransaction');
      for (final r in rows) {
        final book = ((r['accounts'] as String?) ?? '').trim();
        final bookName = book.isEmpty ? 'Cash Book' : book;
        names.add(bookName);
        final isDel = hasDeleted && (r['isDeleted'] as num?) == 1;
        final legacyId = (r['id'] as num).toInt();
        if (existing.contains('${bookName.toLowerCase()}|$legacyId')) already++;
        if (isDel) {
          trashed++;
          continue;
        }
        active++;
        perBook[bookName] = (perBook[bookName] ?? 0) + 1;
        totalIn += _num(r['cash_in']);
        totalOut += _num(r['cash_out']);
        final ms = (r['date'] as num?)?.toInt();
        if (ms != null) {
          minMs = (minMs == null || ms < minMs) ? ms : minMs;
          maxMs = (maxMs == null || ms > maxMs) ? ms : maxMs;
        }
      }
      var notes = 0;
      if (_hasTable(db, 'notebook')) {
        notes = db.select('select count(*) c from notebook').first['c'] as int;
      }
      if (!hasDeleted) warnings.add('No trash information in this file');
      return CashImportPreview(
        bookNames: names.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
        entriesPerBook: perBook,
        activeEntries: active,
        trashedEntries: trashed,
        alreadyImported: already,
        notes: notes,
        firstDate:
            minMs == null ? null : DateTime.fromMillisecondsSinceEpoch(minMs),
        lastDate:
            maxMs == null ? null : DateTime.fromMillisecondsSinceEpoch(maxMs),
        totalIn: totalIn,
        totalOut: totalOut,
        warnings: warnings,
      );
    } finally {
      db.close();
    }
  }

  /// Keys "bookname|legacyId" of entries imported earlier.
  static Set<String> _existingLegacyKeys() {
    final books = {
      for (final b in DatabaseService.getAllCashBooks())
        b.id: b.name.toLowerCase()
    };
    final keys = <String>{};
    for (final e in DatabaseService.cashEntryBox.values) {
      final legacy = e.importedLegacyId;
      if (legacy == null) continue;
      final name = books[e.bookId] ?? e.bookNameSnapshot?.toLowerCase();
      if (name != null) keys.add('$name|$legacy');
    }
    return keys;
  }

  /// Imports the file. Safe to run again: rows already imported are skipped.
  static Future<CashImportResult> run(
    String path, {
    bool includeNotes = true,
    void Function(double progress)? onProgress,
  }) async {
    final db = _open(path);
    try {
      _validate(db);
      final cols = _columns(db, 'cashTransaction');
      bool has(String c) => cols.contains(c);
      final now = DateTime.now();

      // ---- books ----
      final names = <String>[];
      if (_hasTable(db, 'accounts')) {
        for (final r in db.select('select name from accounts order by _id')) {
          final n = (r['name'] as String?)?.trim() ?? '';
          if (n.isNotEmpty) names.add(n);
        }
      }
      final rows = db.select('select * from cashTransaction order by id');
      for (final r in rows) {
        final n = ((r['accounts'] as String?) ?? '').trim();
        final name = n.isEmpty ? 'Cash Book' : n;
        if (!names.any((x) => x.toLowerCase() == name.toLowerCase())) {
          names.add(name);
        }
      }

      final bookIdByName = <String, String>{};
      for (final b in DatabaseService.getAllCashBooks()) {
        bookIdByName[b.name.toLowerCase()] = b.id;
      }
      var created = 0, merged = 0;
      var order = DatabaseService.getAllCashBooks().length;
      for (final name in names) {
        final key = name.toLowerCase();
        if (bookIdByName.containsKey(key)) {
          merged++;
          continue;
        }
        final book = CashBook(
          id: _uuid.v4(),
          name: name,
          createdAt: now,
          updatedAt: now,
          sortOrder: order++,
        );
        await DatabaseService.saveCashBook(book);
        bookIdByName[key] = book.id;
        created++;
      }

      // ---- entries ----
      final existing = _existingLegacyKeys();
      var imported = 0, skipped = 0, trashedCount = 0, dropped = 0;
      final batch = <CashEntry>[];
      final total = rows.length;
      var done = 0;

      Future<void> flush() async {
        if (batch.isEmpty) return;
        await DatabaseService.saveCashEntries(List.of(batch));
        batch.clear();
      }

      for (final r in rows) {
        done++;
        final rawName = ((r['accounts'] as String?) ?? '').trim();
        final bookName = rawName.isEmpty ? 'Cash Book' : rawName;
        final legacyId = (r['id'] as num).toInt();
        if (existing.contains('${bookName.toLowerCase()}|$legacyId')) {
          skipped++;
          continue;
        }
        final cashIn = _num(r['cash_in']);
        final cashOut = _num(r['cash_out']);
        final type = has('transactionType')
            ? (r['transactionType'] as num?)?.toInt()
            : null;
        final isIn = type != null ? type == 1 : cashIn > 0;
        final amount = ((isIn ? cashIn : cashOut) * 100).round() / 100;
        final ms = (r['date'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
        final isDel = has('isDeleted') && (r['isDeleted'] as num?) == 1;

        final paths = <String>[];
        for (final c in const ['bill', 'bill2', 'bill3']) {
          if (!has(c)) continue;
          final p = (r[c] as String?)?.trim() ?? '';
          if (p.isEmpty) continue;
          if (File(p).existsSync()) {
            paths.add(p);
          } else {
            dropped++;
          }
        }
        final desc =
            has('description') ? (r['description'] as String?)?.trim() : null;

        batch.add(CashEntry(
          id: _uuid.v4(),
          bookId: bookIdByName[bookName.toLowerCase()]!,
          date: DateTime.fromMillisecondsSinceEpoch(ms),
          amount: amount,
          isCashIn: isIn,
          notes: (r['notes'] as String?) ?? '',
          description: (desc == null || desc.isEmpty) ? null : desc,
          attachmentPaths: paths.isEmpty ? null : paths,
          isDeleted: isDel,
          deletedAt: isDel ? now : null,
          bookNameSnapshot: isDel ? bookName : null,
          importedLegacyId: legacyId,
          createdAt: now,
          updatedAt: now,
        ));
        if (isDel) {
          trashedCount++;
        } else {
          imported++;
        }
        if (batch.length >= 500) {
          await flush();
          onProgress?.call(done / total);
        }
      }
      await flush();

      // ---- notebook ----
      var notesImported = 0;
      if (includeNotes && _hasTable(db, 'notebook')) {
        final nc = _columns(db, 'notebook');
        for (final r in db.select('select * from notebook order by id')) {
          final text =
              ((nc.contains('note') ? r['note'] : null) as String?)?.trim() ??
                  '';
          if (text.isEmpty) continue;
          final ms = (r['date'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
          await DatabaseService.saveCashNote(CashNote(
            id: _uuid.v4(),
            date: DateTime.fromMillisecondsSinceEpoch(ms),
            text: text,
            isCompleted:
                _truthy(nc.contains('completed') ? r['completed'] : null),
            createdAt: now,
            updatedAt: now,
          ));
          notesImported++;
        }
      }
      onProgress?.call(1);
      return CashImportResult(
        booksCreated: created,
        booksMerged: merged,
        entriesImported: imported,
        entriesSkipped: skipped,
        trashedImported: trashedCount,
        notesImported: notesImported,
        attachmentsDropped: dropped,
      );
    } finally {
      db.close();
    }
  }
}
