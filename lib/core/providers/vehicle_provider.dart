import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/vehicle.dart';

/// Provider for the list of all vehicles
class VehiclesNotifier extends StateNotifier<List<Vehicle>> {
  VehiclesNotifier() : super([]) {
    loadVehicles();
  }

  void loadVehicles() {
    state = DatabaseService.getAllVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await DatabaseService.saveVehicle(vehicle);
    loadVehicles();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await DatabaseService.saveVehicle(vehicle);
    loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await DatabaseService.deleteVehicle(id);
    loadVehicles();
  }

  void refresh() {
    loadVehicles();
  }
}

final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, List<Vehicle>>((ref) {
  return VehiclesNotifier();
});

/// Provider for the currently selected vehicle
class CurrentVehicleNotifier extends StateNotifier<Vehicle?> {
  CurrentVehicleNotifier() : super(null) {
    _loadCurrentVehicle();
  }

  void _loadCurrentVehicle() {
    state = DatabaseService.getCurrentVehicle();
  }

  Future<void> setCurrentVehicle(Vehicle vehicle) async {
    await DatabaseService.setCurrentVehicle(vehicle.id);
    state = vehicle;
  }

  void refresh() {
    _loadCurrentVehicle();
  }
}

final currentVehicleProvider =
    StateNotifierProvider<CurrentVehicleNotifier, Vehicle?>((ref) {
  return CurrentVehicleNotifier();
});

/// Provider for vehicle type (for display purposes)
final vehicleTypeNameProvider = Provider.family<String, int>((ref, typeIndex) {
  return typeIndex == 0 ? 'Main Bore' : 'Side Bore';
});
