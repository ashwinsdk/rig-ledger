import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/agent.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/widgets/adaptive_header.dart';
import 'agent_dialogs.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final billCounts = ref.watch(agentBillCountsProvider);
    final commissions = ref.watch(agentCommissionTotalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header — slim on desktop, gradient on mobile
          AdaptiveHeader(
            title: 'Agent Management',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : Colors.white,
                ),
                onPressed: () => showAddAgentDialog(context, ref),
              ),
            ],
          ),

          // Content
          Expanded(
            child: agents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No agents yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first agent',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => showAddAgentDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Agent'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      final billCount = billCounts[agent.id] ?? 0;
                      return _AgentCard(
                        agent: agent,
                        billCount: billCount,
                        commissionTotal: commissions[agent.id] ?? 0,
                        onEdit: () => showEditAgentDialog(context, ref, agent),
                        onDelete: () =>
                            showDeleteAgentDialog(context, ref, agent, agents),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: agents.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => showAddAgentDialog(context, ref),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  final int billCount;
  final double commissionTotal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgentCard({
    required this.agent,
    required this.billCount,
    this.commissionTotal = 0,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (agent.phone != null &&
                              agent.phone!.isNotEmpty) ...[
                            Icon(Icons.phone_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              agent.phone!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(Icons.receipt_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$billCount ${billCount == 1 ? 'bill' : 'bills'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (commissionTotal > 0 ||
                          agent.depthCommissionRate > 0 ||
                          agent.pvcCommissionRate > 0 ||
                          agent.msPipeCommissionRate > 0 ||
                          agent.commissionRates.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.handshake_outlined,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'Commission ₹${NumberFormat('#,##0.00').format(commissionTotal)}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
