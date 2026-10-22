import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_service.dart';
import '../../core/models/agent.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/ledger_types.dart';
import '../../core/utils/feet_totals.dart';
import '../../core/models/vehicle.dart';
import '../../core/theme/app_colors.dart';
import '../ledger_form/ledger_form_screen.dart';
import '../ledger_form/side_bore_form_screen.dart';

final _money = NumberFormat('#,##0.00');
final _day = DateFormat('dd MMM');
final _month = DateFormat('MMM yyyy');

double _r2(double v) => (v * 100).round() / 100;

/// What the Portfolio shows for one agent and one period (v2.0.3): who and
/// when, the totals, a month by month table (when the period spans months) and
/// every bill with its own commission, so a 3 month view can be read bill by
/// bill. Tap a bill to open it.
class AgentView extends StatelessWidget {
  final Agent? agent;
  final String agentName;

  /// Bills of this agent inside the period (any rig in the scope).
  final List<LedgerEntry> bills;

  /// Period bounds, null = unbounded.
  final DateTime? start;
  final DateTime? end;
  final VoidCallback onShowAll;
  final VoidCallback onDetails;

  /// Profit of all agents in the same period, after expenses (shown as a
  /// reference line under this agent's profit).
  final double? overallProfit;

  /// The ledger type lists, for the feet by type (list order).
  final LedgerTypes types;

  const AgentView({
    super.key,
    required this.agent,
    required this.agentName,
    required this.bills,
    required this.start,
    required this.end,
    required this.onShowAll,
    required this.onDetails,
    this.overallProfit,
    required this.types,
  });

  String get _period {
    if (start == null && end == null) return 'All time';
    final f = DateFormat('dd MMM yyyy');
    final a = start == null ? 'start' : f.format(start!);
    final b = end == null ? 'today' : f.format(end!);
    return '$a to $b';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...bills]..sort((a, b) => b.date.compareTo(a.date));
    final total = _r2(sorted.fold(0.0, (a, b) => a + b.total));
    final received = _r2(sorted.fold(0.0, (a, b) => a + b.received));
    final pending = _r2(sorted.fold(0.0, (a, b) => a + b.balance));
    final commission = _r2(sorted.fold(0.0, (a, b) => a + b.commission));
    final less = _r2(sorted.fold(0.0, (a, b) => a + b.less));

    final months = <String, List<LedgerEntry>>{};
    for (final b in sorted) {
      months.putIfAbsent(_month.format(b.date), () => []).add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(commission),
        const SizedBox(height: 12),
        _profitCard(received - commission, total - less - commission),
        const SizedBox(height: 12),
        Row(
          children: [
            _kpi('Bills', '${sorted.length}', AppColors.textPrimary),
            _kpi('Total', '₹${_money.format(total)}', AppColors.primary),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _kpi('Received', '₹${_money.format(received)}', AppColors.success),
            _kpi('Pending', '₹${_money.format(pending)}', AppColors.warning),
          ],
        ),
        if (sorted.isNotEmpty) ...[
          const SizedBox(height: 16),
          _feetByType(FeetTotals.compute(sorted, types)),
        ],
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No bills for $agentName in this period',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else ...[
          if (months.length > 1) ...[
            const SizedBox(height: 16),
            _monthTable(months),
          ],
          const SizedBox(height: 16),
          const Text('Bills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final b in sorted) _BillRow(bill: b),
          const SizedBox(height: 4),
          _totalRow(sorted.length, total, received, pending, commission),
        ],
      ],
    );
  }

  /// Profit of this agent: money received (or billed, for the expected line)
  /// minus the commission. Expenses are not tracked per agent, so they are not
  /// deducted here; the overall figure below does include them.
  Widget _profitCard(double profit, double expected) {
    String signed(double v) => '${v < 0 ? '-' : ''}₹${_money.format(v.abs())}';
    final good = profit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (good ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (good ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit from this agent (received - commission)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(signed(_r2(profit)),
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: good ? AppColors.success : AppColors.error)),
          ),
          const SizedBox(height: 6),
          Text(
              'Expected when all pending is collected: ${signed(_r2(expected))}',
              style: const TextStyle(fontSize: 12)),
          if (overallProfit != null) ...[
            const SizedBox(height: 2),
            Text('All agents, after expenses: ${signed(_r2(overallProfit!))}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          const Text(
              'Expenses are not tracked per agent, so they are not taken off this figure.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _header(double commission) {
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
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(agentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              if (agent != null)
                IconButton(
                  onPressed: onDetails,
                  icon: const Icon(Icons.tune, color: Colors.white),
                  tooltip: 'Prices and details',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(_period,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          const Text('Commission earned',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('₹${_money.format(commission)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
            label:
                const Text('All agents', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
        ),
      );

  /// Feet of every depth, PVC and MS pipe type over the agent's bills: every
  /// line counts under its own type. Types without feet are left out.
  Widget _feetByType(FeetTotals f) {
    final feet = NumberFormat('#,##0.##');
    Widget group(String title, Map<String, double> map, Color color) {
      final used = {
        for (final e in map.entries)
          if (e.value > 0) e.key: e.value
      };
      if (used.isEmpty) return const SizedBox.shrink();
      final total = used.values.fold(0.0, (a, b) => a + b);
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
                Text('Total ${feet.format(total)} ft',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final e in used.entries)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${LedgerTypes.shortLabel(e.key)}  ',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      TextSpan(
                          text: '${feet.format(e.value)} ft',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ])),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feet by type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          group('Depth', f.depth, Colors.blue),
          group('PVC', f.pvc, Colors.teal),
          group('MS pipe', f.ms, Colors.orange),
        ],
      ),
    );
  }

  Widget _monthTable(Map<String, List<LedgerEntry>> months) {
    TextStyle head() => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary);
    Widget cell(String t, {bool bold = false, Color? color, int flex = 3}) =>
        Expanded(
          flex: flex,
          child: Text(t,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('By month',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 3, child: Text('Month', style: head())),
            Expanded(
                flex: 2,
                child: Text('Bills', textAlign: TextAlign.end, style: head())),
            Expanded(
                flex: 3,
                child: Text('Total', textAlign: TextAlign.end, style: head())),
            Expanded(
                flex: 3,
                child: Text('Commission',
                    textAlign: TextAlign.end, style: head())),
          ]),
          const Divider(height: 12),
          for (final e in months.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                cell('${e.value.length}', flex: 2),
                cell(_money
                    .format(_r2(e.value.fold(0.0, (a, b) => a + b.total)))),
                cell(
                    _money.format(
                        _r2(e.value.fold(0.0, (a, b) => a + b.commission))),
                    bold: true,
                    color: AppColors.accent),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(
      int n, double total, double received, double pending, double comm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('$n ${n == 1 ? 'bill' : 'bills'}',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text('Total ₹${_money.format(total)}',
              style: const TextStyle(fontSize: 13)),
          Text('Received ₹${_money.format(received)}',
              style: const TextStyle(fontSize: 13)),
          Text('Pending ₹${_money.format(pending)}',
              style: const TextStyle(fontSize: 13)),
          Text('Commission ₹${_money.format(comm)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
        ],
      ),
    );
  }
}

/// One bill of the agent view: where and when, the money, and the commission
/// of this bill with its split.
class _BillRow extends StatelessWidget {
  final LedgerEntry bill;
  const _BillRow({required this.bill});

  void _open(BuildContext context) {
    final side = DatabaseService.getVehicle(bill.vehicleId)?.vehicleType ==
        VehicleType.sideBore;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => side
          ? SideBoreFormScreen(entry: bill)
          : LedgerFormScreen(entry: bill),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String, double>{
      'Depth': bill.commissionOf('depth'),
      'PVC': bill.commissionOf('pvc'),
      'MS': bill.commissionOf('ms'),
    }..removeWhere((_, v) => v <= 0);

    Widget amount(String label, double v, Color c) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('₹${_money.format(v)}',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: c)),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_day.format(bill.date),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text('#${bill.billNumber}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(bill.address,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  amount('Total', bill.total, AppColors.primary),
                  amount('Received', bill.received, AppColors.success),
                  amount('Balance', bill.balance,
                      bill.balance > 0 ? AppColors.warning : AppColors.success),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_outlined,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                          bill.isCommissionManuallyEdited
                              ? 'Commission (manual)'
                              : 'Commission',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    Text('₹${_money.format(bill.commission)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    if (parts.length > 1 && !bill.isCommissionManuallyEdited)
                      Expanded(
                        child: Text(
                          parts.entries
                              .map((e) => '${e.key} ${_money.format(e.value)}')
                              .join('  '),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
