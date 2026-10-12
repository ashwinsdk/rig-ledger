import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'widgets/cashbook_common.dart';
import 'widgets/cashbook_period_selector.dart';
import 'widgets/cashbook_totals_strip.dart';

/// Summary (PARITY-061): one card per book that has entries plus the grand
/// total across books for the chosen period.
class CashbookSummaryScreen extends ConsumerStatefulWidget {
  const CashbookSummaryScreen({super.key});

  @override
  ConsumerState<CashbookSummaryScreen> createState() =>
      _CashbookSummaryScreenState();
}

class _CashbookSummaryScreenState extends ConsumerState<CashbookSummaryScreen> {
  CashPeriodSel _sel = CashPeriodSel.today(CashPeriod.all);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final summary = ref.watch(cashSummaryProvider(_sel.query(null)));

    return Scaffold(
      appBar: cashAppBar('Summary'),
      body: CashPageBody(
        child: Column(
          children: [
            CashPeriodSelector(
              value: _sel,
              formatDate: settings.formatDate,
              onChanged: (v) => setState(() => _sel = v),
            ),
            Expanded(
              child: summary.books.isEmpty
                  ? const Center(
                      child: Text('No transactions',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: summary.books.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = summary.books[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await ref
                                  .read(currentCashBookIdProvider.notifier)
                                  .select(s.book.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.book.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  CashbookTotalsStrip(
                                      totals: s.totals, settings: settings),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: CashbookTotalsStrip(
                  totals: summary.grand, settings: settings),
            ),
          ],
        ),
      ),
    );
  }
}
