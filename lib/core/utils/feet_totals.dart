import '../models/ledger_entry.dart';
import '../models/ledger_line.dart';
import '../models/ledger_types.dart';

/// Feet drilled and laid by type, for the ledger summary and the PDF report.
///
/// One entry per type in the user-defined list (in list order, zero included)
/// plus any type that bills use but the list does not have, so no feet are
/// ever dropped. MS pipe has a per type map and a total.
class FeetTotals {
  /// Depth feet by depth type.
  final Map<String, double> depth;

  /// PVC feet by PVC type.
  final Map<String, double> pvc;

  /// MS pipe feet by MS pipe type.
  final Map<String, double> ms;

  final double msPipeTotal;

  /// All depth feet, whatever the type (side bore rigs show only this).
  final double depthTotal;

  const FeetTotals({
    required this.depth,
    required this.pvc,
    this.ms = const {},
    required this.msPipeTotal,
    required this.depthTotal,
  });

  static FeetTotals compute(Iterable<LedgerEntry> entries, LedgerTypes types) {
    final depth = {for (final t in types.depth) t: 0.0};
    final pvc = {for (final t in types.pvc) t: 0.0};
    final ms = {for (final t in types.ms) t: 0.0};
    var msTotal = 0.0;
    var depthTotal = 0.0;
    // Every line counts under its own type (a bill can have several).
    for (final e in entries) {
      for (final l in e.lines) {
        switch (l.category) {
          case LedgerLine.depth:
            depth[l.type] = (depth[l.type] ?? 0) + l.feet;
            depthTotal += l.feet;
          case LedgerLine.pvc:
            pvc[l.type] = (pvc[l.type] ?? 0) + l.feet;
          case LedgerLine.ms:
            ms[l.type] = (ms[l.type] ?? 0) + l.feet;
            msTotal += l.feet;
        }
      }
    }
    return FeetTotals(
        depth: depth,
        pvc: pvc,
        ms: ms,
        msPipeTotal: msTotal,
        depthTotal: depthTotal);
  }
}
