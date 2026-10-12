import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import '../../core/utils/platform_helper.dart';
import 'cashbook_book_picker_dialog.dart';
import 'cashbook_entry_form_screen.dart';
import 'cashbook_report_dialog.dart';
import 'cashbook_settings_screen.dart';
import '../../core/services/cashbook_export_service.dart';
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
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _searching = true);

  void _stopSearch() {
    _searchController.clear();
    ref.read(cashViewConfigProvider.notifier).setQuery('');
    setState(() => _searching = false);
  }

  Future<void> _notesDialog() async {
    final c =
        TextEditingController(text: ref.read(cashViewConfigProvider).query);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search notes'),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Search')),
        ],
      ),
    );
    final text = c.text;
    c.dispose();
    if (ok != true || !mounted) return;
    _searchController.text = text;
    ref.read(cashViewConfigProvider.notifier).setQuery(text);
    setState(() => _searching = text.trim().isNotEmpty);
  }

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) ref.read(cashViewConfigProvider.notifier).setDay(d);
  }

  Future<void> _pickRange() async {
    final settings = ref.read(cashSettingsProvider);
    final range = await pickCashDateRange(context, settings.formatDate);
    if (range != null) {
      ref.read(cashViewConfigProvider.notifier).setCustomRange(range);
    }
  }

  Future<void> _editReporterName() async {
    final settings = ref.read(cashSettingsProvider);
    final text = await showReporterNameDialog(context, settings.reporterName);
    if (text != null) {
      await ref
          .read(cashSettingsProvider.notifier)
          .updateSettings(settings.copyWith(reporterName: text));
    }
  }

  /// Report of what is on screen: period, search and filters apply.
  void _report() {
    final book = ref.read(currentCashBookProvider);
    final cfg = ref.read(cashViewConfigProvider);
    final view = ref.read(cashLedgerProvider);
    final settings = ref.read(cashSettingsProvider);
    if (book == null) return;
    final rows = cfg.ascending ? view.rows : view.rows.reversed.toList();
    final range = view.range;
    final data = CashExportData(
      title: book.name,
      rangeLabel: range == null
          ? 'All'
          : CashbookCalculator.rangeLabel(range).replaceAll(' -> ', ' To '),
      allBooks: false,
      rows: rows,
      previousBalance: view.previousBalance,
      hasPreviousBalance: view.hasPreviousBalance,
      reporter: settings.reporterName,
      generatedAt: DateTime.now(),
    );
    showCashReportDialog(context, ref, data);
  }

  Widget _overflow(CashViewConfig cfg) {
    final notifier = ref.read(cashViewConfigProvider.notifier);
    return PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (v) {
        switch (v) {
          case 'notes':
            _notesDialog();
          case 'date':
            _pickDay();
          case 'range':
            _pickRange();
          case 'asc':
            notifier.setAscending(true);
          case 'desc':
            notifier.setAscending(false);
          case 'income':
            notifier.setType(cfg.type == CashTypeFilter.income
                ? CashTypeFilter.all
                : CashTypeFilter.income);
          case 'expense':
            notifier.setType(cfg.type == CashTypeFilter.expense
                ? CashTypeFilter.all
                : CashTypeFilter.expense);
          case 'name':
            _editReporterName();
          case 'clear':
            _searchController.clear();
            notifier.clearFilters();
            setState(() => _searching = false);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'notes', child: Text('Notes')),
        const PopupMenuItem(value: 'date', child: Text('Date')),
        const PopupMenuItem(value: 'range', child: Text('Select Date Range')),
        CheckedPopupMenuItem(
            value: 'asc',
            checked: cfg.ascending,
            child: const Text('Date Ascending')),
        CheckedPopupMenuItem(
            value: 'desc',
            checked: !cfg.ascending,
            child: const Text('Date Descending')),
        CheckedPopupMenuItem(
            value: 'income',
            checked: cfg.type == CashTypeFilter.income,
            child: const Text(CashLabels.income)),
        CheckedPopupMenuItem(
            value: 'expense',
            checked: cfg.type == CashTypeFilter.expense,
            child: const Text(CashLabels.expense)),
        const PopupMenuItem(value: 'clear', child: Text('Clear filters')),
        const PopupMenuItem(
            value: 'name', child: Text('Your Name and Address')),
      ],
    );
  }

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
          leading: _searching
              ? IconButton(
                  tooltip: 'Close search',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _stopSearch)
              : (widget.onMenu == null
                  ? null
                  : IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.menu),
                      onPressed: widget.onMenu)),
          title: _searching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                      color: PlatformHelper.isDesktop
                          ? AppColors.textPrimary
                          : Colors.white),
                  cursorColor: PlatformHelper.isDesktop
                      ? AppColors.textPrimary
                      : Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        color: PlatformHelper.isDesktop
                            ? AppColors.textHint
                            : Colors.white70),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) =>
                      ref.read(cashViewConfigProvider.notifier).setQuery(v),
                )
              : InkWell(
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
          actions: [
            if (!_searching)
              IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch),
            IconButton(
                tooltip: 'Report',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _report),
            _overflow(cfg),
          ],
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
        if (cfg.type != CashTypeFilter.all || cfg.ascending || searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (searching) 'Search: "${cfg.query.trim()}"',
                      if (cfg.type == CashTypeFilter.income) CashLabels.income,
                      if (cfg.type == CashTypeFilter.expense)
                        CashLabels.expense,
                      if (cfg.ascending) 'Oldest first',
                    ].join('  |  '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(cashViewConfigProvider.notifier).clearFilters();
                    setState(() => _searching = false);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
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
