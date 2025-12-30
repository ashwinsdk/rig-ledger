import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/agent.dart';

const _uuid = Uuid();

/// Agents notifier
class AgentsNotifier extends StateNotifier<List<Agent>> {
  AgentsNotifier() : super([]) {
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

/// Agent bill counts
final agentBillCountsProvider = Provider<Map<String, int>>((ref) {
  final agents = ref.watch(agentsProvider);

  final Map<String, int> counts = {};
  for (final agent in agents) {
    counts[agent.id] = DatabaseService.getAgentBillCount(agent.id);
  }

  return counts;
});

/// Generate new agent ID
String generateAgentId() => _uuid.v4();
