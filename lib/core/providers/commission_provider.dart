import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/commission_entry.dart';

const _uuid = Uuid();

/// Commission entries notifier
class CommissionEntriesNotifier extends StateNotifier<List<CommissionEntry>> {
  CommissionEntriesNotifier() : super([]) {
    loadEntries();
  }

  void loadEntries() {
    state = DatabaseService.getAllCommissionEntries();
  }

  Future<void> addEntry({
    required String agentId,
    required String agentName,
    required DateTime startDate,
    required DateTime endDate,
    required double amount,
    String? notes,
    bool isPaid = false,
  }) async {
    final entry = CommissionEntry(
      id: _uuid.v4(),
      agentId: agentId,
      agentName: agentName,
      startDate: startDate,
      endDate: endDate,
      amount: amount,
      notes: notes,
      createdAt: DateTime.now(),
      vehicleId: DatabaseService.currentVehicleId,
      isPaid: isPaid,
    );
    await DatabaseService.saveCommissionEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(CommissionEntry entry) async {
    await DatabaseService.saveCommissionEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteCommissionEntry(id);
    loadEntries();
  }

  Future<void> togglePaid(String id) async {
    final entry = DatabaseService.getCommissionEntry(id);
    if (entry != null) {
      final updated = entry.copyWith(isPaid: !entry.isPaid);
      await DatabaseService.saveCommissionEntry(updated);
      loadEntries();
    }
  }

  void refresh() {
    loadEntries();
  }
}

/// Commission entries provider
final commissionEntriesProvider =
    StateNotifierProvider<CommissionEntriesNotifier, List<CommissionEntry>>((ref) {
  return CommissionEntriesNotifier();
});

/// Commission entries for a specific agent
final agentCommissionEntriesProvider = Provider.family<List<CommissionEntry>, String>((ref, agentId) {
  final allEntries = ref.watch(commissionEntriesProvider);
  return allEntries.where((e) => e.agentId == agentId).toList();
});

/// Total commission for an agent
final agentTotalCommissionProvider = Provider.family<double, String>((ref, agentId) {
  final entries = ref.watch(agentCommissionEntriesProvider(agentId));
  return entries.fold<double>(0, (sum, entry) => sum + entry.amount);
});

/// Paid commission for an agent
final agentPaidCommissionProvider = Provider.family<double, String>((ref, agentId) {
  final entries = ref.watch(agentCommissionEntriesProvider(agentId));
  return entries.where((e) => e.isPaid).fold<double>(0, (sum, entry) => sum + entry.amount);
});

/// Pending commission for an agent
final agentPendingCommissionProvider = Provider.family<double, String>((ref, agentId) {
  final entries = ref.watch(agentCommissionEntriesProvider(agentId));
  return entries.where((e) => !e.isPaid).fold<double>(0, (sum, entry) => sum + entry.amount);
});

/// Total commission across all agents (for summary)
final totalCommissionAmountProvider = Provider<double>((ref) {
  final entries = ref.watch(commissionEntriesProvider);
  return entries.fold<double>(0, (sum, entry) => sum + entry.amount);
});

/// Total paid commission
final totalPaidCommissionProvider = Provider<double>((ref) {
  final entries = ref.watch(commissionEntriesProvider);
  return entries.where((e) => e.isPaid).fold<double>(0, (sum, entry) => sum + entry.amount);
});

/// Total pending commission
final totalPendingCommissionProvider = Provider<double>((ref) {
  final entries = ref.watch(commissionEntriesProvider);
  return entries.where((e) => !e.isPaid).fold<double>(0, (sum, entry) => sum + entry.amount);
});
