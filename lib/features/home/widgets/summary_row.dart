import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/models/ledger_types.dart';

const _depthColors = [
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.deepPurple
];
const _pvcColors = [Colors.teal, Colors.cyan, Colors.green, Colors.lightGreen];

class SummaryRow extends ConsumerWidget {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyStatsProvider);
    final feetTotals = ref.watch(feetTotalsProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);
    final isSideBore = currentVehicle?.vehicleType == VehicleType.sideBore;
    final currencyFormat = NumberFormat('#,##0.00');
    final feetFormat = NumberFormat('#,##0');

    Widget divider() => Container(
          width: 1,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: AppColors.divider,
        );

    // One slim card, scrolls sideways: money totals first, then the feet of
    // every depth and PVC type (user-defined) and MS pipe.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: _SummaryItem(
                label: 'Total',
                value: '₹${currencyFormat.format(stats['total'] ?? 0)}',
                color: AppColors.primary,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            divider(),
            SizedBox(
              width: 120,
              child: _SummaryItem(
                label: 'Received',
                value: '₹${currencyFormat.format(stats['received'] ?? 0)}',
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            divider(),
            SizedBox(
              width: 120,
              child: _SummaryItem(
                label: 'Balance',
                value: '₹${currencyFormat.format(stats['balance'] ?? 0)}',
                color: AppColors.warning,
                icon: Icons.pending_outlined,
              ),
            ),
            divider(),
            SizedBox(
              width: 120,
              child: _SummaryItem(
                label: 'Commission',
                value: '₹${currencyFormat.format(stats['commission'] ?? 0)}',
                color: AppColors.accent,
                icon: Icons.handshake_outlined,
              ),
            ),
            divider(),
            // Side bore: only the total depth (no type split)
            if (isSideBore)
              SizedBox(
                width: 84,
                child: _FeetItem(
                  label: 'Total Depth',
                  value: '${feetFormat.format(feetTotals.depthTotal)} ft',
                  color: Colors.blue,
                ),
              )
            else ...[
              for (final (i, e) in feetTotals.depth.entries.indexed)
                SizedBox(
                  width: 72,
                  child: _FeetItem(
                    label: '${LedgerTypes.shortLabel(e.key)} Depth',
                    value: '${feetFormat.format(e.value)} ft',
                    color: _depthColors[i % _depthColors.length],
                  ),
                ),
              for (final (i, e) in feetTotals.pvc.entries.indexed)
                SizedBox(
                  width: 72,
                  child: _FeetItem(
                    label: '${LedgerTypes.shortLabel(e.key)} PVC',
                    value: '${feetFormat.format(e.value)} ft',
                    color: _pvcColors[i % _pvcColors.length],
                  ),
                ),
              SizedBox(
                width: 72,
                child: _FeetItem(
                  label: 'MS Pipe',
                  value: '${feetFormat.format(feetTotals.msPipeTotal)} ft',
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
