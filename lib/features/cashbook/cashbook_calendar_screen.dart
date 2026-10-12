import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'cashbook_book_picker_dialog.dart';
import 'cashbook_entry_form_screen.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_period_bar.dart';
import 'widgets/cashbook_totals_strip.dart';

/// Calendar (PARITY-064): month grid with per day income and expense sums.
/// Tapping a day lists its entries.
class CashbookCalendarScreen extends ConsumerStatefulWidget {
  const CashbookCalendarScreen({super.key});

  @override
  ConsumerState<CashbookCalendarScreen> createState() =>
      _CashbookCalendarScreenState();
}

class _CashbookCalendarScreenState
    extends ConsumerState<CashbookCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _bookId;

  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final books = ref.watch(cashBooksProvider);
    final current = ref.watch(currentCashBookProvider);
    final book = books.firstWhere((b) => b.id == (_bookId ?? current?.id),
        orElse: () => current ?? books.first);
    final q = (
      bookId: book.id as String?,
      period: CashPeriod.monthly,
      anchor: _month,
      custom: null as CashDateRange?
    );
    final days = ref.watch(cashDaySummaryProvider(q));
    final entries = ref.watch(cashQueryEntriesProvider(q));
    final totals = CashbookCalculator.totals(entries);

    final range = CashbookCalculator.periodRange(CashPeriod.monthly, _month)!;
    final daysInMonth = range.lastDay.day;
    final lead = range.start.weekday % 7; // Sunday first
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];

    return Scaffold(
      appBar: cashAppBar(book.name, actions: [
        IconButton(
          tooltip: 'Accounts',
          icon: const Icon(Icons.account_balance_wallet_outlined),
          onPressed: () async {
            final b = await showCashBookPicker(context);
            if (b != null) setState(() => _bookId = b.id);
          },
        ),
      ]),
      body: CashPageBody(
        maxWidth: 800,
        child: Column(
          children: [
            const SizedBox(height: 8),
            CashbookPeriodBar(
                label: CashbookCalculator.rangeLabel(range), onShift: _shift),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final d in const [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat'
                ])
                  Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.72,
                ),
                itemCount: cells.length,
                itemBuilder: (_, i) {
                  final day = cells[i];
                  if (day == null) return const SizedBox.shrink();
                  final t = days[day];
                  final isToday =
                      CashbookCalculator.dateOnly(DateTime.now()) == day;
                  return InkWell(
                    onTap: t == null
                        ? null
                        : () => _showDay(context, entries, day, settings),
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                            color:
                                isToday ? AppColors.primary : AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text('${day.day}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500)),
                          if (t != null && t.cashIn > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  CashbookCalculator.formatNumber(t.cashIn),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: CashColors.income,
                                      fontWeight: FontWeight.w600)),
                            ),
                          if (t != null && t.cashOut > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  CashbookCalculator.formatNumber(t.cashOut),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: CashColors.expense,
                                      fontWeight: FontWeight.w600)),
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

  void _showDay(BuildContext context, List<CashEntry> all, DateTime day,
      CashSettings settings) {
    final list =
        all.where((e) => CashbookCalculator.dateOnly(e.date) == day).toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(settings.formatDayHeader(day),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in list)
                    ListTile(
                      dense: true,
                      title: Text(e.notes.isEmpty ? '-' : e.notes),
                      subtitle: Text(settings.formatTime(e.date)),
                      trailing: Text(settings.formatMoney(e.amount),
                          style: TextStyle(
                              color: e.isCashIn
                                  ? CashColors.income
                                  : CashColors.expense,
                              fontWeight: FontWeight.w700)),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CashbookEntryFormScreen(entry: e)));
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
