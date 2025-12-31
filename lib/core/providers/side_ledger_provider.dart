import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/diesel_entry.dart';
import '../models/pvc_entry.dart';
import '../models/bit_entry.dart';
import '../models/hammer_entry.dart';

// ============ DIESEL PROVIDERS ============

class DieselEntriesNotifier extends StateNotifier<List<DieselEntry>> {
  DieselEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    final vehicleId = DatabaseService.currentVehicleId;
    state = DatabaseService.getDieselEntriesByVehicle(vehicleId);
  }

  Future<void> addEntry(DieselEntry entry) async {
    await DatabaseService.saveDieselEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(DieselEntry entry) async {
    await DatabaseService.saveDieselEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteDieselEntry(id);
    loadEntries();
  }

  void refresh() {
    loadEntries();
  }
}

final dieselEntriesProvider =
    StateNotifierProvider<DieselEntriesNotifier, List<DieselEntry>>((ref) {
  return DieselEntriesNotifier();
});

// Diesel filter state
class DieselFilter {
  final String? bunk;
  final DateTime? startDate;
  final DateTime? endDate;

  const DieselFilter({this.bunk, this.startDate, this.endDate});

  bool get hasFilters => bunk != null || startDate != null || endDate != null;

  DieselFilter copyWith({
    String? bunk,
    DateTime? startDate,
    DateTime? endDate,
    bool clearBunk = false,
    bool clearDates = false,
  }) {
    return DieselFilter(
      bunk: clearBunk ? null : (bunk ?? this.bunk),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  DieselFilter clear() => const DieselFilter();
}

final dieselFilterProvider =
    StateProvider<DieselFilter>((ref) => const DieselFilter());

// ============ PVC PROVIDERS ============

class PvcEntriesNotifier extends StateNotifier<List<PvcEntry>> {
  PvcEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    final vehicleId = DatabaseService.currentVehicleId;
    state = DatabaseService.getPvcEntriesByVehicle(vehicleId);
  }

  Future<void> addEntry(PvcEntry entry) async {
    await DatabaseService.savePvcEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(PvcEntry entry) async {
    await DatabaseService.savePvcEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deletePvcEntry(id);
    loadEntries();
  }

  void refresh() {
    loadEntries();
  }
}

final pvcEntriesProvider =
    StateNotifierProvider<PvcEntriesNotifier, List<PvcEntry>>((ref) {
  return PvcEntriesNotifier();
});

// PVC filter state
class PvcFilter {
  final String? type;
  final String? storagePlace;
  final DateTime? startDate;
  final DateTime? endDate;

  const PvcFilter({this.type, this.storagePlace, this.startDate, this.endDate});

  bool get hasFilters =>
      type != null ||
      storagePlace != null ||
      startDate != null ||
      endDate != null;

  PvcFilter copyWith({
    String? type,
    String? storagePlace,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearStoragePlace = false,
    bool clearDates = false,
  }) {
    return PvcFilter(
      type: clearType ? null : (type ?? this.type),
      storagePlace:
          clearStoragePlace ? null : (storagePlace ?? this.storagePlace),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  PvcFilter clear() => const PvcFilter();
}

final pvcFilterProvider = StateProvider<PvcFilter>((ref) => const PvcFilter());

// ============ BIT PROVIDERS ============

class BitEntriesNotifier extends StateNotifier<List<BitEntry>> {
  BitEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    final vehicleId = DatabaseService.currentVehicleId;
    state = DatabaseService.getBitEntriesByVehicle(vehicleId);
  }

  Future<void> addEntry(BitEntry entry) async {
    await DatabaseService.saveBitEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(BitEntry entry) async {
    await DatabaseService.saveBitEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteBitEntry(id);
    loadEntries();
  }

  void refresh() {
    loadEntries();
  }
}

final bitEntriesProvider =
    StateNotifierProvider<BitEntriesNotifier, List<BitEntry>>((ref) {
  return BitEntriesNotifier();
});

// Bit filter state
class BitFilter {
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;

  const BitFilter({this.type, this.startDate, this.endDate});

  bool get hasFilters => type != null || startDate != null || endDate != null;

  BitFilter copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return BitFilter(
      type: clearType ? null : (type ?? this.type),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  BitFilter clear() => const BitFilter();
}

final bitFilterProvider = StateProvider<BitFilter>((ref) => const BitFilter());

// ============ HAMMER PROVIDERS ============

class HammerEntriesNotifier extends StateNotifier<List<HammerEntry>> {
  HammerEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    final vehicleId = DatabaseService.currentVehicleId;
    state = DatabaseService.getHammerEntriesByVehicle(vehicleId);
  }

  Future<void> addEntry(HammerEntry entry) async {
    await DatabaseService.saveHammerEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(HammerEntry entry) async {
    await DatabaseService.saveHammerEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteHammerEntry(id);
    loadEntries();
  }

  void refresh() {
    loadEntries();
  }
}

final hammerEntriesProvider =
    StateNotifierProvider<HammerEntriesNotifier, List<HammerEntry>>((ref) {
  return HammerEntriesNotifier();
});

// Hammer filter state
class HammerFilter {
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;

  const HammerFilter({this.type, this.startDate, this.endDate});

  bool get hasFilters => type != null || startDate != null || endDate != null;

  HammerFilter copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return HammerFilter(
      type: clearType ? null : (type ?? this.type),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  HammerFilter clear() => const HammerFilter();
}

final hammerFilterProvider =
    StateProvider<HammerFilter>((ref) => const HammerFilter());

// ============ COMMON TIME PERIOD PROVIDERS ============

/// Time period for side ledger views
final sideLedgerTimePeriodProvider =
    StateProvider<SideLedgerTimePeriod>((ref) => SideLedgerTimePeriod.month);

enum SideLedgerTimePeriod {
  month,
  threeMonths,
  sixMonths,
  year,
  all,
}

/// Selected month for side ledger
final sideLedgerSelectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Selected year for side ledger
final sideLedgerSelectedYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});
