import '../models/bit_entry.dart';
import '../models/diesel_entry.dart';
import '../models/hammer_entry.dart';
import '../models/ledger_entry.dart';
import '../models/pvc_entry.dart';

/// Money totals of one agent inside a portfolio.
class AgentPortfolioRow {
  final String agentId;
  final String agentName;
  final int bills;
  final double total;
  final double received;
  final double pending;
  final double commission;

  const AgentPortfolioRow({
    required this.agentId,
    required this.agentName,
    required this.bills,
    required this.total,
    required this.received,
    required this.pending,
    required this.commission,
  });
}

/// Portfolio numbers for a period (v2.0.0 feature 3).
///
/// Definitions (shown to the user in the Portfolio screen):
/// - total: sum of bill totals (before less)
/// - less: discounts given
/// - received: money received on bills
/// - pending: balance still owed (total - received - less)
/// - commission: informational, never part of total
/// - expenses: side ledger purchases (diesel, PVC, bit, hammer) in the period
/// - realised profit = received - expenses - commission
/// - expected profit = total - less - expenses - commission
/// Expenses are not tracked per agent, so with an agent filter the expense
/// and profit figures are not available (`expensesApply` is false).
class PortfolioSummary {
  final int bills;
  final double total;
  final double less;
  final double received;
  final double pending;
  final double commission;
  final double diesel;
  final double pvc;
  final double bit;
  final double hammer;
  final bool expensesApply;
  final List<AgentPortfolioRow> agents;

  const PortfolioSummary({
    required this.bills,
    required this.total,
    required this.less,
    required this.received,
    required this.pending,
    required this.commission,
    required this.diesel,
    required this.pvc,
    required this.bit,
    required this.hammer,
    required this.expensesApply,
    required this.agents,
  });

  double get expenses =>
      PortfolioCalculator.round2(diesel + pvc + bit + hammer);
  double get netBilled => PortfolioCalculator.round2(total - less);
  double get realisedProfit =>
      PortfolioCalculator.round2(received - expenses - commission);
  double get expectedProfit =>
      PortfolioCalculator.round2(netBilled - expenses - commission);
}

/// Pure calculation, no Hive or Riverpod. Dates are inclusive on both ends;
/// a null bound means unbounded.
class PortfolioCalculator {
  PortfolioCalculator._();

  static double round2(double v) => (v * 100).round() / 100;

  static bool _inRange(DateTime d, DateTime? start, DateTime? end) =>
      (start == null || !d.isBefore(start)) && (end == null || !d.isAfter(end));

  /// [sideBoreVehicleIds]: vehicles whose PVC purchases are ignored (side
  /// bore rigs have no PVC).
  static PortfolioSummary compute({
    required Iterable<LedgerEntry> bills,
    required Iterable<DieselEntry> diesel,
    required Iterable<PvcEntry> pvc,
    required Iterable<BitEntry> bit,
    required Iterable<HammerEntry> hammer,
    DateTime? start,
    DateTime? end,
    String? agentId,
    Set<String> sideBoreVehicleIds = const {},
  }) {
    final selected = bills
        .where((b) =>
            _inRange(b.date, start, end) &&
            (agentId == null || b.agentId == agentId))
        .toList();

    var total = 0, less = 0, received = 0, pending = 0, commission = 0;
    final byAgent = <String, List<LedgerEntry>>{};
    for (final b in selected) {
      total += (b.total * 100).round();
      less += (b.less * 100).round();
      received += (b.received * 100).round();
      pending += (b.balance * 100).round();
      commission += (b.commission * 100).round();
      byAgent.putIfAbsent(b.agentId, () => []).add(b);
    }

    final rows = <AgentPortfolioRow>[];
    byAgent.forEach((id, list) {
      int t = 0, r = 0, p = 0, c = 0;
      for (final b in list) {
        t += (b.total * 100).round();
        r += (b.received * 100).round();
        p += (b.balance * 100).round();
        c += (b.commission * 100).round();
      }
      rows.add(AgentPortfolioRow(
        agentId: id,
        agentName: list.first.agentName,
        bills: list.length,
        total: t / 100,
        received: r / 100,
        pending: p / 100,
        commission: c / 100,
      ));
    });
    rows.sort((a, b) => b.total.compareTo(a.total));

    final noAgent = agentId == null;
    double sum(Iterable<double> v) {
      var p = 0;
      for (final x in v) {
        p += (x * 100).round();
      }
      return p / 100;
    }

    return PortfolioSummary(
      bills: selected.length,
      total: total / 100,
      less: less / 100,
      received: received / 100,
      pending: pending / 100,
      commission: commission / 100,
      diesel: noAgent
          ? sum(diesel
              .where((e) => _inRange(e.date, start, end))
              .map((e) => e.total))
          : 0,
      pvc: noAgent
          ? sum(pvc
              .where((e) =>
                  _inRange(e.date, start, end) &&
                  !sideBoreVehicleIds.contains(e.vehicleId))
              .map((e) => e.total))
          : 0,
      bit: noAgent
          ? sum(bit
              .where((e) => _inRange(e.date, start, end))
              .map((e) => e.total))
          : 0,
      hammer: noAgent
          ? sum(hammer
              .where((e) => _inRange(e.date, start, end))
              .map((e) => e.total))
          : 0,
      expensesApply: noAgent,
      agents: rows,
    );
  }
}
