import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/models/ledger_types.dart';
import '../../../core/utils/feet_totals.dart';

const _depthColors = [
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.deepPurple
];
const _pvcColors = [Colors.teal, Colors.cyan, Colors.green, Colors.lightGreen];

class SummaryRow extends ConsumerStatefulWidget {
  const SummaryRow({super.key});

  @override
  ConsumerState<SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends ConsumerState<SummaryRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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
    final strip = Container(
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
            if (isSideBore) ...[
              divider(),
              SizedBox(
                width: 84,
                child: _FeetItem(
                  label: 'Total Depth',
                  value: '${feetFormat.format(feetTotals.depthTotal)} ft',
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isSideBore) return strip;
    return Column(
      children: [
        strip,
        _feetPanel(feetTotals, feetFormat),
      ],
    );
  }

  /// Drop down with the feet of every depth, PVC and MS pipe type.
  Widget _feetPanel(FeetTotals t, NumberFormat f) {
    Widget section(String title, Map<String, double> map, List<Color> colors) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (i, e) in map.entries.indexed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${LedgerTypes.shortLabel(e.key)}  ',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      TextSpan(
                          text: '${f.format(e.value)} ft',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors[i % colors.length])),
                    ])),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.straighten,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Feet: Depth ${f.format(t.depthTotal)}  |  '
                      'PVC ${f.format(t.pvc.values.fold(0.0, (a, b) => a + b))}  |  '
                      'MS ${f.format(t.msPipeTotal)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section('Depth by type', t.depth, _depthColors),
                  section('PVC by type', t.pvc, _pvcColors),
                  section('MS pipe by type', t.ms, const [Colors.orange]),
                ],
              ),
            ),
        ],
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
