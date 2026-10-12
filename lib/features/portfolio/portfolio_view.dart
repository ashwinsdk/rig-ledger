import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/portfolio_calculator.dart';

final _money = NumberFormat('#,##0.00');

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
  bool _allRigs = false;

  @override
  Widget build(BuildContext context) {
    final src = ref.watch(portfolioSourceProvider(_allRigs));
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
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('This rig')),
                    ButtonSegment(value: true, label: Text('All rigs')),
                  ],
                  selected: {_allRigs},
                  onSelectionChanged: (v) => setState(() {
                    _allRigs = v.first;
                    _agentId = null;
                  }),
                  showSelectedIcon: false,
                ),
              ),
            ],
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
          if (_agentId == null && s.agents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AgentsCard(rows: s.agents),
          ],
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
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
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
          const Divider(),
          _row('Total expenses', s.expenses, bold: true),
        ],
      ),
    );
  }
}

class _AgentsCard extends StatelessWidget {
  final List<AgentPortfolioRow> rows;
  const _AgentsCard({required this.rows});

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
          const Text('By agent', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(r.agentName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text('${r.bills} ${r.bills == 1 ? 'bill' : 'bills'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 2),
                  Wrap(spacing: 14, children: [
                    _kv('Total', r.total, AppColors.primary),
                    _kv('Received', r.received, AppColors.success),
                    _kv('Pending', r.pending, AppColors.warning),
                    _kv('Commission', r.commission, AppColors.accent),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, double v, Color c) => Text.rich(TextSpan(children: [
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
