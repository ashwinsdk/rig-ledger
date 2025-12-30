import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/ledger_entry.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../ledger_form/ledger_form_screen.dart';

class LedgerList extends ConsumerWidget {
  const LedgerList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedEntries = ref.watch(groupedLedgerEntriesProvider);
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No entries yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first entry',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final entries = groupedEntries[date]!;
        return _DateGroup(date: date, entries: entries);
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<LedgerEntry> entries;

  const _DateGroup({
    required this.date,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final dayTotal = entries.fold<double>(0, (sum, e) => sum + e.total);
    final currencyFormat = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyFormat.format(dayTotal),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Entries
        ...entries.map((entry) => _LedgerEntryCard(entry: entry)),
      ],
    );
  }
}

class _LedgerEntryCard extends StatelessWidget {
  final LedgerEntry entry;

  const _LedgerEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEditForm(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Bill number and Agent
                Row(
                  children: [
                    // Bill number
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${entry.billNumber}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Agent name (highlighted)
                    Expanded(
                      child: Text(
                        entry.agentName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row: Depth, PVC
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.straighten,
                      label: 'Depth',
                      value: '${entry.depthInFeet}ft (${entry.depth})',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.format_paint_outlined,
                      label: 'PVC',
                      value: entry.pvc,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Third row: Total, Received, Balance
                Row(
                  children: [
                    Expanded(
                      child: _ValueDisplay(
                        label: 'Total',
                        value: currencyFormat.format(entry.total),
                        isHighlighted: true,
                        showOverride: entry.isTotalManuallyEdited,
                      ),
                    ),
                    Expanded(
                      child: _ValueDisplay(
                        label: 'Received',
                        value: currencyFormat.format(entry.received),
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _ValueDisplay(
                        label: 'Balance',
                        value: currencyFormat.format(entry.balance),
                        isHighlighted: true,
                        color: entry.balance > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LedgerFormScreen(entry: entry),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final bool showOverride;
  final Color? color;

  const _ValueDisplay({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.showOverride = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (showOverride) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 10,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ??
                (isHighlighted ? AppColors.primary : AppColors.textPrimary),
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
