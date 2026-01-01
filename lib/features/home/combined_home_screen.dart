import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/side_ledger_provider.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/models/diesel_entry.dart';
import '../../core/models/pvc_entry.dart';
import '../../core/models/bit_entry.dart';
import '../../core/models/hammer_entry.dart';
import '../../core/models/vehicle.dart';
import 'widgets/ledger_list.dart';
import 'widgets/calendar_view.dart';
import 'widgets/summary_row.dart';
import 'widgets/search_sheet.dart';
import 'widgets/filter_sheet.dart';
import '../side_ledger/diesel/diesel_list_screen.dart';
import '../side_ledger/pvc/pvc_list_screen.dart';
import '../side_ledger/bit/bit_list_screen.dart';
import '../side_ledger/hammer/hammer_list_screen.dart';
import '../navigation/main_navigation.dart';

class CombinedHomeScreen extends ConsumerStatefulWidget {
  const CombinedHomeScreen({super.key});

  @override
  ConsumerState<CombinedHomeScreen> createState() => _CombinedHomeScreenState();
}

class _CombinedHomeScreenState extends ConsumerState<CombinedHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(homeTabIndexProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final isDailyView = ref.watch(isDailyViewProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final timePeriod = ref.watch(timePeriodProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient App Bar
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar Row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () => _showSearchSheet(context),
                          tooltip: 'Search',
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showVehicleSwitcher(context, ref),
                            child: Column(
                              children: [
                                const Text(
                                  'RigLedger',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (currentVehicle != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        currentVehicle.vehicleType ==
                                                VehicleType.mainBore
                                            ? Icons.precision_manufacturing
                                            : Icons.construction,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        currentVehicle.name,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.filter_list,
                                  color: Colors.white),
                              onPressed: () => _showFilterSheet(context, ref),
                              tooltip: 'Filter',
                            ),
                            if (filter.hasFilters)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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

                  // Search indicator if active (only for Ledger tab)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      if (_tabController.index == 0 && searchQuery.isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Searching: "$searchQuery"',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                },
                                child: const Icon(Icons.close,
                                    color: Colors.white70, size: 16),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Time Period & Controls (only for Ledger tab)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      if (_tabController.index == 0) {
                        return Column(
                          children: [
                            // Time Period Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Row(
                                children: [
                                  _buildPeriodChip(ref, 'Month',
                                      TimePeriod.month, timePeriod),
                                  _buildPeriodChip(ref, '3 Mo',
                                      TimePeriod.threeMonths, timePeriod),
                                  _buildPeriodChip(ref, '6 Mo',
                                      TimePeriod.sixMonths, timePeriod),
                                  _buildPeriodChip(
                                      ref, 'Year', TimePeriod.year, timePeriod),
                                  _buildPeriodChip(
                                      ref, 'All', TimePeriod.all, timePeriod),
                                ],
                              ),
                            ),

                            // Month Navigation Row (only show for month view)
                            if (timePeriod == TimePeriod.month)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(
                                                selectedMonthProvider.notifier)
                                            .state = DateTime(
                                          selectedMonth.year,
                                          selectedMonth.month - 1,
                                        );
                                      },
                                    ),
                                    Text(
                                      DateFormat('MMMM yyyy')
                                          .format(selectedMonth),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(
                                                selectedMonthProvider.notifier)
                                            .state = DateTime(
                                          selectedMonth.year,
                                          selectedMonth.month + 1,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            // Year Navigation Row (only show for year view)
                            if (timePeriod == TimePeriod.year)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(selectedYearProvider.notifier)
                                            .state = selectedYear - 1;
                                      },
                                    ),
                                    Text(
                                      selectedYear.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(selectedYearProvider.notifier)
                                            .state = selectedYear + 1;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            // View Toggle
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(isDailyViewProvider.notifier)
                                            .state = true;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isDailyView
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Daily',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isDailyView
                                                ? AppColors.primary
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(isDailyViewProvider.notifier)
                                            .state = false;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !isDailyView
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Calendar',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !isDailyView
                                                ? AppColors.primary
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox(height: 12);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Ledger Tab
                Column(
                  children: [
                    const SummaryRow(),
                    Expanded(
                      child: isDailyView
                          ? const LedgerList()
                          : const CalendarViewWidget(),
                    ),
                  ],
                ),
                // Side Ledger Tab
                _buildSideLedgerContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideLedgerContent() {
    final sideLedgerTimePeriod = ref.watch(sideLedgerTimePeriodProvider);
    final sideLedgerSelectedMonth = ref.watch(sideLedgerSelectedMonthProvider);
    final sideLedgerSelectedYear = ref.watch(sideLedgerSelectedYearProvider);

    // Get all entries
    final allDieselEntries = ref.watch(dieselEntriesProvider);
    final allPvcEntries = ref.watch(pvcEntriesProvider);
    final allBitEntries = ref.watch(bitEntriesProvider);
    final allHammerEntries = ref.watch(hammerEntriesProvider);

    // Filter entries based on time period
    final dieselEntries = _filterByTimePeriod(allDieselEntries,
        sideLedgerTimePeriod, sideLedgerSelectedMonth, sideLedgerSelectedYear);
    final pvcEntries = _filterByTimePeriod(allPvcEntries, sideLedgerTimePeriod,
        sideLedgerSelectedMonth, sideLedgerSelectedYear);
    final bitEntries = _filterByTimePeriod(allBitEntries, sideLedgerTimePeriod,
        sideLedgerSelectedMonth, sideLedgerSelectedYear);
    final hammerEntries = _filterByTimePeriod(allHammerEntries,
        sideLedgerTimePeriod, sideLedgerSelectedMonth, sideLedgerSelectedYear);

    // Calculate totals
    final format = NumberFormat('#,##0.00');
    const Color hammerColor = Color(0xFF8B4513); // Brown color for hammer

    double dieselTotal = 0;
    double dieselPending = 0;
    double dieselLitres = 0;
    for (final e in dieselEntries) {
      dieselTotal += e.total;
      dieselPending += e.pending;
      dieselLitres += e.litre;
    }

    double pvcTotal = 0;
    double pvcPending = 0;
    int pvcCount = 0;
    for (final e in pvcEntries) {
      pvcTotal += e.total;
      pvcPending += e.pending;
      pvcCount += e.count;
    }

    double bitTotal = 0;
    double bitPending = 0;
    int bitCount = 0;
    for (final e in bitEntries) {
      bitTotal += e.total;
      bitPending += e.pending;
      bitCount += e.count;
    }

    double hammerTotal = 0;
    double hammerPending = 0;
    int hammerCount = 0;
    for (final e in hammerEntries) {
      hammerTotal += e.total;
      hammerPending += e.pending;
      hammerCount += e.count;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Time Period Chips for Side Ledger
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSideLedgerPeriodChip(ref, 'Month',
                      SideLedgerTimePeriod.month, sideLedgerTimePeriod),
                  _buildSideLedgerPeriodChip(ref, '3 Mo',
                      SideLedgerTimePeriod.threeMonths, sideLedgerTimePeriod),
                  _buildSideLedgerPeriodChip(ref, '6 Mo',
                      SideLedgerTimePeriod.sixMonths, sideLedgerTimePeriod),
                  _buildSideLedgerPeriodChip(ref, 'Year',
                      SideLedgerTimePeriod.year, sideLedgerTimePeriod),
                  _buildSideLedgerPeriodChip(ref, 'All',
                      SideLedgerTimePeriod.all, sideLedgerTimePeriod),
                ],
              ),
            ),
          ),

          // Month/Year Navigation
          if (sideLedgerTimePeriod == SideLedgerTimePeriod.month)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(sideLedgerSelectedMonthProvider.notifier).state =
                          DateTime(
                        sideLedgerSelectedMonth.year,
                        sideLedgerSelectedMonth.month - 1,
                      );
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(sideLedgerSelectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref.read(sideLedgerSelectedMonthProvider.notifier).state =
                          DateTime(
                        sideLedgerSelectedMonth.year,
                        sideLedgerSelectedMonth.month + 1,
                      );
                    },
                  ),
                ],
              ),
            ),

          if (sideLedgerTimePeriod == SideLedgerTimePeriod.year)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(sideLedgerSelectedYearProvider.notifier).state =
                          sideLedgerSelectedYear - 1;
                    },
                  ),
                  Text(
                    sideLedgerSelectedYear.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref.read(sideLedgerSelectedYearProvider.notifier).state =
                          sideLedgerSelectedYear + 1;
                    },
                  ),
                ],
              ),
            ),

          // Stats Summary Row with detailed totals
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStatDouble(
                        'Diesel',
                        '${format.format(dieselLitres)} L',
                        '₹${format.format(dieselTotal)}',
                        AppColors.warning),
                    _buildMiniStatDouble('PVC', '$pvcCount pcs',
                        '₹${format.format(pvcTotal)}', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStatDouble('Bit', '$bitCount pcs',
                        '₹${format.format(bitTotal)}', AppColors.success),
                    _buildMiniStatDouble('Hammer', '$hammerCount pcs',
                        '₹${format.format(hammerTotal)}', hammerColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildCategoryCard(
                  'Diesel',
                  Icons.local_gas_station,
                  AppColors.warning,
                  '${dieselEntries.length} entries | ${format.format(dieselLitres)} L',
                  '₹${format.format(dieselTotal)}',
                  dieselPending > 0
                      ? '₹${format.format(dieselPending)} pending'
                      : null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DieselListScreen(),
                    ),
                  ),
                ),
                _buildCategoryCard(
                  'PVC',
                  Icons.plumbing,
                  AppColors.primary,
                  '$pvcCount pieces',
                  '₹${format.format(pvcTotal)}',
                  pvcPending > 0
                      ? '₹${format.format(pvcPending)} pending'
                      : null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PvcListScreen(),
                    ),
                  ),
                ),
                _buildCategoryCard(
                  'Bit',
                  Icons.circle_outlined,
                  AppColors.success,
                  '$bitCount pieces',
                  '₹${format.format(bitTotal)}',
                  bitPending > 0
                      ? '₹${format.format(bitPending)} pending'
                      : null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BitListScreen(),
                    ),
                  ),
                ),
                _buildCategoryCard(
                  'Hammer',
                  Icons.hardware,
                  hammerColor,
                  '$hammerCount pieces',
                  '₹${format.format(hammerTotal)}',
                  hammerPending > 0
                      ? '₹${format.format(hammerPending)} pending'
                      : null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HammerListScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatDouble(
      String label, String value1, String value2, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideLedgerPeriodChip(WidgetRef ref, String label,
      SideLedgerTimePeriod period, SideLedgerTimePeriod currentPeriod) {
    final isSelected = period == currentPeriod;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          ref.read(sideLedgerTimePeriodProvider.notifier).state = period;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  List<T> _filterByTimePeriod<T>(List<T> entries, SideLedgerTimePeriod period,
      DateTime selectedMonth, int selectedYear) {
    if (period == SideLedgerTimePeriod.all) return entries;

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case SideLedgerTimePeriod.month:
        startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
        endDate = DateTime(
            selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
        break;
      case SideLedgerTimePeriod.threeMonths:
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case SideLedgerTimePeriod.sixMonths:
        startDate = DateTime(now.year, now.month - 5, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case SideLedgerTimePeriod.year:
        startDate = DateTime(selectedYear, 1, 1);
        endDate = DateTime(selectedYear, 12, 31, 23, 59, 59);
        break;
      case SideLedgerTimePeriod.all:
        return entries;
    }

    return entries.where((entry) {
      final date = _getEntryDate(entry);
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();
  }

  DateTime _getEntryDate(dynamic entry) {
    if (entry is DieselEntry) return entry.date;
    if (entry is PvcEntry) return entry.date;
    if (entry is BitEntry) return entry.date;
    if (entry is HammerEntry) return entry.date;
    return DateTime.now();
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    String amount,
    String? pending,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (pending != null)
              Text(
                pending,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showVehicleSwitcher(BuildContext context, WidgetRef ref) {
    final vehicles = ref.read(vehiclesProvider);
    final currentVehicle = ref.read(currentVehicleProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Switch Vehicle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a vehicle to view its ledger',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No vehicles found'),
                ),
              )
            else
              ...vehicles.map((vehicle) {
                final isSelected = vehicle.id == currentVehicle?.id;
                final isSideBore = vehicle.vehicleType == VehicleType.sideBore;
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSideBore
                          ? Icons.engineering_outlined
                          : Icons.precision_manufacturing_outlined,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    vehicle.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  subtitle: Text(
                    isSideBore ? 'Side Bore' : 'Main Bore',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (!isSelected) {
                      await ref
                          .read(currentVehicleProvider.notifier)
                          .setCurrentVehicle(vehicle);
                      // Clear filters and search when changing vehicles
                      ref.read(searchQueryProvider.notifier).state = '';
                      ref.read(ledgerFilterProvider.notifier).state =
                          const LedgerFilter();
                      // Refresh all providers
                      ref.read(ledgerEntriesProvider.notifier).refresh();
                      ref.read(dieselEntriesProvider.notifier).refresh();
                      ref.read(pvcEntriesProvider.notifier).refresh();
                      ref.read(bitEntriesProvider.notifier).refresh();
                      ref.read(hammerEntriesProvider.notifier).refresh();
                      ref.read(agentsProvider.notifier).refresh();
                    }
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchSheet(),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterSheet(),
    );
  }

  Widget _buildPeriodChip(WidgetRef ref, String label, TimePeriod period,
      TimePeriod currentPeriod) {
    final isSelected = period == currentPeriod;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          ref.read(timePeriodProvider.notifier).state = period;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
