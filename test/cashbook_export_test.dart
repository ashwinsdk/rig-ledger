import 'dart:convert';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/models/cash_entry.dart';
import 'package:rig_ledger/core/providers/cashbook_provider.dart';
import 'package:rig_ledger/core/services/cashbook_export_service.dart';
import 'package:rig_ledger/core/utils/cashbook_calculator.dart';

CashEntry e(String id, DateTime d, double a, bool isIn, String notes,
    {String book = 'b1'}) {
  return CashEntry(
    id: id,
    bookId: book,
    date: d,
    amount: a,
    isCashIn: isIn,
    notes: notes,
    createdAt: d,
    updatedAt: d,
  );
}

CashExportData data({bool all = false}) {
  final rows = CashbookCalculator.buildRows([
    e('1', DateTime(2026, 10, 12, 15, 30), 1000, true, 'Opening Balance'),
    e('2', DateTime(2026, 10, 12, 15, 32), 400.5, false,
        'Diesel, "top up"\nline 2'),
    e('3', DateTime(2026, 10, 13, 9, 0), 50, true, 'Other', book: 'b2'),
  ], ascending: true);
  return CashExportData(
    title: 'Site/Book: 1',
    rangeLabel: 'All',
    allBooks: all,
    rows: rows,
    bookNames: const {'b1': 'Site', 'b2': 'Other'},
    generatedAt: DateTime(2026, 10, 12),
  );
}

void main() {
  test('file names follow the reference pattern and are sanitized', () {
    expect(CashbookExportService.fileName(data(), 'pdf'),
        'Site_Book_ 1 Oct-12-2026.pdf');
    expect(CashbookExportService.fileName(data(all: true), 'csv'),
        'cashbook Oct-12-2026.csv');
  });

  test('single book CSV: BOM, header, quoting, running balance, totals', () {
    final bytes = CashbookExportService.buildCsvBytes(data());
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.skip(3).toList());
    final lines = const LineSplitter().convert(text);
    expect(
        lines.first, 'Date,Time,Notes,Description,Income,Expense,Balance,Rig');
    expect(text, contains('"Diesel, ""top up""\nline 2"'));
    expect(
        text, contains('2026-10-12,15:30,Opening Balance,,1000.00,,1000.00'));
    expect(text, contains('599.50'));
    expect(text.trim().split('\r\n').last, ',,Total,,1050.00,400.50,649.50,');
  });

  test('all books CSV has an Account column and no balance', () {
    final text = utf8.decode(
        CashbookExportService.buildCsvBytes(data(all: true)).skip(3).toList());
    expect(text.split('\r\n').first,
        'Date,Time,Account,Notes,Description,Income,Expense,Rig');
    expect(text, contains('2026-10-13,09:00,Other,Other,,50.00,'));
  });

  test('CSV has a Rig column with the rig name when the entry has one', () {
    final base = data(all: false);
    final rows = [
      for (final r in base.rows)
        CashLedgerRow(r.entry..vehicleId = 'rig1', r.balance),
    ];
    final d = CashExportData(
      title: base.title,
      rangeLabel: base.rangeLabel,
      allBooks: false,
      rows: rows,
      rigNames: const {'rig1': 'Main Rig'},
      generatedAt: base.generatedAt,
    );
    final text =
        utf8.decode(CashbookExportService.buildCsvBytes(d).skip(3).toList());
    expect(text, contains('1000.00,,1000.00,Main Rig'));
  });

  test('CSV with previous balance row', () {
    final d = CashExportData(
      title: 'B',
      rangeLabel: 'x',
      allBooks: false,
      rows: const [],
      previousBalance: 20,
      hasPreviousBalance: true,
      generatedAt: DateTime(2026),
    );
    final text =
        utf8.decode(CashbookExportService.buildCsvBytes(d).skip(3).toList());
    expect(text, contains(',,Previous Balance,,,,20.00,'));
  });

  test('PDF builds for both layouts', () async {
    const settings = CashSettings();
    for (final all in [false, true]) {
      final bytes =
          await CashbookExportService.buildPdf(data(all: all), settings);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    }
  });

  test('PDF renders Tamil notes with the bundled fonts', () async {
    pw.Font load(String name) => pw.Font.ttf(
        File('assets/fonts/$name').readAsBytesSync().buffer.asByteData());
    final rows = CashbookCalculator.buildRows([
      e('1', DateTime(2026, 1, 1), 10, true, 'பாயின்ட் 01'),
    ], ascending: true);
    final d = CashExportData(
      title: 'Tamil',
      rangeLabel: 'All',
      allBooks: false,
      rows: rows,
      generatedAt: DateTime(2026, 1, 1),
    );
    final bytes = await CashbookExportService.buildPdf(
      d,
      const CashSettings(),
      baseFont: load('NotoSans-Regular.ttf'),
      fallbackFonts: [load('NotoSansTamil-Regular.ttf')],
    );
    expect(bytes.length, greaterThan(1000));
  });
}
