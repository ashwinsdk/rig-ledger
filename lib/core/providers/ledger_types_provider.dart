import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/ledger_types.dart';
import 'ledger_provider.dart';

/// The user-defined depth, PVC and MS pipe types (v2.0.1).
///
/// Rules: a type is a number of inches (`9inch`, `9.5inch`); renaming updates
/// every bill that uses it; deleting is refused while any bill uses it and the
/// last type of a list cannot be deleted. Step rate tables are chosen per depth
/// type (7inch table, 8inch table or none).
class LedgerTypesNotifier extends StateNotifier<LedgerTypes> {
  final Ref _ref;

  LedgerTypesNotifier(this._ref) : super(LedgerTypes.defaults()) {
    load();
  }

  void load() {
    state = _withUsedTypes(DatabaseService.getLedgerTypes());
  }

  /// A type used by bills but missing from the list (a sync from an older
  /// device) is shown anyway. Only in memory: it is stored with the next edit.
  LedgerTypes _withUsedTypes(LedgerTypes types) {
    var out = types;
    for (final c in LedgerTypeCategory.values) {
      final missing = DatabaseService.usedLedgerTypes(c)
          .where((t) => !out.forCategory(c).contains(t))
          .toList();
      if (missing.isNotEmpty) {
        out = out.withCategory(c, _sorted([...out.forCategory(c), ...missing]));
      }
    }
    return out;
  }

  static List<String> _sorted(List<String> list) {
    final out = [...list];
    out.sort((a, b) {
      final x = double.tryParse(LedgerTypes.inchesOf(a));
      final y = double.tryParse(LedgerTypes.inchesOf(b));
      if (x != null && y != null) return x.compareTo(y);
      return a.compareTo(b);
    });
    return out;
  }

  Future<void> _save(LedgerTypes next) async {
    final stamped = next.copyWith(updatedAt: DateTime.now());
    await DatabaseService.saveLedgerTypes(stamped);
    state = stamped;
  }

  /// Adds a type from what the user typed. Returns `(success, errorMessage)`.
  Future<(bool, String?)> addType(LedgerTypeCategory c, String input) async {
    final name = LedgerTypes.nameFromInches(input);
    if (name == null) {
      return (false, 'Enter the size in inches, for example 9 or 9.5');
    }
    if (state.forCategory(c).contains(name)) {
      return (false, '$name already exists');
    }
    await _save(
        state.withCategory(c, _sorted([...state.forCategory(c), name])));
    return (true, null);
  }

  /// Renames [from] to the size in [input] on the list and on every bill.
  Future<(bool, String?)> renameType(
      LedgerTypeCategory c, String from, String input) async {
    final to = LedgerTypes.nameFromInches(input);
    if (to == null) {
      return (false, 'Enter the size in inches, for example 9 or 9.5');
    }
    if (to == from) return (true, null);
    if (state.forCategory(c).contains(to)) return (false, '$to already exists');

    final table =
        c == LedgerTypeCategory.depth ? state.stepTableFor(from) : null;
    await DatabaseService.renameBillType(c, from, to);
    final list = [
      for (final t in state.forCategory(c)) t == from ? to : t,
    ];
    var steps = {...state.steps}..remove(from);
    if (table != null) steps[to] = table; // the renamed type keeps its table
    await _save(state.withCategory(c, _sorted(list)).copyWith(steps: steps));
    _ref.read(ledgerEntriesProvider.notifier).refresh();
    return (true, null);
  }

  /// Deletes [type] unless a bill uses it or it is the last one.
  Future<(bool, String?)> deleteType(LedgerTypeCategory c, String type) async {
    final used = DatabaseService.countBillsWithType(c, type);
    if (used > 0) {
      return (
        false,
        '$used ${used == 1 ? 'bill uses' : 'bills use'} $type. '
            'Change ${used == 1 ? 'it' : 'them'} first.'
      );
    }
    if (state.forCategory(c).length <= 1) {
      return (false, 'Keep at least one ${c.shortName} type');
    }
    final steps = {...state.steps}..remove(type);
    await _save(state.withCategory(c, [
      for (final t in state.forCategory(c))
        if (t != type) t
    ]).copyWith(steps: steps));
    return (true, null);
  }

  /// Sets the step rate table of a depth type: '7inch', '8inch' or null.
  Future<void> setStepTable(String depthType, String? table) async {
    final steps = {...state.steps};
    if (table == null) {
      // 7inch and 8inch use their own table unless told otherwise, so "none"
      // is stored as an explicit empty choice for them.
      if (depthType == '7inch' || depthType == '8inch') {
        steps[depthType] = 'none';
      } else {
        steps.remove(depthType);
      }
    } else {
      steps[depthType] = table;
    }
    await _save(state.copyWith(steps: steps));
  }

  void refresh() => load();
}

final ledgerTypesProvider =
    StateNotifierProvider<LedgerTypesNotifier, LedgerTypes>((ref) {
  return LedgerTypesNotifier(ref);
});
