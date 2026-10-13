import 'package:flutter/material.dart';
import '../../../core/providers/cashbook_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cashbook_calculator.dart';
import 'cashbook_common.dart';

/// Total Income / Total Expense / Balance strip (PARITY-034). When
/// [previousBalance] is given, "Previous Balance" and the final "Balance"
/// rows are added below (PARITY-037).
class CashbookTotalsStrip extends StatelessWidget {
  final CashTotals totals;
  final CashSettings settings;
  final double? previousBalance;

  const CashbookTotalsStrip({
    super.key,
    required this.totals,
    required this.settings,
    this.previousBalance,
  });

  /// One summary column: icon and label, then the amount (same layout as the
  /// ledger summary card).
  Widget _cell(IconData icon, String label, double value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(settings.formatMoney(value),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bal = totals.balance;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                _cell(Icons.south_west, CashLabels.totalIncome, totals.cashIn,
                    CashColors.income),
                const VerticalDivider(width: 1, color: AppColors.divider),
                _cell(Icons.north_east, CashLabels.totalExpense, totals.cashOut,
                    CashColors.expense),
                const VerticalDivider(width: 1, color: AppColors.divider),
                _cell(Icons.account_balance_wallet_outlined, CashLabels.balance,
                    bal, bal < 0 ? CashColors.expense : CashColors.balance),
              ],
            ),
          ),
          if (previousBalance != null) ...[
            const Divider(height: 1, color: AppColors.divider),
            _line('Previous Balance', previousBalance!),
            const Divider(height: 1, color: AppColors.divider),
            _line(CashLabels.balance,
                CashbookCalculator.roundMoney(previousBalance! + bal),
                bold: true),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          Text(settings.formatMoney(value),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: value < 0 ? CashColors.expense : CashColors.balance)),
        ],
      ),
    );
  }
}
