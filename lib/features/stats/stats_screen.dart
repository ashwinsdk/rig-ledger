import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/side_ledger_provider.dart';
import '../../core/providers/vehicle_provider.dart';

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

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  DateRangeOption _dateRangeOption = DateRangeOption.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _touchedIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all entry providers - this ensures rebuild when data changes
    // ignore: unused_local_variable
    final _ = (
      ref.watch(ledgerEntriesProvider),
      ref.watch(dieselEntriesProvider),
      ref.watch(pvcEntriesProvider),
      ref.watch(bitEntriesProvider),
      ref.watch(hammerEntriesProvider),
    );
    final currentVehicle = ref.watch(currentVehicleProvider);

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
                    if (currentVehicle != null)
                      Text(
                        currentVehicle.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Ledger'),
                          Tab(text: 'Side Ledger'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                // Ledger Stats Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_dateRangeOption == DateRangeOption.custom)
                        _buildCustomDateRangePicker(),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPieChartSection(),
                    ],
                  ),
                ),
                // Side Ledger Stats Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_dateRangeOption == DateRangeOption.custom)
                        _buildCustomDateRangePicker(),
                      // 4 Pie Charts in 2x2 Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDieselPieChart()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPvcPieChart()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBitPieChart()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildHammerPieChart()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Detailed Stats Cards
                      const Text(
                        'Detailed Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDieselStats(),
                      const SizedBox(height: 16),
                      _buildPvcStats(),
                      const SizedBox(height: 16),
                      _buildBitStats(),
                      const SizedBox(height: 16),
                      _buildHammerStats(),
                    ],
                  ),
                ),
              ],
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
    // Helper to get end of day (23:59:59.999)
    DateTime endOfDay(DateTime date) =>
        DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    switch (_dateRangeOption) {
      case DateRangeOption.currentMonth:
        // Last day of current month at end of day
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        return (
          DateTime(now.year, now.month, 1),
          endOfDay(lastDayOfMonth),
        );
      case DateRangeOption.lastThreeMonths:
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        return (
          DateTime(now.year, now.month - 2, 1),
          endOfDay(lastDayOfMonth),
        );
      case DateRangeOption.lastSixMonths:
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        return (
          DateTime(now.year, now.month - 5, 1),
          endOfDay(lastDayOfMonth),
        );
      case DateRangeOption.lastYear:
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        return (
          DateTime(now.year - 1, now.month, 1),
          endOfDay(lastDayOfMonth),
        );
      case DateRangeOption.custom:
        return (
          _customStartDate ?? DateTime(now.year, now.month, 1),
          _customEndDate != null ? endOfDay(_customEndDate!) : endOfDay(now),
        );
    }
  }

  /// Filter entries by date range from provider data
  List<T> _filterByDateRange<T>(List<T> entries, DateTime startDate,
      DateTime endDate, DateTime Function(T) getDate) {
    return entries.where((entry) {
      final date = getDate(entry);
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();
  }

  Widget _buildSummaryCards() {
    final (startDate, endDate) = _getDateRange();
    // Use provider data with watch for reactivity
    final allEntries = ref.watch(ledgerEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

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
    // Use provider for reactivity and calculate agent totals
    final allEntries = ref.watch(ledgerEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    // Calculate agent-wise totals from filtered entries
    final Map<String, double> agentTotals = {};
    for (final entry in entries) {
      agentTotals[entry.agentName] =
          (agentTotals[entry.agentName] ?? 0) + entry.total;
    }

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

  // ============ SIDE LEDGER STATS ============

  // ============ PIE CHARTS FOR SIDE LEDGER ============

  Widget _buildDieselPieChart() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(dieselEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildMiniEmptyChart(
          'Diesel', Icons.local_gas_station, AppColors.warning);
    }

    double totalPaid = 0;
    double totalPending = 0;
    for (final e in entries) {
      totalPaid += e.paid;
      totalPending += e.pending;
    }

    return _buildMiniPieChart(
      title: 'Diesel',
      icon: Icons.local_gas_station,
      color: AppColors.warning,
      paid: totalPaid,
      pending: totalPending,
    );
  }

  Widget _buildPvcPieChart() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(pvcEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildMiniEmptyChart('PVC', Icons.view_column, AppColors.primary);
    }

    double totalPaid = 0;
    double totalPending = 0;
    for (final e in entries) {
      totalPaid += e.paid;
      totalPending += e.pending;
    }

    return _buildMiniPieChart(
      title: 'PVC',
      icon: Icons.view_column,
      color: AppColors.primary,
      paid: totalPaid,
      pending: totalPending,
    );
  }

  Widget _buildBitPieChart() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(bitEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildMiniEmptyChart(
          'Bit', Icons.circle_outlined, AppColors.success);
    }

    double totalPaid = 0;
    double totalPending = 0;
    for (final e in entries) {
      totalPaid += e.paid;
      totalPending += e.pending;
    }

    return _buildMiniPieChart(
      title: 'Bit',
      icon: Icons.circle_outlined,
      color: AppColors.success,
      paid: totalPaid,
      pending: totalPending,
    );
  }

  Widget _buildHammerPieChart() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(hammerEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildMiniEmptyChart('Hammer', Icons.hardware, AppColors.error);
    }

    double totalPaid = 0;
    double totalPending = 0;
    for (final e in entries) {
      totalPaid += e.paid;
      totalPending += e.pending;
    }

    return _buildMiniPieChart(
      title: 'Hammer',
      icon: Icons.hardware,
      color: AppColors.error,
      paid: totalPaid,
      pending: totalPending,
    );
  }

  Widget _buildMiniEmptyChart(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPieChart({
    required String title,
    required IconData icon,
    required Color color,
    required double paid,
    required double pending,
  }) {
    final total = paid + pending;
    final paidPercent = total > 0 ? (paid / total * 100) : 0;
    final pendingPercent = total > 0 ? (pending / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: PieChart(
              PieChartData(
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(
                    color: AppColors.success,
                    value: paid,
                    title: '',
                    radius: 18,
                  ),
                  PieChartSectionData(
                    color: AppColors.warning,
                    value: pending,
                    title: '',
                    radius: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${paidPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Due',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${pendingPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDieselStats() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(dieselEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildEmptyStatsCard(
        'Diesel',
        Icons.local_gas_station,
        AppColors.primary,
      );
    }

    double totalAmount = 0;
    double totalLitres = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (final entry in entries) {
      totalAmount += entry.total;
      totalLitres += entry.litre;
      totalPaid += entry.paid;
      totalPending += entry.pending;
    }

    final avgRate = totalLitres > 0 ? totalAmount / totalLitres : 0.0;
    final format = NumberFormat('#,##0.00');

    return _buildStatsCard(
      title: 'Diesel',
      icon: Icons.local_gas_station,
      color: AppColors.primary,
      entries: entries.length,
      stats: [
        _StatRow(
            label: 'Total Litres', value: '${format.format(totalLitres)} L'),
        _StatRow(
            label: 'Total Amount', value: '₹${format.format(totalAmount)}'),
        _StatRow(label: 'Avg Rate', value: '₹${format.format(avgRate)}/L'),
        _StatRow(
            label: 'Paid',
            value: '₹${format.format(totalPaid)}',
            color: AppColors.success),
        _StatRow(
            label: 'Pending',
            value: '₹${format.format(totalPending)}',
            color: AppColors.warning),
      ],
    );
  }

  Widget _buildPvcStats() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(pvcEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildEmptyStatsCard(
        'PVC',
        Icons.view_column,
        AppColors.accent,
      );
    }

    // Count by type (support multi-select types)
    final Map<String, int> typeCounts = {};
    double totalAmount = 0;
    double totalPaid = 0;
    double totalPending = 0;
    int totalCount = 0;

    for (final entry in entries) {
      // Use types list if available, otherwise fallback to single type
      final typesList = entry.types ?? [entry.type];
      for (final type in typesList) {
        typeCounts[type] = (typeCounts[type] ?? 0) + entry.count;
      }
      totalAmount += entry.total;
      totalPaid += entry.paid;
      totalPending += entry.pending;
      totalCount += entry.count;
    }

    final format = NumberFormat('#,##0.00');
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsCard(
      title: 'PVC',
      icon: Icons.view_column,
      color: AppColors.accent,
      entries: entries.length,
      stats: [
        _StatRow(label: 'Total Count', value: '$totalCount pcs'),
        ...sortedTypes
            .map((e) => _StatRow(label: e.key, value: '${e.value} pcs')),
        _StatRow(label: 'Total Value', value: '₹${format.format(totalAmount)}'),
        _StatRow(
            label: 'Paid',
            value: '₹${format.format(totalPaid)}',
            color: AppColors.success),
        _StatRow(
            label: 'Pending',
            value: '₹${format.format(totalPending)}',
            color: AppColors.warning),
      ],
    );
  }

  Widget _buildBitStats() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(bitEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildEmptyStatsCard(
        'Bit',
        Icons.circle_outlined,
        AppColors.success,
      );
    }

    // Count by type (support multi-select types)
    final Map<String, int> typeCounts = {};
    double totalAmount = 0;
    double totalPaid = 0;
    double totalPending = 0;
    int totalCount = 0;

    for (final entry in entries) {
      // Use types list if available, otherwise fallback to single type
      final typesList = entry.types ?? [entry.type];
      for (final type in typesList) {
        typeCounts[type] = (typeCounts[type] ?? 0) + entry.count;
      }
      totalAmount += entry.total;
      totalPaid += entry.paid;
      totalPending += entry.pending;
      totalCount += entry.count;
    }

    final format = NumberFormat('#,##0.00');
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsCard(
      title: 'Bit',
      icon: Icons.circle_outlined,
      color: AppColors.success,
      entries: entries.length,
      stats: [
        _StatRow(label: 'Total Count', value: '$totalCount pcs'),
        ...sortedTypes
            .map((e) => _StatRow(label: e.key, value: '${e.value} pcs')),
        _StatRow(label: 'Total Value', value: '₹${format.format(totalAmount)}'),
        _StatRow(
            label: 'Paid',
            value: '₹${format.format(totalPaid)}',
            color: AppColors.success),
        _StatRow(
            label: 'Pending',
            value: '₹${format.format(totalPending)}',
            color: AppColors.warning),
      ],
    );
  }

  Widget _buildHammerStats() {
    final (startDate, endDate) = _getDateRange();
    // Use provider for reactivity
    final allEntries = ref.watch(hammerEntriesProvider);
    final entries =
        _filterByDateRange(allEntries, startDate, endDate, (e) => e.date);

    if (entries.isEmpty) {
      return _buildEmptyStatsCard(
        'Hammer',
        Icons.hardware,
        AppColors.error,
      );
    }

    // Count by type (support multi-select types)
    final Map<String, int> typeCounts = {};
    double totalAmount = 0;
    double totalPaid = 0;
    double totalPending = 0;
    int totalCount = 0;

    for (final entry in entries) {
      // Use types list if available, otherwise fallback to single type
      final typesList = entry.types ?? [entry.type];
      for (final type in typesList) {
        typeCounts[type] = (typeCounts[type] ?? 0) + entry.count;
      }
      totalAmount += entry.total;
      totalPaid += entry.paid;
      totalPending += entry.pending;
      totalCount += entry.count;
    }

    final format = NumberFormat('#,##0.00');
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsCard(
      title: 'Hammer',
      icon: Icons.hardware,
      color: AppColors.error,
      entries: entries.length,
      stats: [
        _StatRow(label: 'Total Count', value: '$totalCount pcs'),
        ...sortedTypes
            .map((e) => _StatRow(label: e.key, value: '${e.value} pcs')),
        _StatRow(label: 'Total Value', value: '₹${format.format(totalAmount)}'),
        _StatRow(
            label: 'Paid',
            value: '₹${format.format(totalPaid)}',
            color: AppColors.success),
        _StatRow(
            label: 'Pending',
            value: '₹${format.format(totalPending)}',
            color: AppColors.warning),
      ],
    );
  }

  Widget _buildEmptyStatsCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No entries in selected period',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required Color color,
    required int entries,
    required List<_StatRow> stats,
  }) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$entries entries',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...stats.map((stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: stat.color ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
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

class _StatRow {
  final String label;
  final String value;
  final Color? color;

  const _StatRow({
    required this.label,
    required this.value,
    this.color,
  });
}
