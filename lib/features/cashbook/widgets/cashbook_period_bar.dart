import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cashbook_calculator.dart';

const _periodLabels = {
  CashPeriod.all: 'All',
  CashPeriod.daily: 'Daily',
  CashPeriod.weekly: 'Weekly',
  CashPeriod.monthly: 'Monthly',
  CashPeriod.yearly: 'Yearly',
};

/// Chips: All, Daily, Weekly, Monthly, Yearly (PARITY-036). [periods] limits
/// the tabs (Account Summary has no Daily tab).
class CashbookPeriodTabs extends StatelessWidget {
  final CashPeriod selected;
  final ValueChanged<CashPeriod> onSelected;
  final List<CashPeriod> periods;

  /// Pill chips for use inside the gradient header (same look as the main
  /// ledger period chips).
  final bool onGradient;

  const CashbookPeriodTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.periods = CashPeriod.values,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onGradient) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            for (final p in periods)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onSelected(p),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected == p
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _periodLabels[p]!,
                      style: TextStyle(
                        color: selected == p ? AppColors.primary : Colors.white,
                        fontWeight:
                            selected == p ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final p in periods)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_periodLabels[p]!,
                    style: TextStyle(
                        color: selected == p
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                selected: selected == p,
                selectedColor: AppColors.primary,
                showCheckmark: false,
                side: BorderSide(
                    color:
                        selected == p ? AppColors.primary : AppColors.border),
                backgroundColor: AppColors.surface,
                onSelected: (_) => onSelected(p),
              ),
            ),
        ],
      ),
    );
  }
}

/// Period label with previous/next arrows. [label] is for example
/// "Oct-01-2026 -> Oct-31-2026". Arrows are hidden when [onShift] is null.
class CashbookPeriodBar extends StatelessWidget {
  final String label;
  final void Function(int delta)? onShift;

  /// White chevrons and label on the gradient, like the main ledger month row.
  final bool onGradient;

  const CashbookPeriodBar(
      {super.key, required this.label, this.onShift, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    if (onGradient) {
      return Row(
        children: [
          if (onShift != null)
            IconButton(
                tooltip: 'Previous',
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => onShift!(-1))
          else
            const SizedBox(width: 48, height: 48),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ),
          if (onShift != null)
            IconButton(
                tooltip: 'Next',
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => onShift!(1))
          else
            const SizedBox(width: 48, height: 48),
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (onShift != null)
            IconButton(
                tooltip: 'Previous',
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () => onShift!(-1))
          else
            const SizedBox(width: 48, height: 48),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          if (onShift != null)
            IconButton(
                tooltip: 'Next',
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: () => onShift!(1))
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}
