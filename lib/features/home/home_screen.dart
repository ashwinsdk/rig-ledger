import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import 'widgets/ledger_list.dart';
import 'widgets/calendar_view.dart';
import 'widgets/summary_row.dart';
import 'widgets/search_sheet.dart';
import 'widgets/filter_sheet.dart';
import '../ledger_form/ledger_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final isDailyView = ref.watch(isDailyViewProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final timePeriod = ref.watch(timePeriodProvider);

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
                              Consumer(
                                builder: (context, ref, child) {
                                  final currentVehicle =
                                      ref.watch(currentVehicleProvider);
                                  if (currentVehicle == null)
                                    return const SizedBox.shrink();
                                  return Text(
                                    currentVehicle.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
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

                  // Search indicator if active
                  if (searchQuery.isNotEmpty)
                    Container(
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
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                            child: const Icon(Icons.close,
                                color: Colors.white70, size: 16),
                          ),
                        ],
                      ),
                    ),

                  // Time Period Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _buildPeriodChip(
                            ref, 'Month', TimePeriod.month, timePeriod),
                        _buildPeriodChip(ref, '3 Months',
                            TimePeriod.threeMonths, timePeriod),
                        _buildPeriodChip(
                            ref, '6 Months', TimePeriod.sixMonths, timePeriod),
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
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white),
                            onPressed: () {
                              ref.read(selectedMonthProvider.notifier).state =
                                  DateTime(
                                selectedMonth.year,
                                selectedMonth.month - 1,
                              );
                            },
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(selectedMonth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white),
                            onPressed: () {
                              ref.read(selectedMonthProvider.notifier).state =
                                  DateTime(
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
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white),
                            onPressed: () {
                              ref.read(selectedYearProvider.notifier).state =
                                  selectedYear - 1;
                            },
                          ),
                          Text(
                            selectedYear.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white),
                            onPressed: () {
                              ref.read(selectedYearProvider.notifier).state =
                                  selectedYear + 1;
                            },
                          ),
                        ],
                      ),
                    ),

                  // View Toggle
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref.read(isDailyViewProvider.notifier).state =
                                  true;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isDailyView
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
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
                              ref.read(isDailyViewProvider.notifier).state =
                                  false;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isDailyView
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Summary Row
          const SummaryRow(),

          // Content
          Expanded(
            child:
                isDailyView ? const LedgerList() : const CalendarViewWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddLedgerForm(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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

  void _openAddLedgerForm(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LedgerFormScreen(),
      ),
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
}
