import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/services/cashbook_export_service.dart';
import '../../core/services/file_save_service.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'widgets/cashbook_common.dart';

enum _Format { pdf, csv }

/// "Report" dialog for the book on screen (PARITY-069, 070): honours the
/// active period, search and filters because [data] is built from them.
Future<void> showCashReportDialog(
    BuildContext context, WidgetRef ref, CashExportData data) async {
  final format = await showDialog<_Format>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Report'),
      children: [
        SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _Format.pdf),
            child: const Text('PDF')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _Format.csv),
            child: const Text('CSV')),
      ],
    ),
  );
  if (format == null || !context.mounted) return;
  await runCashExport(context, ref, data, format == _Format.pdf);
}

/// Builds and saves/shares a report file.
Future<void> runCashExport(
    BuildContext context, WidgetRef ref, CashExportData data, bool pdf) async {
  if (data.rows.isEmpty) {
    showCashSnack(context, 'Nothing to export', error: true);
    return;
  }
  try {
    final settings = ref.read(cashSettingsProvider);
    final Uint8List bytes;
    if (pdf) {
      final (base, fallback) = await CashbookExportService.loadFonts();
      bytes = await CashbookExportService.buildPdf(data, settings,
          baseFont: base, fallbackFonts: fallback);
    } else {
      bytes = Uint8List.fromList(CashbookExportService.buildCsvBytes(data));
    }
    if (!context.mounted) return;
    final saved = await FileSaveService.saveFile(
      context: context,
      bytes: bytes,
      fileName: CashbookExportService.fileName(data, pdf ? 'pdf' : 'csv'),
      shareSubject: 'RigLedger Account Ledger report',
      dialogTitle: 'Save report',
    );
    if (saved && context.mounted) showCashSnack(context, 'Report exported');
  } catch (e) {
    if (context.mounted) {
      showCashSnack(context, 'Failed to export: $e', error: true);
    }
  }
}

/// Report-All Accounts (PARITY-072): all books, period All or a date range,
/// PDF or CSV.
Future<void> showCashReportAllDialog(
    BuildContext context, WidgetRef ref) async {
  final settings = ref.read(cashSettingsProvider);
  CashDateRange? range;
  var pdf = true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Report - All Accounts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: range == null,
                  onSelected: (_) => setLocal(() => range = null),
                ),
                ChoiceChip(
                  label: Text(range == null
                      ? 'Select Date Range'
                      : CashbookCalculator.rangeLabel(range!)),
                  selected: range != null,
                  onSelected: (_) async {
                    final r = await pickCashDateRange(ctx, settings.formatDate);
                    if (r != null) setLocal(() => range = r);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('PDF')),
                ButtonSegment(value: false, label: Text('CSV')),
              ],
              selected: {pdf},
              onSelectionChanged: (s) => setLocal(() => pdf = s.first),
              showSelectedIcon: false,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final data = buildAllBooksExport(ref, range);
  await runCashExport(context, ref, data, pdf);
}

/// Export data for all books (oldest first, no per book balance).
CashExportData buildAllBooksExport(WidgetRef ref, CashDateRange? range) {
  final settings = ref.read(cashSettingsProvider);
  final books = ref.read(cashBooksProvider);
  final entries = ref
      .read(cashEntriesProvider)
      .where((e) => !e.isDeleted && (range == null || range.contains(e.date)))
      .toList();
  final rows = CashbookCalculator.buildRows(entries, ascending: true);
  return CashExportData(
    title: 'Account Ledger',
    rangeLabel: range == null
        ? 'All'
        : CashbookCalculator.rangeLabel(range).replaceAll(' -> ', ' To '),
    allBooks: true,
    rows: rows,
    bookNames: {for (final b in books) b.id: b.name},
    rigNames: {for (final v in ref.read(vehiclesProvider)) v.id: v.name},
    reporter: settings.reporterName,
    generatedAt: DateTime.now(),
  );
}
