import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../../core/providers/agent_provider.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late TextEditingController _billNumberController;
  late TextEditingController _addressController;
  String? _selectedAgentId;
  String? _selectedDepthType;
  String? _selectedPvcType;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(ledgerFilterProvider);
    _billNumberController = TextEditingController(text: filter.billNumber);
    _addressController = TextEditingController(text: filter.address);
    _selectedAgentId = filter.agentId;
    _selectedDepthType = filter.depthType;
    _selectedPvcType = filter.pvcType;
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider);
    final currentFilter = ref.watch(ledgerFilterProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Entries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (currentFilter.hasFilters)
                  TextButton(
                    onPressed: () {
                      ref.read(ledgerFilterProvider.notifier).state =
                          const LedgerFilter();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Bill Number
            TextField(
              controller: _billNumberController,
              decoration: const InputDecoration(
                labelText: 'Bill Number',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Address
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Agent Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAgentId,
              decoration: const InputDecoration(
                labelText: 'Agent',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Agents'),
                ),
                ...agents.map((agent) => DropdownMenuItem<String>(
                      value: agent.id,
                      child: Text(agent.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAgentId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Depth Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDepthType,
              decoration: const InputDecoration(
                labelText: 'Depth Type',
                prefixIcon: Icon(Icons.height),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Depths'),
                ),
                DropdownMenuItem<String>(
                  value: '7inch',
                  child: Text('7 inch'),
                ),
                DropdownMenuItem<String>(
                  value: '8inch',
                  child: Text('8 inch'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepthType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // PVC Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPvcType,
              decoration: const InputDecoration(
                labelText: 'PVC Type',
                prefixIcon: Icon(Icons.plumbing),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All PVC'),
                ),
                DropdownMenuItem<String>(
                  value: '7inch',
                  child: Text('7 inch'),
                ),
                DropdownMenuItem<String>(
                  value: '8inch',
                  child: Text('8 inch'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPvcType = value;
                });
              },
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(ledgerFilterProvider.notifier).state =
                          LedgerFilter(
                        billNumber: _billNumberController.text.isNotEmpty
                            ? _billNumberController.text
                            : null,
                        address: _addressController.text.isNotEmpty
                            ? _addressController.text
                            : null,
                        agentId: _selectedAgentId,
                        depthType: _selectedDepthType,
                        pvcType: _selectedPvcType,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
