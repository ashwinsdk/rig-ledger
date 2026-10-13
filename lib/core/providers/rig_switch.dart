import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import 'agent_provider.dart';
import 'ledger_provider.dart';
import 'side_ledger_provider.dart';
import 'vehicle_provider.dart';

/// Makes [vehicle] the current rig everywhere (LR-01).
///
/// One shared implementation for the Ledger header, the Portfolio header and
/// Vehicle Management. Waits for the stored current rig to change, clears the
/// ledger search and every filter (they belong to the previous rig), then
/// refreshes the providers that are scoped to a rig. The macOS shell keeps its
/// own copy (frozen).
///
/// Returns false when [vehicle] was already the current rig.
Future<bool> switchRig(WidgetRef ref, Vehicle vehicle) async {
  if (ref.read(currentVehicleProvider)?.id == vehicle.id) return false;

  await ref.read(currentVehicleProvider.notifier).setCurrentVehicle(vehicle);

  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(ledgerFilterProvider.notifier).state = const LedgerFilter();
  ref.read(dieselFilterProvider.notifier).state = const DieselFilter();
  ref.read(pvcFilterProvider.notifier).state = const PvcFilter();
  ref.read(bitFilterProvider.notifier).state = const BitFilter();
  ref.read(hammerFilterProvider.notifier).state = const HammerFilter();

  ref.read(ledgerEntriesProvider.notifier).refresh();
  ref.read(dieselEntriesProvider.notifier).refresh();
  ref.read(pvcEntriesProvider.notifier).refresh();
  ref.read(bitEntriesProvider.notifier).refresh();
  ref.read(hammerEntriesProvider.notifier).refresh();
  ref.read(agentsProvider.notifier).refresh();
  return true;
}
