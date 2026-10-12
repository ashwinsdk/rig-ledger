import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/agent.dart';
import '../services/payment_link_service.dart';
import 'cashbook_provider.dart';
import 'ledger_provider.dart';

const _uuid = Uuid();

/// Agents notifier
class AgentsNotifier extends StateNotifier<List<Agent>> {
  final Ref _ref;
  AgentsNotifier(this._ref) : super([]) {
    loadAgents();
  }

  void loadAgents() {
    state = DatabaseService.getAllAgents();
  }

  Future<Agent> addAgent(String name, {String? phone, String? notes}) async {
    final agent = Agent(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      vehicleId: DatabaseService.currentVehicleId,
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
      for (final bill in DatabaseService.getLedgerEntriesByAgent(id)) {
        await PaymentLinkService.onBillDeleted(bill.id);
      }
      await DatabaseService.deleteLedgerEntriesByAgent(id);
      _ref.read(cashEntriesProvider.notifier).refresh();
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
  return AgentsNotifier(ref);
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

/// Generate new agent ID
String generateAgentId() => _uuid.v4();
