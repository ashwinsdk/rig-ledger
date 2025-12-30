import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ledger_provider.dart';

class SummaryRow extends ConsumerWidget {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyStatsProvider);
    final feetTotals = ref.watch(feetTotalsProvider);
    final currencyFormat = NumberFormat('#,##0.00');
    final feetFormat = NumberFormat('#,##0');

    return Column(
      children: [
        // Financial Summary Row
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total',
                  value: '₹${currencyFormat.format(stats['total'] ?? 0)}',
                  color: AppColors.primary,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Received',
                  value: '₹${currencyFormat.format(stats['received'] ?? 0)}',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Balance',
                  value: '₹${currencyFormat.format(stats['balance'] ?? 0)}',
                  color: AppColors.warning,
                  icon: Icons.pending_outlined,
                ),
              ),
            ],
          ),
        ),
        // Feet Totals Row
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Feet Totals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _FeetItem(
                      label: '7" Depth',
                      value:
                          '${feetFormat.format(feetTotals['depth7inch'] ?? 0)} ft',
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _FeetItem(
                      label: '8" Depth',
                      value:
                          '${feetFormat.format(feetTotals['depth8inch'] ?? 0)} ft',
                      color: Colors.indigo,
                    ),
                  ),
                  Expanded(
                    child: _FeetItem(
                      label: '7" PVC',
                      value:
                          '${feetFormat.format(feetTotals['pvc7inch'] ?? 0)} ft',
                      color: Colors.teal,
                    ),
                  ),
                  Expanded(
                    child: _FeetItem(
                      label: '8" PVC',
                      value:
                          '${feetFormat.format(feetTotals['pvc8inch'] ?? 0)} ft',
                      color: Colors.cyan,
                    ),
                  ),
                  Expanded(
                    child: _FeetItem(
                      label: 'MS Pipe',
                      value:
                          '${feetFormat.format(feetTotals['msPipeTotal'] ?? 0)} ft',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeetItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FeetItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
