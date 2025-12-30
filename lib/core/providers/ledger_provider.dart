import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/ledger_entry.dart';

const _uuid = Uuid();

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

  const LedgerFilter({
    this.billNumber,
    this.address,
    this.agentId,
  });

  bool get hasFilters =>
      billNumber != null || address != null || agentId != null;

  LedgerFilter copyWith({
    String? billNumber,
    String? address,
    String? agentId,
    bool clearBillNumber = false,
    bool clearAddress = false,
    bool clearAgentId = false,
  }) {
    return LedgerFilter(
      billNumber: clearBillNumber ? null : (billNumber ?? this.billNumber),
      address: clearAddress ? null : (address ?? this.address),
      agentId: clearAgentId ? null : (agentId ?? this.agentId),
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

/// Filtered entries for current month
final filteredLedgerEntriesProvider = Provider<List<LedgerEntry>>((ref) {
  final entries = ref.watch(ledgerEntriesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final filter = ref.watch(ledgerFilterProvider);

  var filtered = entries.where((entry) {
    return entry.date.year == selectedMonth.year &&
        entry.date.month == selectedMonth.month;
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
