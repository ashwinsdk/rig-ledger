import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'cashbook_book_picker_dialog.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_period_selector.dart';
import 'widgets/cashbook_totals_strip.dart';

/// Account Summary (PARITY-062): per day Income / Expense / Savings of one
/// book for a period. The totals strip does not include the previous balance.
class CashbookAccountSummaryScreen extends ConsumerStatefulWidget {
  const CashbookAccountSummaryScreen({super.key});

  @override
  ConsumerState<CashbookAccountSummaryScreen> createState() =>
      _CashbookAccountSummaryScreenState();
}

class _CashbookAccountSummaryScreenState
    extends ConsumerState<CashbookAccountSummaryScreen> {
  CashPeriodSel _sel = CashPeriodSel.today(CashPeriod.monthly);
  String? _bookId;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final current = ref.watch(currentCashBookProvider);
    final books = ref.watch(cashBooksProvider);
    final book = books.firstWhere((b) => b.id == (_bookId ?? current?.id),
        orElse: () => current ?? books.first);
    final q = _sel.query(book.id);
    final days = ref.watch(cashDaySummaryProvider(q));
    final entries = ref.watch(cashQueryEntriesProvider(q));
    final totals = CashbookCalculator.totals(entries);

    return Scaffold(
      appBar: cashAppBar('Account Summary'),
      body: CashPageBody(
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final b = await showCashBookPicker(context);
                if (b != null) setState(() => _bookId = b.id);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text(book.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            CashPeriodSelector(
              value: _sel,
              formatDate: settings.formatDate,
              periods: const [
                CashPeriod.all,
                CashPeriod.weekly,
                CashPeriod.monthly,
                CashPeriod.yearly,
              ],
              onChanged: (v) => setState(() => _sel = v),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
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
                  Expanded(
                      flex: 3,
                      child: Text('Savings',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: days.isEmpty
                  ? const Center(
                      child: Text('No transactions',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView(
                      children: [
                        for (final e in days.entries.toList().reversed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom:
                                        BorderSide(color: AppColors.divider))),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text(settings.formatDate(e.key),
                                        style: const TextStyle(fontSize: 13))),
                                _num(settings, e.value.cashIn,
                                    CashColors.income),
                                _num(settings, e.value.cashOut,
                                    CashColors.expense),
                                _num(
                                    settings,
                                    e.value.balance,
                                    e.value.balance < 0
                                        ? CashColors.expense
                                        : CashColors.balance),
                              ],
                            ),
                          ),
                      ],
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

  Widget _num(CashSettings s, double v, Color color) => Expanded(
        flex: 3,
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CashbookCalculator.formatNumber(v, fixed2: s.fixedDecimals),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      );
}
