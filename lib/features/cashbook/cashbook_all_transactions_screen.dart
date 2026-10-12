import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'cashbook_entry_form_screen.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_period_selector.dart';
import 'widgets/cashbook_row.dart';
import 'widgets/cashbook_totals_strip.dart';

/// Transaction-All Accounts (PARITY-063): every book in one list grouped by
/// day, with the book name and a single signed-by-color Amount column.
class CashbookAllTransactionsScreen extends ConsumerStatefulWidget {
  const CashbookAllTransactionsScreen({super.key});

  @override
  ConsumerState<CashbookAllTransactionsScreen> createState() =>
      _CashbookAllTransactionsScreenState();
}

class _CashbookAllTransactionsScreenState
    extends ConsumerState<CashbookAllTransactionsScreen> {
  CashPeriodSel _sel = CashPeriodSel.today(CashPeriod.all);
  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final books = ref.watch(cashBooksProvider);
    final names = {for (final b in books) b.id: b.name};
    final q = _query.trim().toLowerCase();
    final entries = ref
        .watch(cashQueryEntriesProvider(_sel.query(null)))
        .where((e) =>
            q.isEmpty ||
            e.notes.toLowerCase().contains(q) ||
            (e.description ?? '').toLowerCase().contains(q) ||
            (names[e.bookId] ?? '').toLowerCase().contains(q))
        .toList();
    final totals = CashbookCalculator.totals(entries);

    // Group by day, newest first.
    final items = <Object>[];
    DateTime? lastDay;
    for (final e in entries) {
      final day = CashbookCalculator.dateOnly(e.date);
      if (lastDay != day) {
        items.add(day);
        lastDay = day;
      }
      items.add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('Transaction-All Accounts',
                style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.appBarGradient)),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ],
      ),
      body: CashPageBody(
        child: Column(
          children: [
            CashPeriodSelector(
              value: _sel,
              formatDate: settings.formatDate,
              onChanged: (v) => setState(() => _sel = v),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 3,
                      child: Text('Accounts',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 3,
                      child: Text('Amount',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No transactions',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        if (item is DateTime) {
                          return CashbookDayHeader(
                              day: item, settings: settings);
                        }
                        final e = item as CashEntry;
                        final color =
                            e.isCashIn ? CashColors.income : CashColors.expense;
                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      CashbookEntryFormScreen(entry: e))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom:
                                        BorderSide(color: AppColors.divider))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.notes.isEmpty ? '-' : e.notes,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      Text(settings.formatTime(e.date),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(names[e.bookId] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                          settings.formatMoney(e.amount),
                                          style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: CashbookTotalsStrip(totals: totals, settings: settings),
            ),
          ],
        ),
      ),
    );
  }
}
