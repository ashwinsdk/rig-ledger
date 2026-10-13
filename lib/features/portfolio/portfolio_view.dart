import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/agent.dart';
import '../../core/models/ledger_types.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/portfolio_calculator.dart';
import '../agents/agent_dialogs.dart';

final _money = NumberFormat('#,##0.00');

/// This rig / All rigs: two big pills with icons and a line saying what is
/// shown. The header above holds the rig picker.
class _ScopeToggle extends ConsumerWidget {
  final bool allRigs;
  final ValueChanged<bool> onChanged;
  const _ScopeToggle({required this.allRigs, required this.onChanged});

  Widget _option(String label, IconData icon, bool selected, bool value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rigs = ref.watch(vehiclesProvider);
    final current = ref.watch(currentVehicleProvider);
    final hint = allRigs
        ? 'Showing all ${rigs.length} ${rigs.length == 1 ? 'rig' : 'rigs'} together'
        : 'Showing ${current?.name ?? 'the current rig'} only';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              _option('This rig', Icons.precision_manufacturing_outlined,
                  !allRigs, false),
              _option('All rigs', Icons.apps_rounded, allRigs, true),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Text(hint,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

/// Portfolio overview (v2.0.0 feature 3): total, received, pending,
/// commission, expenses and profit for a period, optionally for one agent
/// and optionally across all rigs. The period comes from the Stats header.
class PortfolioView extends ConsumerStatefulWidget {
  /// Inclusive bounds; null means unbounded (All).
  final DateTime? start;
  final DateTime? end;

  const PortfolioView({super.key, this.start, this.end});

  @override
  ConsumerState<PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends ConsumerState<PortfolioView> {
  String? _agentId;

  @override
  Widget build(BuildContext context) {
    final allRigs = ref.watch(portfolioAllRigsProvider);
    final src = ref.watch(portfolioSourceProvider(allRigs));
    final bills = src.bills;
    final sideBoreIds = src.sideBoreVehicleIds;

    // Agents that have bills in the scope (any period) for the filter chips.
    final agentNames = <String, String>{};
    for (final b in bills) {
      agentNames[b.agentId] = b.agentName;
    }
    if (_agentId != null && !agentNames.containsKey(_agentId)) {
      _agentId = null;
    }

    final s = PortfolioCalculator.compute(
      bills: bills,
      diesel: src.diesel,
      pvc: src.pvc,
      bit: src.bit,
      hammer: src.hammer,
      other: src.other,
      start: widget.start,
      end: widget.end,
      agentId: _agentId,
      sideBoreVehicleIds: sideBoreIds,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScopeToggle(
            allRigs: allRigs,
            onChanged: (v) {
              ref.read(portfolioAllRigsProvider.notifier).state = v;
              setState(() => _agentId = null);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All agents'),
                    side: BorderSide(
                        color: _agentId == null
                            ? AppColors.primary
                            : AppColors.border),
                    selected: _agentId == null,
                    onSelected: (_) => setState(() => _agentId = null),
                  ),
                ),
                for (final e in agentNames.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      side: BorderSide(
                          color: _agentId == e.key
                              ? AppColors.primary
                              : AppColors.border),
                      selected: _agentId == e.key,
                      onSelected: (_) => setState(() => _agentId = e.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (s.expensesApply) _ProfitCard(s: s) else const _NoExpensesNote(),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _MetricCard('Total billed', s.total, AppColors.primary,
                  Icons.account_balance_wallet_outlined,
                  subtitle: '${s.bills} ${s.bills == 1 ? 'bill' : 'bills'}'),
              _MetricCard('Received', s.received, AppColors.success,
                  Icons.check_circle_outline),
              _MetricCard('Pending', s.pending, AppColors.warning,
                  Icons.pending_outlined,
                  subtitle: s.less > 0
                      ? 'after ₹${_money.format(s.less)} less'
                      : null),
              _MetricCard('Commission', s.commission, AppColors.accent,
                  Icons.handshake_outlined,
                  subtitle: 'not part of total'),
            ],
          ),
          if (s.expensesApply) ...[
            const SizedBox(height: 16),
            _ExpensesCard(s: s),
          ],
          const SizedBox(height: 16),
          _AgentsSection(rows: s.agents),
          const SizedBox(height: 16),
          const _DefinitionsCard(),
        ],
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  final PortfolioSummary s;
  const _ProfitCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final profit = s.realisedProfit;
    final good = profit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit (received - expenses - commission)',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${good ? '' : '-'}₹${_money.format(profit.abs())}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected when all pending is collected: '
            '${s.expectedProfit < 0 ? '-' : ''}₹${_money.format(s.expectedProfit.abs())}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NoExpensesNote extends StatelessWidget {
  const _NoExpensesNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Expenses are not tracked per agent, so profit is shown for all agents only.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String? subtitle;
  const _MetricCard(this.label, this.value, this.color, this.icon,
      {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('₹${_money.format(value)}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExpensesCard extends StatelessWidget {
  final PortfolioSummary s;
  const _ExpensesCard({required this.s});

  Widget _row(String label, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          Text('₹${_money.format(v)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expenses (side ledger)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _row('Diesel', s.diesel),
          if (s.pvc > 0) _row('PVC', s.pvc),
          _row('Bit', s.bit),
          _row('Hammer', s.hammer),
          _row('Other expenses', s.other),
          const Divider(),
          _row('Total expenses', s.expenses, bold: true),
        ],
      ),
    );
  }
}

/// Agents section (v2.0.1): every agent, including ones without bills in the
/// period, with the period totals. Tap an agent for details, prices and edit.
class _AgentsSection extends ConsumerWidget {
  final List<AgentPortfolioRow> rows;
  const _AgentsSection({required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final byId = {for (final r in rows) r.agentId: r};
    final sorted = [...agents]..sort((a, b) {
        final x = byId[a.id]?.total ?? 0;
        final y = byId[b.id]?.total ?? 0;
        final c = y.compareTo(x);
        return c != 0 ? c : a.name.compareTo(b.name);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Agents',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => showAddAgentDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add agent'),
              ),
            ],
          ),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No agents yet. Tap Add agent to create one.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          for (final agent in sorted)
            _AgentRow(
              agent: agent,
              row: byId[agent.id],
              onTap: () => _showAgentSheet(context, ref, agent, byId[agent.id]),
            ),
        ],
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  final Agent agent;
  final AgentPortfolioRow? row;
  final VoidCallback onTap;
  const _AgentRow(
      {required this.agent, required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(agent.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                  r == null
                      ? 'no bills'
                      : '${r.bills} ${r.bills == 1 ? 'bill' : 'bills'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textHint),
            ]),
            if (r != null) ...[
              const SizedBox(height: 2),
              Wrap(spacing: 14, children: [
                _kv('Total', r.total, AppColors.primary),
                _kv('Received', r.received, AppColors.success),
                _kv('Pending', r.pending, AppColors.warning),
                _kv('Commission', r.commission, AppColors.accent),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _kv(String k, double v, Color c) =>
      Text.rich(TextSpan(children: [
        TextSpan(
            text: '$k ',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        TextSpan(
            text: '₹${_money.format(v)}',
            style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      ]));
}

/// Detail sheet of one agent: contact, period totals, commission prices per
/// type, and Edit / Delete (the same dialogs the Agents screen uses).
void _showAgentSheet(
    BuildContext context, WidgetRef ref, Agent agent, AgentPortfolioRow? row) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _AgentSheet(agentId: agent.id, row: row),
  );
}

class _AgentSheet extends ConsumerWidget {
  final String agentId;
  final AgentPortfolioRow? row;
  const _AgentSheet({required this.agentId, required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final agent = agents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) return const SizedBox(height: 80);
    final prices = agent.commissionRates;
    final defaults = {
      'Depth': agent.depthCommissionRate,
      'PVC': agent.pvcCommissionRate,
      'MS pipe': agent.msPipeCommissionRate,
    };

    String label(String key) {
      final parts = key.split(':');
      final cat = switch (parts.first) {
        'depth' => 'Depth',
        'pvc' => 'PVC',
        _ => 'MS pipe',
      };
      return '$cat ${parts.length > 1 ? LedgerTypes.shortLabel(parts[1]) : ''}';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Text(agent.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            if (agent.phone != null && agent.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(agent.phone!,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            if (agent.notes != null && agent.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(agent.notes!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 16),
            const Text('This period',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (row == null)
              const Text('No bills in this period',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              Wrap(spacing: 14, runSpacing: 4, children: [
                _AgentRow._kv('Total', row!.total, AppColors.primary),
                _AgentRow._kv('Received', row!.received, AppColors.success),
                _AgentRow._kv('Pending', row!.pending, AppColors.warning),
                _AgentRow._kv('Commission', row!.commission, AppColors.accent),
              ]),
            const SizedBox(height: 16),
            const Text('Commission per foot',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (prices.isEmpty && defaults.values.every((v) => v == 0))
              const Text('No prices set. Tap Edit to add them.',
                  style: TextStyle(color: AppColors.textSecondary)),
            for (final e in prices.entries) _priceLine(label(e.key), e.value),
            for (final e in defaults.entries)
              if (e.value > 0) _priceLine('${e.key} (other sizes)', e.value),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDeleteAgentDialog(context, ref, agent, agents);
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showEditAgentDialog(context, ref, agent);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLine(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text('₹${_money.format(value)} / ft',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _DefinitionsCard extends StatelessWidget {
  const _DefinitionsCard();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Total billed = sum of bill totals. Pending = total - received - less. '
      'Commission is shown separately and is never part of a bill total. '
      'Expenses are the side ledger purchases in the period. '
      'Profit = received - expenses - commission.',
      style: TextStyle(fontSize: 11, color: AppColors.textHint),
    );
  }
}
