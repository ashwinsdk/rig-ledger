import '../models/ledger_entry.dart';
import '../models/ledger_types.dart';

/// Feet drilled and laid by type, for the ledger summary and the PDF report.
///
/// One entry per type in the user-defined list (in list order, zero included)
/// plus any type that bills use but the list does not have, so no feet are
/// ever dropped. MS pipe is one total.
class FeetTotals {
  /// Depth feet by depth type.
  final Map<String, double> depth;

  /// PVC feet by PVC type.
  final Map<String, double> pvc;

  final double msPipeTotal;

  /// All depth feet, whatever the type (side bore rigs show only this).
  final double depthTotal;

  const FeetTotals({
    required this.depth,
    required this.pvc,
    required this.msPipeTotal,
    required this.depthTotal,
  });

  static FeetTotals compute(Iterable<LedgerEntry> entries, LedgerTypes types) {
    final depth = {for (final t in types.depth) t: 0.0};
    final pvc = {for (final t in types.pvc) t: 0.0};
    var ms = 0.0;
    var depthTotal = 0.0;
    for (final e in entries) {
      depth[e.depth] = (depth[e.depth] ?? 0) + e.depthInFeet;
      pvc[e.pvc] = (pvc[e.pvc] ?? 0) + e.pvcInFeet;
      ms += e.msPipeInFeet;
      depthTotal += e.depthInFeet;
    }
    return FeetTotals(
        depth: depth, pvc: pvc, msPipeTotal: ms, depthTotal: depthTotal);
  }
}
