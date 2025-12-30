import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/ledger_entry.dart';

const _uuid = Uuid();

/// Time period filter options
enum TimePeriod {
  month, // Current selected month (default)
  threeMonths, // Last 3 months
  sixMonths, // Last 6 months
  year, // Last 12 months
  all, // All time
}

/// Current time period filter
final timePeriodProvider = StateProvider<TimePeriod>((ref) => TimePeriod.month);

/// Current selected month for filtering
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// View mode: true = daily view, false = calendar view
final isDailyViewProvider = StateProvider<bool>((ref) => true);

/// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filter state
class LedgerFilter {
  final String? billNumber;
  final String? address;
  final String? agentId;
  final String? depthType;
  final String? pvcType;

  const LedgerFilter({
    this.billNumber,
    this.address,
    this.agentId,
    this.depthType,
    this.pvcType,
  });

  bool get hasFilters =>
      billNumber != null ||
      address != null ||
      agentId != null ||
      depthType != null ||
      pvcType != null;

  LedgerFilter copyWith({
    String? billNumber,
    String? address,
    String? agentId,
    String? depthType,
    String? pvcType,
    bool clearBillNumber = false,
    bool clearAddress = false,
    bool clearAgentId = false,
    bool clearDepthType = false,
    bool clearPvcType = false,
  }) {
    return LedgerFilter(
      billNumber: clearBillNumber ? null : (billNumber ?? this.billNumber),
      address: clearAddress ? null : (address ?? this.address),
      agentId: clearAgentId ? null : (agentId ?? this.agentId),
      depthType: clearDepthType ? null : (depthType ?? this.depthType),
      pvcType: clearPvcType ? null : (pvcType ?? this.pvcType),
    );
  }

  LedgerFilter clear() {
    return const LedgerFilter();
  }
}

final ledgerFilterProvider =
    StateProvider<LedgerFilter>((ref) => const LedgerFilter());

/// Ledger entries notifier
class LedgerEntriesNotifier extends StateNotifier<List<LedgerEntry>> {
  LedgerEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    state = DatabaseService.getAllLedgerEntries();
  }

  Future<void> addEntry(LedgerEntry entry) async {
    await DatabaseService.saveLedgerEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(LedgerEntry entry) async {
    await DatabaseService.saveLedgerEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteLedgerEntry(id);
    loadEntries();
  }

  Future<void> importEntries(List<LedgerEntry> entries) async {
    for (final entry in entries) {
      await DatabaseService.saveLedgerEntry(entry);
    }
    loadEntries();
  }

  void refresh() {
    loadEntries();
  }
}

final ledgerEntriesProvider =
    StateNotifierProvider<LedgerEntriesNotifier, List<LedgerEntry>>((ref) {
  return LedgerEntriesNotifier();
});

/// Filtered entries based on time period
final filteredLedgerEntriesProvider = Provider<List<LedgerEntry>>((ref) {
  final entries = ref.watch(ledgerEntriesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final timePeriod = ref.watch(timePeriodProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final filter = ref.watch(ledgerFilterProvider);

  final now = DateTime.now();

  // Filter by time period
  var filtered = entries.where((entry) {
    switch (timePeriod) {
      case TimePeriod.month:
        return entry.date.year == selectedMonth.year &&
            entry.date.month == selectedMonth.month;
      case TimePeriod.threeMonths:
        final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
        return entry.date
            .isAfter(threeMonthsAgo.subtract(const Duration(days: 1)));
      case TimePeriod.sixMonths:
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
        return entry.date
            .isAfter(sixMonthsAgo.subtract(const Duration(days: 1)));
      case TimePeriod.year:
        final oneYearAgo = DateTime(now.year - 1, now.month, 1);
        return entry.date.isAfter(oneYearAgo.subtract(const Duration(days: 1)));
      case TimePeriod.all:
        return true;
    }
  }).toList();

  // Apply search
  if (searchQuery.isNotEmpty) {
    final lowerQuery = searchQuery.toLowerCase();
    filtered = filtered.where((entry) {
      return entry.billNumber.toLowerCase().contains(lowerQuery) ||
          entry.address.toLowerCase().contains(lowerQuery) ||
          entry.agentName.toLowerCase().contains(lowerQuery) ||
          (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Apply filters
  if (filter.billNumber != null && filter.billNumber!.isNotEmpty) {
    filtered = filtered.where((entry) {
      return entry.billNumber
          .toLowerCase()
          .contains(filter.billNumber!.toLowerCase());
    }).toList();
  }

  if (filter.address != null && filter.address!.isNotEmpty) {
    filtered = filtered.where((entry) {
      return entry.address
          .toLowerCase()
          .contains(filter.address!.toLowerCase());
    }).toList();
  }

  if (filter.agentId != null) {
    filtered =
        filtered.where((entry) => entry.agentId == filter.agentId).toList();
  }

  if (filter.depthType != null) {
    filtered =
        filtered.where((entry) => entry.depth == filter.depthType).toList();
  }

  if (filter.pvcType != null) {
    filtered = filtered.where((entry) => entry.pvc == filter.pvcType).toList();
  }

  // Sort by date descending
  filtered.sort((a, b) => b.date.compareTo(a.date));

  return filtered;
});

/// Entries grouped by date
final groupedLedgerEntriesProvider =
    Provider<Map<DateTime, List<LedgerEntry>>>((ref) {
  final entries = ref.watch(filteredLedgerEntriesProvider);

  final Map<DateTime, List<LedgerEntry>> grouped = {};
  for (final entry in entries) {
    final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
    grouped.putIfAbsent(dateKey, () => []).add(entry);
  }

  // Sort entries within each day
  for (final list in grouped.values) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return grouped;
});

/// Monthly summary stats
final monthlyStatsProvider = Provider<Map<String, double>>((ref) {
  final entries = ref.watch(filteredLedgerEntriesProvider);

  double total = 0;
  double received = 0;
  double balance = 0;

  for (final entry in entries) {
    total += entry.total;
    received += entry.received;
    balance += entry.balance;
  }

  return {
    'total': total,
    'received': received,
    'balance': balance,
  };
});

/// Feet totals by type for 7inch/8inch
final feetTotalsProvider = Provider<Map<String, double>>((ref) {
  final entries = ref.watch(filteredLedgerEntriesProvider);

  double depth7inch = 0;
  double depth8inch = 0;
  double pvc7inch = 0;
  double pvc8inch = 0;
  double msPipeTotal = 0;

  for (final entry in entries) {
    // Calculate depth feet by type
    if (entry.depth == '7inch') {
      depth7inch += entry.depthInFeet;
    } else if (entry.depth == '8inch') {
      depth8inch += entry.depthInFeet;
    }

    // Calculate PVC feet by type
    if (entry.pvc == '7inch') {
      pvc7inch += entry.pvcInFeet;
    } else if (entry.pvc == '8inch') {
      pvc8inch += entry.pvcInFeet;
    }

    // MS Pipe total
    msPipeTotal += entry.msPipeInFeet;
  }

  return {
    'depth7inch': depth7inch,
    'depth8inch': depth8inch,
    'pvc7inch': pvc7inch,
    'pvc8inch': pvc8inch,
    'msPipeTotal': msPipeTotal,
  };
});

/// Calendar day totals
final calendarDayTotalsProvider = Provider<Map<int, double>>((ref) {
  final entries = ref.watch(filteredLedgerEntriesProvider);

  final Map<int, double> dayTotals = {};
  for (final entry in entries) {
    final day = entry.date.day;
    dayTotals[day] = (dayTotals[day] ?? 0) + entry.total;
  }

  return dayTotals;
});

/// Generate new entry ID
String generateEntryId() => _uuid.v4();
