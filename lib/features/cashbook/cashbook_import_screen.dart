import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/services/cashbook_import_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'widgets/cashbook_common.dart';

/// One-time import of a backup .db from the reference cashbook app. Shows a
/// dry run first; nothing is written until the user confirms. The chosen file
/// is never modified and importing twice does not duplicate entries.
class CashbookImportScreen extends ConsumerStatefulWidget {
  const CashbookImportScreen({super.key});

  @override
  ConsumerState<CashbookImportScreen> createState() =>
      _CashbookImportScreenState();
}

class _CashbookImportScreenState extends ConsumerState<CashbookImportScreen> {
  String? _path;
  String? _fileName;
  CashImportPreview? _preview;
  CashImportResult? _result;
  String? _error;
  bool _includeNotes = true;
  bool _busy = false;
  double _progress = 0;

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = r?.files.single.path;
    if (path == null) return;
    setState(() {
      _path = path;
      _fileName = r!.files.single.name;
      _preview = null;
      _result = null;
      _error = null;
    });
    try {
      final p = CashbookImportService.preview(path);
      if (mounted) setState(() => _preview = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _import() async {
    final p = _preview;
    if (p == null || _path == null) return;
    final ok = await confirmCashDialog(
      context,
      title: 'Import',
      message:
          'Import ${p.activeEntries} transactions, ${p.trashedEntries} deleted transactions'
          '${_includeNotes ? ' and ${p.notes} notes' : ''} into Account Ledger? '
          'Your existing data is kept and the file is not changed.',
      confirmLabel: 'Import',
    );
    if (!ok) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });
    try {
      final r = await CashbookImportService.run(
        _path!,
        includeNotes: _includeNotes,
        onProgress: (v) {
          if (mounted) setState(() => _progress = v);
        },
      );
      refreshCashbookAfterImport();
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void refreshCashbookAfterImport() {
    ref.read(cashBooksProvider.notifier).refresh();
    ref.read(cashEntriesProvider.notifier).refresh();
    ref.read(cashNotesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final p = _preview;
    final date = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: cashAppBar('Import from cashbook app'),
      body: CashPageBody(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Choose a backup file (.db) made with the Backup Data option of the '
              'cashbook app. You see what will be imported before anything is written.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open),
              label: Text(
                  _fileName == null ? 'Choose file' : 'Choose another file'),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(_fileName!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
            if (p != null && _result == null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dry run (nothing written yet)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _line('Books', '${p.bookNames.length}'),
                      _line('Transactions', '${p.activeEntries}'),
                      _line('Deleted transactions (kept 30 days)',
                          '${p.trashedEntries}'),
                      _line('Notes', '${p.notes}'),
                      if (p.firstDate != null && p.lastDate != null)
                        _line('Period',
                            '${date.format(p.firstDate!)} - ${date.format(p.lastDate!)}'),
                      _line(CashLabels.totalIncome,
                          settings.formatMoney(p.totalIn)),
                      _line(CashLabels.totalExpense,
                          settings.formatMoney(p.totalOut)),
                      _line(
                          CashLabels.balance,
                          settings.formatMoney(CashbookCalculator.roundMoney(
                              p.totalIn - p.totalOut))),
                      if (p.alreadyImported > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${p.alreadyImported} transactions were imported before and will be skipped.',
                            style: const TextStyle(color: AppColors.warning),
                          ),
                        ),
                      for (final w in p.warnings)
                        Text(w,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      const Divider(height: 24),
                      const Text('Books',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      for (final n in p.bookNames)
                        _line(n, '${p.entriesPerBook[n] ?? 0}'),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Import notebook'),
                        value: _includeNotes,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _includeNotes = v),
                      ),
                      const SizedBox(height: 8),
                      if (_busy) LinearProgressIndicator(value: _progress),
                      if (!_busy)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _import,
                            child: const Text('Import'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        SizedBox(width: 8),
                        Text('Import complete',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 8),
                      _line('Books created', '${_result!.booksCreated}'),
                      _line('Books merged by name', '${_result!.booksMerged}'),
                      _line('Transactions imported',
                          '${_result!.entriesImported}'),
                      _line('Deleted transactions imported',
                          '${_result!.trashedImported}'),
                      _line('Skipped (already imported)',
                          '${_result!.entriesSkipped}'),
                      _line('Notes imported', '${_result!.notesImported}'),
                      if (_result!.attachmentsDropped > 0)
                        _line('Bill files not found on this device',
                            '${_result!.attachmentsDropped}'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
