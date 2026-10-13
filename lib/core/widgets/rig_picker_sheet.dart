import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../providers/rig_switch.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_colors.dart';

/// Bottom sheet that lists the rigs and switches the current one with
/// [switchRig]. Shared by the Ledger header and the Portfolio header.
/// [onSwitched] runs after the rig changed (not when the current rig is tapped).
Future<void> showRigPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  void Function(Vehicle vehicle)? onSwitched,
}) {
  final vehicles = ref.read(vehiclesProvider);
  final currentVehicle = ref.read(currentVehicleProvider);

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Switch Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a vehicle to view its ledger',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No vehicles found')),
              )
            else
              ...vehicles.map((vehicle) {
                final isSelected = vehicle.id == currentVehicle?.id;
                final isSideBore = vehicle.vehicleType == VehicleType.sideBore;
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSideBore
                          ? Icons.engineering_outlined
                          : Icons.precision_manufacturing_outlined,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    vehicle.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  subtitle: Text(
                    isSideBore ? 'Side Bore' : 'Main Bore',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (await switchRig(ref, vehicle)) {
                      onSwitched?.call(vehicle);
                    }
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
