import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/cashbook_provider.dart';
import '../utils/cashbook_calculator.dart';

/// Everything an Account Ledger report needs. Rows are oldest first and carry
/// their running balance.
class CashExportData {
  final String title;
  final String rangeLabel;
  final bool allBooks;
  final List<CashLedgerRow> rows;
  final Map<String, String> bookNames;
  final double previousBalance;
  final bool hasPreviousBalance;
  final String reporter;
  final DateTime generatedAt;

  const CashExportData({
    required this.title,
    required this.rangeLabel,
    required this.allBooks,
    required this.rows,
    this.bookNames = const {},
    this.previousBalance = 0,
    this.hasPreviousBalance = false,
    this.reporter = '',
    required this.generatedAt,
  });

  CashTotals get totals => CashbookCalculator.totals(rows.map((r) => r.entry));
}

/// PDF and CSV builders for the Account Ledger (PARITY-069..074).
class CashbookExportService {
  CashbookExportService._();

  static final DateFormat _fileDate = DateFormat('MMM-dd-yyyy');

  /// "<Book> Oct-12-2026.pdf" for one book, "cashbook Oct-12-2026.pdf" for all.
  static String fileName(CashExportData data, String ext) {
    final base = data.allBooks ? 'cashbook' : data.title;
    final safe = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safe.isEmpty ? 'cashbook' : safe} ${_fileDate.format(data.generatedAt)}.$ext';
  }

  // ---- CSV ----

  static const List<String> _singleHeaders = [
    'Date',
    'Time',
    'Notes',
    'Description',
    'Income',
    'Expense',
    'Balance',
  ];
  static const List<String> _allHeaders = [
    'Date',
    'Time',
    'Account',
    'Notes',
    'Description',
    'Income',
    'Expense',
  ];

  static String _plain(double v) =>
      CashbookCalculator.roundMoney(v).toStringAsFixed(2);

  /// UTF-8 text with a byte order mark so spreadsheet apps open it correctly.
  static List<int> buildCsvBytes(CashExportData data) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm');
    final rows = <List<dynamic>>[
      data.allBooks ? _allHeaders : _singleHeaders,
    ];
    if (!data.allBooks && data.hasPreviousBalance) {
      rows.add([
        '',
        '',
        'Previous Balance',
        '',
        '',
        '',
        _plain(data.previousBalance)
      ]);
    }
    for (final r in data.rows) {
      final e = r.entry;
      final inAmt = e.isCashIn ? _plain(e.amount) : '';
      final outAmt = e.isCashIn ? '' : _plain(e.amount);
      if (data.allBooks) {
        rows.add([
          dateFmt.format(e.date),
          timeFmt.format(e.date),
          data.bookNames[e.bookId] ?? '',
          e.notes,
          e.description ?? '',
          inAmt,
          outAmt,
        ]);
      } else {
        rows.add([
          dateFmt.format(e.date),
          timeFmt.format(e.date),
          e.notes,
          e.description ?? '',
          inAmt,
          outAmt,
          _plain(r.balance),
        ]);
      }
    }
    final t = data.totals;
    if (data.allBooks) {
      rows.add(['', '', '', 'Total', '', _plain(t.cashIn), _plain(t.cashOut)]);
    } else {
      rows.add([
        '',
        '',
        'Total',
        '',
        _plain(t.cashIn),
        _plain(t.cashOut),
        _plain(t.balance)
      ]);
    }
    final text = const ListToCsvConverter().convert(rows);
    return [0xEF, 0xBB, 0xBF, ...utf8.encode(text)];
  }

  // ---- PDF ----

  /// Loads the bundled fonts (Noto Sans + Noto Sans Tamil) so notes in Tamil
  /// render correctly. Falls back to the built-in font if loading fails.
  static Future<(pw.Font, List<pw.Font>)> loadFonts() async {
    try {
      final base = pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
      final tamil = pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf'));
      return (base, [tamil]);
    } catch (_) {
      return (pw.Font.helvetica(), <pw.Font>[]);
    }
  }

  static Future<Uint8List> buildPdf(
    CashExportData data,
    CashSettings settings, {
    pw.Font? baseFont,
    List<pw.Font> fallbackFonts = const [],
  }) async {
    final theme = pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: baseFont ?? pw.Font.helvetica(),
      fontFallback: fallbackFonts,
    );
    final doc = pw.Document(theme: theme);
    const green = PdfColor.fromInt(0xFF2E7D32);
    const red = PdfColor.fromInt(0xFFC62828);
    const inFill = PdfColor.fromInt(0xFFE0F2F1);
    const outFill = PdfColor.fromInt(0xFFFDECEC);

    String fmtDate(DateTime d) {
      final date = settings.formatDate(d);
      return settings.showTimeInReports
          ? '$date\n${settings.formatTime(d)}'
          : date;
    }

    final headers = data.allBooks
        ? [
            '#',
            'Date',
            'Notes',
            CashLabels.income,
            CashLabels.expense,
            'Accounts'
          ]
        : [
            '#',
            'Date',
            'Notes',
            CashLabels.income,
            CashLabels.expense,
            'Balance'
          ];

    final body = <List<String>>[];
    var n = 0;
    if (!data.allBooks && data.hasPreviousBalance) {
      body.add([
        '',
        '',
        'Previous Balance',
        '',
        '',
        settings.formatNumber(data.previousBalance)
      ]);
    }
    for (final r in data.rows) {
      final e = r.entry;
      n++;
      final notes = [
        e.notes,
        if ((e.description ?? '').isNotEmpty) e.description!
      ].where((s) => s.isNotEmpty).join('\n');
      body.add([
        '$n',
        fmtDate(e.date),
        notes,
        e.isCashIn ? settings.formatNumber(e.amount) : '',
        e.isCashIn ? '' : settings.formatNumber(e.amount),
        data.allBooks
            ? (data.bookNames[e.bookId] ?? '')
            : settings.formatNumber(r.balance),
      ]);
    }

    final t = data.totals;
    pw.Widget summaryRow(String label, double v, PdfColor color) => pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Text(label, style: pw.TextStyle(color: color)),
              ),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Text(settings.formatNumber(v)),
              ),
            ),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('${data.title}  |  page ${ctx.pageNumber}',
                    style: const pw.TextStyle(fontSize: 8))),
        build: (ctx) => [
          if (data.allBooks)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(_fileDate.format(data.generatedAt),
                  style: const pw.TextStyle(fontSize: 9)),
            ),
          pw.Center(
            child: pw.Text(data.allBooks ? 'Account Ledger' : data.title,
                style: const pw.TextStyle(fontSize: 18)),
          ),
          if (data.reporter.isNotEmpty)
            pw.Center(
                child: pw.Text(data.reporter,
                    style: const pw.TextStyle(fontSize: 9))),
          pw.SizedBox(height: 4),
          pw.Center(
              child: pw.Text(data.rangeLabel,
                  style: const pw.TextStyle(fontSize: 10))),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: body,
            headerStyle: const pw.TextStyle(fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.topCenter,
              1: pw.Alignment.topCenter,
              2: pw.Alignment.topLeft,
              3: pw.Alignment.topRight,
              4: pw.Alignment.topRight,
              5: data.allBooks ? pw.Alignment.topLeft : pw.Alignment.topRight,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(62),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.6),
            },
            border: pw.TableBorder.all(width: 0.5),
            cellDecoration: (index, _, __) => pw.BoxDecoration(
              color: index == 3 ? inFill : (index == 4 ? outFill : null),
            ),
            headerDecoration: const pw.BoxDecoration(),
          ),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.SizedBox(
              width: 260,
              child: pw.Column(children: [
                summaryRow('Total ${CashLabels.income}', t.cashIn, green),
                summaryRow('Total ${CashLabels.expense}', t.cashOut, red),
                summaryRow(CashLabels.balance, t.balance, PdfColors.black),
              ]),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
