import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/bit_entry.dart';
import '../models/diesel_entry.dart';
import '../models/hammer_entry.dart';
import '../models/ledger_entry.dart';
import '../models/pvc_entry.dart';
import '../models/vehicle.dart';
import 'ledger_provider.dart';
import 'side_ledger_provider.dart';

/// Records the Portfolio is calculated from.
class PortfolioSource {
  final List<LedgerEntry> bills;
  final List<DieselEntry> diesel;
  final List<PvcEntry> pvc;
  final List<BitEntry> bit;
  final List<HammerEntry> hammer;

  /// Side bore rigs (their PVC purchases are ignored).
  final Set<String> sideBoreVehicleIds;

  const PortfolioSource({
    required this.bills,
    required this.diesel,
    required this.pvc,
    required this.bit,
    required this.hammer,
    required this.sideBoreVehicleIds,
  });
}

/// Portfolio scope: false = the current rig, true = all rigs. Shared by the
/// Portfolio header and the Overview so both agree.
final portfolioAllRigsProvider = StateProvider<bool>((ref) => false);

/// Portfolio records for the current rig, or for all rigs when the family
/// argument is true. Watching the per-rig providers keeps it live.
final portfolioSourceProvider =
    Provider.family<PortfolioSource, bool>((ref, allRigs) {
  final myBills = ref.watch(ledgerEntriesProvider);
  final myDiesel = ref.watch(dieselEntriesProvider);
  final myPvc = ref.watch(pvcEntriesProvider);
  final myBit = ref.watch(bitEntriesProvider);
  final myHammer = ref.watch(hammerEntriesProvider);
  return PortfolioSource(
    bills: allRigs ? DatabaseService.ledgerBox.values.toList() : myBills,
    diesel: allRigs ? DatabaseService.dieselBox.values.toList() : myDiesel,
    pvc: allRigs ? DatabaseService.pvcBox.values.toList() : myPvc,
    bit: allRigs ? DatabaseService.bitBox.values.toList() : myBit,
    hammer: allRigs ? DatabaseService.hammerBox.values.toList() : myHammer,
    sideBoreVehicleIds: DatabaseService.vehicleBox.values
        .where((v) => v.vehicleType == VehicleType.sideBore)
        .map((v) => v.id)
        .toSet(),
  );
});
