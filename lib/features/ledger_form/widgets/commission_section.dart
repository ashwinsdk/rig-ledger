import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// One commission rate field of the section: a bill line.
class CommissionRow {
  /// 'depth', 'pvc' or 'ms'.
  final String category;
  final String label; // for example 'Depth 7inch'
  final double feet;
  final TextEditingController rate;

  const CommissionRow({
    required this.category,
    required this.label,
    required this.feet,
    required this.rate,
  });

  double get amount => feet * (double.tryParse(rate.text) ?? 0);
}

/// Commission block of a bill (v2.0.1, lines in v2.0.2): a rate per foot for
/// every depth, PVC and MS pipe line, the amount per kind and the total, which
/// can be overridden. Commission is informational and is never part of the
/// bill total.
///
/// The form owns the controllers; this widget only lays them out and calls
/// [onChanged] after any edit so the form can recalculate.
class CommissionSection extends StatelessWidget {
  final List<CommissionRow> rows;
  final TextEditingController commission;
  final bool isManual;
  final VoidCallback onChanged;
  final ValueChanged<bool> onManualChanged;

  const CommissionSection({
    super.key,
    required this.rows,
    required this.commission,
    required this.isManual,
    required this.onChanged,
    required this.onManualChanged,
  });

  /// Commission calculated from the current rates (used by the form).
  static double calculate(Iterable<CommissionRow> rows) {
    final c = rows.fold(0.0, (a, r) => a + r.amount);
    return (c * 100).round() / 100;
  }

  Widget _rate(CommissionRow r) {
    final money = NumberFormat('#,##0.##');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: r.rate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
        decoration: InputDecoration(
          labelText: '${r.label} rate (₹/ft)',
          helperText: '${money.format(r.feet)} ft = ₹${money.format(r.amount)}',
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }

  Widget _line(String label, double value, {bool bold = false, String? tag}) {
    final money = NumberFormat('#,##0.##');
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (tag != null) ...[
            Text(tag,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning)),
            const SizedBox(width: 8),
          ],
          Text('₹${money.format(value)}', style: style),
        ],
      ),
    );
  }

  /// Read-only totals: the commission of each kind and of the bill.
  Widget _breakdown() {
    double of(String cat) =>
        rows.where((r) => r.category == cat).fold(0.0, (a, r) => a + r.amount);
    final total = double.tryParse(commission.text) ?? 0;
    final has = {for (final r in rows) r.category};
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (has.contains('depth')) _line('Depth commission', of('depth')),
          if (has.contains('pvc')) _line('PVC commission', of('pvc')),
          if (has.contains('ms')) _line('MS pipe commission', of('ms')),
          const Divider(height: 12),
          _line('Total commission', total,
              bold: true, tag: isManual ? 'manual' : null),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Commission',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Flexible(
                child: Text('not added to total',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in rows) _rate(r),
          const SizedBox(height: 12),
          _breakdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: commission,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  decoration: InputDecoration(
                    labelText: 'Commission (₹)',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    suffixIcon: isManual
                        ? const Tooltip(
                            message: 'Manually edited',
                            child: Icon(Icons.edit, color: AppColors.warning))
                        : null,
                  ),
                  onChanged: (_) {
                    if (!isManual) onManualChanged(true);
                  },
                ),
              ),
              if (isManual) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => onManualChanged(false),
                  child: const Text('Auto'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
