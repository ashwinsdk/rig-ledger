import 'package:flutter/material.dart';
import '../../../core/providers/cashbook_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cashbook_calculator.dart';
import 'cashbook_common.dart';

/// Day header above a group of cards, "Mon, Oct 12 2026" (same look as the
/// ledger date headers).
class CashbookDayHeader extends StatelessWidget {
  final DateTime day;
  final CashSettings settings;
  const CashbookDayHeader(
      {super.key, required this.day, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(settings.formatDayHeader(day),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }
}

/// One ledger entry as a floating card: notes, description and time at the
/// left, the signed amount at the right with the running balance under it
/// (PARITY-032). Same card style as the ledger bill cards.
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.notes.isEmpty ? '-' : e.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (meta.isNotEmpty)
                            Text(meta,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
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
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amounts shrink to fit instead of squeezing the notes.
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(settings.formatMoney(e.amount),
                            style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                      if (settings.showBalancePerEntry)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                                'Balance ${settings.formatNumber(row.balance)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
