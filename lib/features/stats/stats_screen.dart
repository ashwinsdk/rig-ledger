import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/providers/ledger_provider.dart';

enum DateRangeOption {
  currentMonth,
  lastThreeMonths,
  lastSixMonths,
  lastYear,
  custom
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateRangeOption _dateRangeOption = DateRangeOption.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    // Force rebuild when ledger entries change
    ref.watch(ledgerEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date range selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRangeChip(
                              'Month', DateRangeOption.currentMonth),
                          _buildRangeChip(
                              '3 Mo', DateRangeOption.lastThreeMonths),
                          _buildRangeChip(
                              '6 Mo', DateRangeOption.lastSixMonths),
                          _buildRangeChip('Year', DateRangeOption.lastYear),
                          _buildRangeChip('Custom', DateRangeOption.custom),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom date range picker
                  if (_dateRangeOption == DateRangeOption.custom)
                    _buildCustomDateRangePicker(),

                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // Pie Chart
                  _buildPieChartSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, DateRangeOption option) {
    final isSelected = _dateRangeOption == option;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dateRangeOption = option;
            if (option == DateRangeOption.custom && _customStartDate == null) {
              final now = DateTime.now();
              _customStartDate = DateTime(now.year, now.month, 1);
              _customEndDate = now;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateRangePicker() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(isStart: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _customStartDate != null
                        ? dateFormat.format(_customStartDate!)
                        : 'Select date',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(isStart: false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'To',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _customEndDate != null
                        ? dateFormat.format(_customEndDate!)
                        : 'Select date',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    switch (_dateRangeOption) {
      case DateRangeOption.currentMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case DateRangeOption.lastThreeMonths:
        return (
          DateTime(now.year, now.month - 2, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case DateRangeOption.lastSixMonths:
        return (
          DateTime(now.year, now.month - 5, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case DateRangeOption.lastYear:
        return (
          DateTime(now.year - 1, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case DateRangeOption.custom:
        return (
          _customStartDate ?? DateTime(now.year, now.month, 1),
          _customEndDate ?? now,
        );
    }
  }

  Widget _buildSummaryCards() {
    final (startDate, endDate) = _getDateRange();
    final entries =
        DatabaseService.getLedgerEntriesByDateRange(startDate, endDate);

    double total = 0;
    double received = 0;
    double balance = 0;

    for (final entry in entries) {
      total += entry.total;
      received += entry.received;
      balance += entry.balance;
    }

    final format = NumberFormat('#,##0.00');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total',
                value: '₹${format.format(total)}',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Entries',
                value: entries.length.toString(),
                icon: Icons.receipt_long_outlined,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Received',
                value: '₹${format.format(received)}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Pending',
                value: '₹${format.format(balance)}',
                icon: Icons.pending_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartSection() {
    final (startDate, endDate) = _getDateRange();
    final agentTotals = DatabaseService.getAgentWiseTotals(
      startDate: startDate,
      endDate: endDate,
    );

    if (agentTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'No data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add ledger entries to see statistics',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = agentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedEntries.fold<double>(0, (sum, e) => sum + e.value);
    final format = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Agent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: List.generate(sortedEntries.length, (index) {
                  final entry = sortedEntries[index];
                  final isTouched = index == _touchedIndex;
                  final percentage = (entry.value / total * 100);

                  return PieChartSectionData(
                    color: AppColors
                        .chartColors[index % AppColors.chartColors.length],
                    value: entry.value,
                    title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                    radius: isTouched ? 60 : 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          ...sortedEntries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final percentage = (entry.value / total * 100);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors
                          .chartColors[index % AppColors.chartColors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '₹${format.format(entry.value)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
