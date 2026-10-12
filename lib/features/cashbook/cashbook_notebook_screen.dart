import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_note.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import 'cashbook_note_form_screen.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_period_selector.dart';
import '../../core/utils/cashbook_calculator.dart';

enum _NoteFilter { all, completed, pending }

/// Notebook (PARITY-065..068): dated to-do notes with a completed checkbox,
/// period tabs and Completed / Pending / Total stats.
class CashbookNotebookScreen extends ConsumerStatefulWidget {
  const CashbookNotebookScreen({super.key});

  @override
  ConsumerState<CashbookNotebookScreen> createState() =>
      _CashbookNotebookScreenState();
}

class _CashbookNotebookScreenState
    extends ConsumerState<CashbookNotebookScreen> {
  CashPeriodSel _sel = CashPeriodSel.today(CashPeriod.monthly);
  _NoteFilter _filter = _NoteFilter.all;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final all = ref.watch(cashNotesProvider);
    final range = _sel.range;
    final inPeriod =
        all.where((n) => range == null || range.contains(n.date)).toList();
    final completed = inPeriod.where((n) => n.isCompleted).length;
    final pending = inPeriod.length - completed;

    final shown = inPeriod.where((n) {
      switch (_filter) {
        case _NoteFilter.all:
          return true;
        case _NoteFilter.completed:
          return n.isCompleted;
        case _NoteFilter.pending:
          return !n.isCompleted;
      }
    }).toList()
      ..sort((a, b) =>
          _ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    Widget stat(String label, int v, Color c) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(
                        color: c, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('$v',
                    style: TextStyle(
                        color: c, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: cashAppBar('Notebook', actions: [
        PopupMenuButton<String>(
          onSelected: (v) => setState(() {
            switch (v) {
              case 'completed':
                _filter = _filter == _NoteFilter.completed
                    ? _NoteFilter.all
                    : _NoteFilter.completed;
              case 'pending':
                _filter = _filter == _NoteFilter.pending
                    ? _NoteFilter.all
                    : _NoteFilter.pending;
              case 'asc':
                _ascending = true;
              case 'desc':
                _ascending = false;
            }
          }),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
                value: 'completed',
                checked: _filter == _NoteFilter.completed,
                child: const Text('Completed')),
            CheckedPopupMenuItem(
                value: 'pending',
                checked: _filter == _NoteFilter.pending,
                child: const Text('Pending')),
            CheckedPopupMenuItem(
                value: 'asc',
                checked: _ascending,
                child: const Text('Date Ascending')),
            CheckedPopupMenuItem(
                value: 'desc',
                checked: !_ascending,
                child: const Text('Date Descending')),
          ],
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CashbookNoteFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: CashPageBody(
        maxWidth: 800,
        child: Column(
          children: [
            CashPeriodSelector(
              value: _sel,
              formatDate: settings.formatDate,
              onChanged: (v) => setState(() => _sel = v),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const Center(
                      child: Text('No notes',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: shown.length,
                      itemBuilder: (_, i) =>
                          _NoteTile(note: shown[i], settings: settings),
                    ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    stat('Completed', completed, CashColors.income),
                    const VerticalDivider(width: 1),
                    stat('Pending', pending, CashColors.expense),
                    const VerticalDivider(width: 1),
                    stat('Total', inPeriod.length, AppColors.textPrimary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends ConsumerWidget {
  final CashNote note;
  final CashSettings settings;
  const _NoteTile({required this.note, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CashbookNoteFormScreen(note: note))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.text,
                      style: TextStyle(
                        fontSize: 15,
                        decoration: note.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: note.isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${settings.formatDayHeader(note.date)} ${settings.formatTime(note.date)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Checkbox(
                value: note.isCompleted,
                onChanged: (_) => ref
                    .read(cashNotesProvider.notifier)
                    .toggleCompleted(note.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
