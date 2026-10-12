import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'cashbook_book_picker_dialog.dart';
import 'cashbook_entry_form_screen.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_header.dart';
import 'widgets/cashbook_period_bar.dart';
import 'widgets/cashbook_row.dart';
import 'widgets/cashbook_totals_strip.dart';

/// Account Ledger home: header with book selector, period tabs, grouped list,
/// Income / Expense buttons and the totals strip (PARITY-013, 031..041).
class CashbookHomeScreen extends ConsumerStatefulWidget {
  /// Opens the hub (drawer on mobile). Null hides the menu button.
  final VoidCallback? onMenu;

  const CashbookHomeScreen({super.key, this.onMenu});

  @override
  ConsumerState<CashbookHomeScreen> createState() => _CashbookHomeScreenState();
}

class _CashbookHomeScreenState extends ConsumerState<CashbookHomeScreen> {
  Future<void> _pickBook() async {
    final book = await showCashBookPicker(context);
    if (book != null) {
      await ref.read(currentCashBookIdProvider.notifier).select(book.id);
      ref.read(cashViewConfigProvider.notifier).clearFilters();
    }
  }

  void _openForm({required bool income}) {
    final book = ref.read(currentCashBookProvider);
    if (book == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          CashbookEntryFormScreen(bookId: book.id, initialCashIn: income),
    ));
  }

  void _openEdit(CashEntry e) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CashbookEntryFormScreen(entry: e)));
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(currentCashBookProvider);
    final cfg = ref.watch(cashViewConfigProvider);
    final view = ref.watch(cashLedgerProvider);
    final settings = ref.watch(cashSettingsProvider);

    final items = <Object>[];
    if (view.hasPreviousBalance) items.add('prev');
    for (final g in view.groups) {
      items.add(g.day);
      items.addAll(g.rows);
    }

    final searching = cfg.query.trim().isNotEmpty;
    final rangeLabel =
        view.range == null ? 'All' : CashbookCalculator.rangeLabel(view.range!);

    return Column(
      children: [
        CashHeader(
          leading: widget.onMenu == null
              ? null
              : IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: widget.onMenu),
          title: InkWell(
            onTap: _pickBook,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(book?.name ?? 'Account Ledger',
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        CashbookPeriodTabs(
          selected: cfg.customRange != null ? CashPeriod.all : cfg.period,
          onSelected: (p) =>
              ref.read(cashViewConfigProvider.notifier).setPeriod(p),
        ),
        CashbookPeriodBar(
          label: rangeLabel,
          onShift: (cfg.period == CashPeriod.all ||
                  cfg.customRange != null ||
                  searching)
              ? null
              : (d) => ref.read(cashViewConfigProvider.notifier).shift(d),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                  flex: 5,
                  child: Text('Date',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              Expanded(
                  flex: 3,
                  child: Text(CashLabels.income,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: CashColors.income,
                          fontWeight: FontWeight.w700))),
              Expanded(
                  flex: 3,
                  child: Text(CashLabels.expense,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: CashColors.expense,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: CashPageBody(
            child: items.isEmpty
                ? const Center(
                    child: Text('No transactions',
                        style: TextStyle(color: AppColors.textHint)))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item == 'prev') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Text('Previous Balance',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Text(settings.formatMoney(view.previousBalance),
                                  style: const TextStyle(
                                      color: CashColors.balance,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }
                      if (item is DateTime) {
                        return CashbookDayHeader(day: item, settings: settings);
                      }
                      final row = item as CashLedgerRow;
                      return CashbookRow(
                        row: row,
                        settings: settings,
                        onTap: () => _openEdit(row.entry),
                      );
                    },
                  ),
          ),
        ),
        CashPageBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CashColors.income),
                        onPressed:
                            book == null ? null : () => _openForm(income: true),
                        child: const Text(CashLabels.income),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CashColors.expense),
                        onPressed: book == null
                            ? null
                            : () => _openForm(income: false),
                        child: const Text(CashLabels.expense),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CashbookTotalsStrip(
                  totals: view.totals,
                  settings: settings,
                  previousBalance:
                      view.hasPreviousBalance ? view.previousBalance : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
