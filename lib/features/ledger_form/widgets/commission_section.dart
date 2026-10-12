import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/models/ledger_entry.dart';
import '../../../core/theme/app_colors.dart';

/// Commission block of a bill (v2.0.0): rate per foot for depth (and PVC / MS
/// pipe on main bore) and the resulting commission, which can be overridden.
/// Commission is informational and is never part of the bill total.
///
/// The form owns the controllers; this widget only lays them out and calls
/// [onChanged] after any edit so the form can recalculate.
class CommissionSection extends StatelessWidget {
  final double depthFeet;
  final double pvcFeet;
  final double msPipeFeet;
  final bool showPvcAndMs;
  final TextEditingController depthRate;
  final TextEditingController pvcRate;
  final TextEditingController msPipeRate;
  final TextEditingController commission;
  final bool isManual;
  final VoidCallback onChanged;
  final ValueChanged<bool> onManualChanged;

  const CommissionSection({
    super.key,
    required this.depthFeet,
    required this.pvcFeet,
    required this.msPipeFeet,
    required this.showPvcAndMs,
    required this.depthRate,
    required this.pvcRate,
    required this.msPipeRate,
    required this.commission,
    required this.isManual,
    required this.onChanged,
    required this.onManualChanged,
  });

  /// Commission calculated from the current rates (used by the form).
  static double calculate({
    required double depthFeet,
    required double pvcFeet,
    required double msPipeFeet,
    required TextEditingController depthRate,
    required TextEditingController pvcRate,
    required TextEditingController msPipeRate,
    required bool showPvcAndMs,
  }) {
    return LedgerEntry.calculateCommission(
      depthInFeet: depthFeet,
      depthCommissionRate: double.tryParse(depthRate.text) ?? 0,
      pvcInFeet: showPvcAndMs ? pvcFeet : 0,
      pvcCommissionRate:
          showPvcAndMs ? (double.tryParse(pvcRate.text) ?? 0) : 0,
      msPipeInFeet: showPvcAndMs ? msPipeFeet : 0,
      msPipeCommissionRate:
          showPvcAndMs ? (double.tryParse(msPipeRate.text) ?? 0) : 0,
    );
  }

  Widget _rate(TextEditingController c, String label, double feet) {
    final money = NumberFormat('#,##0.##');
    final part = feet * (double.tryParse(c.text) ?? 0);
    return Expanded(
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: '${money.format(feet)} ft = ₹${money.format(part)}',
        ),
        onChanged: (_) => onChanged(),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rate(depthRate, 'Depth rate (₹/ft)', depthFeet),
              if (showPvcAndMs) ...[
                const SizedBox(width: 8),
                _rate(pvcRate, 'PVC rate (₹/ft)', pvcFeet),
                const SizedBox(width: 8),
                _rate(msPipeRate, 'MS rate (₹/ft)', msPipeFeet),
              ],
            ],
          ),
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
