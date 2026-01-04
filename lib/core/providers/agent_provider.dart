import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/agent.dart';
import 'ledger_provider.dart';

const _uuid = Uuid();

/// Agents notifier
class AgentsNotifier extends StateNotifier<List<Agent>> {
  AgentsNotifier() : super([]) {
    loadAgents();
  }

  void loadAgents() {
    state = DatabaseService.getAllAgents();
  }

  Future<Agent> addAgent(String name, {String? phone, String? notes, double commissionPerBill = 0}) async {
    final agent = Agent(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      vehicleId: DatabaseService.currentVehicleId,
      commissionPerBill: commissionPerBill,
    );
    await DatabaseService.saveAgent(agent);
    loadAgents();
    return agent;
  }

  Future<void> updateAgent(Agent agent) async {
    final updated = agent.copyWith(updatedAt: DateTime.now());
    await DatabaseService.saveAgent(updated);

    // Update agent name in ledger entries
    await DatabaseService.updateAgentInLedgerEntries(agent.id, agent.name);

    loadAgents();
  }

  Future<void> deleteAgent(String id, {String? reassignToAgentId}) async {
    if (reassignToAgentId != null) {
      final targetAgent = DatabaseService.getAgent(reassignToAgentId);
      if (targetAgent != null) {
        await DatabaseService.reassignLedgerEntries(
            id, reassignToAgentId, targetAgent.name);
      }
    } else {
      await DatabaseService.deleteLedgerEntriesByAgent(id);
    }
    await DatabaseService.deleteAgent(id);
    loadAgents();
  }

  Agent? getAgentByName(String name) {
    return DatabaseService.getAgentByName(name);
  }

  Future<Agent> getOrCreateAgent(String name) async {
    var agent = DatabaseService.getAgentByName(name);
    if (agent == null) {
      agent = await addAgent(name);
    }
    return agent;
  }

  int getAgentBillCount(String agentId) {
    return DatabaseService.getAgentBillCount(agentId);
  }

  void refresh() {
    loadAgents();
  }
}

final agentsProvider =
    StateNotifierProvider<AgentsNotifier, List<Agent>>((ref) {
  return AgentsNotifier();
});

/// Agent bill counts - watches both agents and ledger entries for reactivity
final agentBillCountsProvider = Provider<Map<String, int>>((ref) {
  final agents = ref.watch(agentsProvider);
  // Watch ledger entries to trigger recalculation when entries change
  ref.watch(ledgerEntriesProvider);

  final Map<String, int> counts = {};
  for (final agent in agents) {
    counts[agent.id] = DatabaseService.getAgentBillCount(agent.id);
  }

  return counts;
});

/// Agent commission totals - calculates commission based on bill count and commission rate
final agentCommissionTotalsProvider = Provider<Map<String, double>>((ref) {
  final agents = ref.watch(agentsProvider);
  final billCounts = ref.watch(agentBillCountsProvider);

  final Map<String, double> commissions = {};
  for (final agent in agents) {
    final billCount = billCounts[agent.id] ?? 0;
    commissions[agent.id] = agent.commissionPerBill * billCount;
  }

  return commissions;
});

/// Total commission across all agents for current view
final totalCommissionProvider = Provider<double>((ref) {
  final agents = ref.watch(agentsProvider);
  final billCounts = ref.watch(agentBillCountsProvider);

  double total = 0;
  for (final agent in agents) {
    final billCount = billCounts[agent.id] ?? 0;
    total += agent.commissionPerBill * billCount;
  }

  return total;
});

/// Commission for filtered entries (based on current period/filters)
final filteredCommissionProvider = Provider<double>((ref) {
  final filteredEntries = ref.watch(filteredLedgerEntriesProvider);
  final agents = ref.watch(agentsProvider);

  // Create a map of agent id to commission rate
  final Map<String, double> agentCommissionRates = {};
  for (final agent in agents) {
    agentCommissionRates[agent.id] = agent.commissionPerBill;
  }

  // Calculate commission based on filtered entries
  double total = 0;
  for (final entry in filteredEntries) {
    final rate = agentCommissionRates[entry.agentId] ?? 0;
    total += rate;
  }

  return total;
});

/// Generate new agent ID
String generateAgentId() => _uuid.v4();
