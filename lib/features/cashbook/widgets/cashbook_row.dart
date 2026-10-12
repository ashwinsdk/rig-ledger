import 'package:flutter/material.dart';
import '../../../core/providers/cashbook_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cashbook_calculator.dart';
import 'cashbook_common.dart';

/// Day header band, "Mon, Oct 12 2026".
class CashbookDayHeader extends StatelessWidget {
  final DateTime day;
  final CashSettings settings;
  const CashbookDayHeader(
      {super.key, required this.day, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.divider,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(settings.formatDayHeader(day),
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}

/// One ledger row: notes and time at the left, amount in the Income or
/// Expense column, running balance under the amount (PARITY-032).
class CashbookRow extends StatelessWidget {
  final CashLedgerRow row;
  final CashSettings settings;
  final VoidCallback onTap;

  const CashbookRow({
    super.key,
    required this.row,
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = row.entry;
    final color = e.isCashIn ? CashColors.income : CashColors.expense;
    final meta = <String>[
      if (settings.showDateInEntry) settings.formatDate(e.date),
      if (settings.showTime) settings.formatTime(e.date),
    ].join('  ');

    Widget amountCell(bool inCol) => Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: e.isCashIn == inCol
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(settings.formatMoney(e.amount),
                        style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  )
                : const SizedBox.shrink(),
          ),
        );

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.notes.isEmpty ? '-' : e.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              color: e.notes.isEmpty
                                  ? AppColors.textHint
                                  : AppColors.textPrimary),
                        ),
                        if ((e.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(e.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                          ),
                      ],
                    ),
                  ),
                  amountCell(true),
                  amountCell(false),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (meta.isNotEmpty)
                    Text(meta,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  if ((e.attachmentPaths ?? const []).isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.attach_file,
                        size: 14, color: AppColors.textSecondary),
                  ],
                  if (e.sourceType != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.link,
                        size: 14, color: AppColors.textSecondary),
                  ],
                  const Spacer(),
                  if (settings.showBalancePerEntry)
                    Text(
                        'Balance ${CashbookCalculator.formatNumber(row.balance, fixed2: settings.fixedDecimals)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
