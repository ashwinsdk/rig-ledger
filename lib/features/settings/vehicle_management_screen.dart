import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/providers/vehicle_provider.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../../core/providers/side_ledger_provider.dart';
import '../../../core/providers/agent_provider.dart';
import '../../../core/theme/app_colors.dart';

class VehicleManagementScreen extends ConsumerStatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  ConsumerState<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState
    extends ConsumerState<VehicleManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehiclesProvider.notifier).refresh();
    });
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => const _VehicleFormDialog(),
    ).then((_) {
      ref.read(vehiclesProvider.notifier).refresh();
    });
  }

  void _showEditVehicleDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleFormDialog(vehicle: vehicle),
    ).then((_) {
      ref.read(vehiclesProvider.notifier).refresh();
    });
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final vehicles = ref.read(vehiclesProvider);

    // Prevent deleting the last vehicle
    if (vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentVehicle = ref.read(currentVehicleProvider);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${vehicle.name}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will delete all ledger entries, side-ledger data, and agent information for this vehicle.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // If deleting the current vehicle, switch to another one first
      if (currentVehicle?.id == vehicle.id) {
        final otherVehicle = vehicles.firstWhere((v) => v.id != vehicle.id);
        await ref
            .read(currentVehicleProvider.notifier)
            .setCurrentVehicle(otherVehicle);
      }

      await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);

      // Refresh all data providers
      ref.read(ledgerEntriesProvider.notifier).refresh();
      ref.read(dieselEntriesProvider.notifier).refresh();
      ref.read(pvcEntriesProvider.notifier).refresh();
      ref.read(bitEntriesProvider.notifier).refresh();
      ref.read(hammerEntriesProvider.notifier).refresh();
      ref.read(agentsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted')),
        );
      }
    }
  }

  Future<void> _switchVehicle(Vehicle vehicle) async {
    await ref.read(currentVehicleProvider.notifier).setCurrentVehicle(vehicle);

    // Clear filters and search when changing vehicles
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(ledgerFilterProvider.notifier).state = const LedgerFilter();

    // Refresh all data providers for the new vehicle
    ref.read(ledgerEntriesProvider.notifier).refresh();
    ref.read(dieselEntriesProvider.notifier).refresh();
    ref.read(pvcEntriesProvider.notifier).refresh();
    ref.read(bitEntriesProvider.notifier).refresh();
    ref.read(hammerEntriesProvider.notifier).refresh();
    ref.read(agentsProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${vehicle.name}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBarGradient,
          ),
        ),
      ),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vehicles yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddVehicleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isCurrentVehicle = currentVehicle?.id == vehicle.id;
                final isMainBore = vehicle.vehicleTypeIndex == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCurrentVehicle
                        ? const BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap:
                        isCurrentVehicle ? null : () => _switchVehicle(vehicle),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Vehicle icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isMainBore
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMainBore
                                  ? Icons.precision_manufacturing
                                  : Icons.construction,
                              color: isMainBore ? Colors.blue : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Vehicle info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      vehicle.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isCurrentVehicle) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isMainBore ? 'Main Bore' : 'Side Bore',
                                  style: TextStyle(
                                    color:
                                        isMainBore ? Colors.blue : Colors.green,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditVehicleDialog(vehicle);
                              } else if (value == 'delete') {
                                _deleteVehicle(vehicle);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VehicleFormDialog extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const _VehicleFormDialog({this.vehicle});

  @override
  ConsumerState<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _selectedTypeIndex = 0; // 0 = Main Bore, 1 = Side Bore

  bool get isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _selectedTypeIndex = widget.vehicle?.vehicleTypeIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      vehicleTypeIndex: _selectedTypeIndex,
      createdAt: widget.vehicle?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      await ref.read(vehiclesProvider.notifier).updateVehicle(vehicle);
    } else {
      await ref.read(vehiclesProvider.notifier).addVehicle(vehicle);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Vehicle updated' : 'Vehicle added'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name *',
                hintText: 'e.g., Main Rig, Side Rig 1',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a vehicle name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Vehicle Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    index: 0,
                    title: 'Main Bore',
                    subtitle: 'Full ledger + side-ledger',
                    icon: Icons.precision_manufacturing,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    index: 1,
                    title: 'Side Bore',
                    subtitle: 'Mini-ledger + side-ledger',
                    icon: Icons.construction,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveVehicle,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTypeIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTypeIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
