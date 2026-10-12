import 'package:flutter/material.dart';
import '../../../core/providers/cashbook_provider.dart';
import '../../../core/utils/cashbook_calculator.dart';
import 'cashbook_common.dart';
import 'cashbook_period_bar.dart';

/// Period state of the summary screens (tab, anchor date, optional custom
/// range). Immutable; use the helpers to derive new values.
class CashPeriodSel {
  final CashPeriod period;
  final DateTime anchor;
  final CashDateRange? custom;
  const CashPeriodSel(this.period, this.anchor, [this.custom]);

  factory CashPeriodSel.today(CashPeriod period) =>
      CashPeriodSel(period, DateTime.now());

  CashDateRange? get range =>
      custom ?? CashbookCalculator.periodRange(period, anchor);

  String get label =>
      range == null ? 'All' : CashbookCalculator.rangeLabel(range!);

  bool get canShift => custom == null && period != CashPeriod.all;

  CashPeriodSel withPeriod(CashPeriod p) => CashPeriodSel(p, DateTime.now());

  CashPeriodSel shifted(int delta) => CashPeriodSel(
      period, CashbookCalculator.shiftAnchor(period, anchor, delta));

  CashPeriodSel withCustom(CashDateRange r) => CashPeriodSel(period, anchor, r);

  /// Key for the summary providers.
  CashQuery query(String? bookId) =>
      (bookId: bookId, period: period, anchor: anchor, custom: custom);
}

/// Tabs plus the period bar, with an optional date range button.
class CashPeriodSelector extends StatelessWidget {
  final CashPeriodSel value;
  final ValueChanged<CashPeriodSel> onChanged;
  final List<CashPeriod> periods;
  final String Function(DateTime) formatDate;

  const CashPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.formatDate,
    this.periods = CashPeriod.values,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CashbookPeriodTabs(
                periods: periods,
                selected: value.custom != null ? CashPeriod.all : value.period,
                onSelected: (p) => onChanged(value.withPeriod(p)),
              ),
            ),
            IconButton(
              tooltip: 'Select Date Range',
              icon: const Icon(Icons.date_range),
              onPressed: () async {
                final r = await pickCashDateRange(context, formatDate);
                if (r != null) onChanged(value.withCustom(r));
              },
            ),
          ],
        ),
        CashbookPeriodBar(
          label: value.label,
          onShift: value.canShift ? (d) => onChanged(value.shifted(d)) : null,
        ),
      ],
    );
  }
}
