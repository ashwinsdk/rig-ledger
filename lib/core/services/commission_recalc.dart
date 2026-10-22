import '../database/database_service.dart';
import '../models/agent.dart';
import '../models/ledger_entry.dart';
import '../models/ledger_line.dart';
import '../models/vehicle.dart';

/// Moves the commission of existing bills to a changed agent price (v2.0.3).
///
/// A bill is skipped when its commission was overridden by hand
/// (`isCommissionManuallyEdited`). On the other bills each line follows the
/// new price only when its rate still equals the agent's OLD price for that
/// line type (the rate came from the agent); a different rate was typed by
/// hand and is kept. Side bore bills use the agent's default depth rate, like
/// the side bore form. The bill commission is recalculated from the lines.
class CommissionRecalc {
  CommissionRecalc._();

  static bool _same(double a, double b) => (a - b).abs() < 1e-9;

  /// The agent price a line of a bill takes.
  static double priceFor(Agent agent, String category, String type,
      {required bool sideBore}) {
    if (sideBore) return agent.depthCommissionRate;
    return agent.rateFor(category, type);
  }

  /// Bills of [bills] that change, already updated (not saved).
  static List<LedgerEntry> changedBills({
    required Agent oldAgent,
    required Agent newAgent,
    required Iterable<LedgerEntry> bills,
    required bool Function(String vehicleId) isSideBore,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    final out = <LedgerEntry>[];
    for (final bill in bills) {
      if (bill.agentId != newAgent.id) continue;
      if (bill.isCommissionManuallyEdited) continue;
      final side = isSideBore(bill.vehicleId);
      var any = false;
      final lines = <LedgerLine>[];
      for (final l in bill.lines) {
        if (side && l.category != LedgerLine.depth) {
          lines.add(l);
          continue;
        }
        final oldP = priceFor(oldAgent, l.category, l.type, sideBore: side);
        final newP = priceFor(newAgent, l.category, l.type, sideBore: side);
        if (!_same(oldP, newP) && _same(l.commissionRate, oldP)) {
          lines.add(l.copyWith(commissionRate: newP));
          any = true;
        } else {
          lines.add(l);
        }
      }
      if (!any) continue;
      out.add(bill.withLines(lines).copyWith(
            commission: LedgerEntry.calculateLinesCommission(lines),
            updatedAt: stamp,
          ));
    }
    return out;
  }

  /// Recalculates and saves the bills of [newAgent]. Returns how many changed.
  static Future<int> apply(
      {required Agent oldAgent, required Agent newAgent}) async {
    final changed = changedBills(
      oldAgent: oldAgent,
      newAgent: newAgent,
      bills: DatabaseService.getLedgerEntriesByAgent(newAgent.id),
      isSideBore: (id) =>
          DatabaseService.getVehicle(id)?.vehicleType == VehicleType.sideBore,
    );
    for (final b in changed) {
      await DatabaseService.saveLedgerEntry(b);
    }
    return changed.length;
  }
}
