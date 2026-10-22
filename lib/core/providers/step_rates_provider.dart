import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/step_rates.dart';

/// Step rate tables per rig (v2.0.4). Saved bills keep the step rate they were
/// saved with; only bills that are created or whose depth is edited afterwards
/// use the tables as they are then.
class StepRatesNotifier extends StateNotifier<StepRates> {
  StepRatesNotifier() : super(DatabaseService.getStepRates());

  Future<void> saveRig(
      String vehicleId, StepTable table7, StepTable table8) async {
    final next = state.withRig(
        vehicleId,
        RigStepRates(
            table7: table7, table8: table8, updatedAt: DateTime.now()));
    await DatabaseService.saveStepRates(next);
    state = next;
  }

  /// Back to the built-in tables. Stored with a new timestamp so the reset
  /// also wins in a sync.
  Future<void> resetRig(String vehicleId) =>
      saveRig(vehicleId, StepTable.builtin7, StepTable.builtin8);

  void refresh() => state = DatabaseService.getStepRates();
}

final stepRatesProvider =
    StateNotifierProvider<StepRatesNotifier, StepRates>((ref) {
  return StepRatesNotifier();
});
