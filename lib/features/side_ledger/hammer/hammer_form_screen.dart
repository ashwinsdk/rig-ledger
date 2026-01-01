import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/hammer_entry.dart';
import '../../../core/models/type_detail.dart';
import '../../../core/providers/side_ledger_provider.dart';

class HammerFormScreen extends ConsumerStatefulWidget {
  final HammerEntry? entry;

  const HammerFormScreen({super.key, this.entry});

  @override
  ConsumerState<HammerFormScreen> createState() => _HammerFormScreenState();
}

class _HammerFormScreenState extends ConsumerState<HammerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  static const List<String> hammerTypes = ['6.5 inch', '7 inch'];

  late TextEditingController _billNumberController;
  late TextEditingController _hammerNameController;
  late TextEditingController _paidController;
  late TextEditingController _notesController;

  // Per-type controllers for count and rate
  final Map<String, TextEditingController> _countControllers = {};
  final Map<String, TextEditingController> _rateControllers = {};

  DateTime _selectedDate = DateTime.now();
  Set<String> _selectedTypes = {}; // Multi-select types
  double _total = 0;
  double _pending = 0;

  bool get isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _billNumberController = TextEditingController(
      text: entry?.billNumber ?? '',
    );
    _hammerNameController = TextEditingController(
      text: entry?.hammerName ?? '',
    );
    _paidController = TextEditingController(
      text: entry?.paid.toString() ?? '0',
    );
    _notesController = TextEditingController(
      text: entry?.notes ?? '',
    );

    // Initialize controllers for all types
    for (final type in hammerTypes) {
      _countControllers[type] = TextEditingController();
      _rateControllers[type] = TextEditingController();
      _countControllers[type]!.addListener(_recalculate);
      _rateControllers[type]!.addListener(_recalculate);
    }

    if (entry != null) {
      _selectedDate = entry.date;

      // Load type details if available
      final details = entry.typeDetails;
      if (details != null && details.isNotEmpty) {
        for (final detail in details) {
          _selectedTypes.add(detail.type);
          _countControllers[detail.type]?.text = detail.count.toString();
          _rateControllers[detail.type]?.text = detail.rate.toString();
        }
      } else if (entry.types != null && entry.types!.isNotEmpty) {
        // Fallback to old types with shared count/rate
        _selectedTypes = entry.types!.toSet();
        for (final type in _selectedTypes) {
          _countControllers[type]?.text = entry.count.toString();
          _rateControllers[type]?.text = entry.rate.toString();
        }
      } else {
        // Single type fallback
        _selectedTypes = {entry.type};
        _countControllers[entry.type]?.text = entry.count.toString();
        _rateControllers[entry.type]?.text = entry.rate.toString();
      }

      _total = entry.total;
      _pending = entry.pending;
    }

    _paidController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _hammerNameController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    for (final controller in _countControllers.values) {
      controller.dispose();
    }
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recalculate() {
    double total = 0;
    for (final type in _selectedTypes) {
      final count = int.tryParse(_countControllers[type]?.text ?? '') ?? 0;
      final rate = double.tryParse(_rateControllers[type]?.text ?? '') ?? 0;
      total += count * rate;
    }
    final paid = double.tryParse(_paidController.text) ?? 0;

    setState(() {
      _total = total;
      _pending = _total - paid;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isBillNumberUnique(String billNumber) {
    if (billNumber.isEmpty) return true;

    final vehicleId = DatabaseService.currentVehicleId;
    final entries = DatabaseService.getHammerEntriesByVehicle(vehicleId);

    for (final entry in entries) {
      if (entry.billNumber == billNumber) {
        if (isEditing && entry.id == widget.entry!.id) continue;
        return false;
      }
    }
    return true;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one type is selected
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Hammer type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that selected types have count and rate
    for (final type in _selectedTypes) {
      final count = int.tryParse(_countControllers[type]?.text ?? '') ?? 0;
      final rate = double.tryParse(_rateControllers[type]?.text ?? '') ?? 0;
      if (count <= 0 || rate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter count and rate for $type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final billNumber = _billNumberController.text.trim();
    if (!_isBillNumberUnique(billNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill number "$billNumber" already exists'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final typesList = _selectedTypes.toList();

    // Build type details
    final typeDetails = <TypeDetail>[];
    int totalCount = 0;
    for (final type in typesList) {
      final count = int.tryParse(_countControllers[type]?.text ?? '') ?? 0;
      final rate = double.tryParse(_rateControllers[type]?.text ?? '') ?? 0;
      typeDetails.add(TypeDetail(type: type, count: count, rate: rate));
      totalCount += count;
    }

    final entry = HammerEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      vehicleId: DatabaseService.currentVehicleId,
      date: _selectedDate,
      billNumber: billNumber,
      type: typesList.first, // Keep first type for backward compatibility
      types: typesList, // Store all selected types
      typeDetailsJson: TypeDetail.encodeList(typeDetails),
      hammerName: _hammerNameController.text.trim(),
      count: totalCount, // Total count for backward compatibility
      rate: typeDetails.first.rate, // First rate for backward compatibility
      total: _total,
      paid: double.tryParse(_paidController.text) ?? 0,
      pending: _pending,
      balance: (double.tryParse(_paidController.text) ?? 0) - _total,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      await ref.read(hammerEntriesProvider.notifier).updateEntry(entry);
    } else {
      await ref.read(hammerEntriesProvider.notifier).addEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Entry updated' : 'Entry added'),
        ),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case '6.5 inch':
        return Colors.brown;
      case '7 inch':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Hammer Entry' : 'Add Hammer Entry'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF252B49), Color(0xFF315D9A), Color(0xFF618DCE)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.brown),
                title: const Text('Date'),
                subtitle: Text(_dateFormat.format(_selectedDate)),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // Bill number
            TextFormField(
              controller: _billNumberController,
              decoration: const InputDecoration(
                labelText: 'Bill Number *',
                hintText: 'Enter bill number (numeric only)',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a bill number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hammer Type selection (multi-select)
            const Text(
              'Hammer Type * (Select one or more)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hammerTypes.map((type) {
                final isSelected = _selectedTypes.contains(type);
                final color = _getTypeColor(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? color : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                        // Clear values when deselected
                        _countControllers[type]?.clear();
                        _rateControllers[type]?.clear();
                      }
                      _recalculate();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Hammer Name
            TextFormField(
              controller: _hammerNameController,
              decoration: const InputDecoration(
                labelText: 'Hammer Name',
                hintText: 'Enter hammer name/identifier',
                prefixIcon: Icon(Icons.hardware),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Per-type count and rate inputs
            if (_selectedTypes.isNotEmpty) ...[
              const Text(
                'Count & Rate per Type *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...hammerTypes
                  .where((t) => _selectedTypes.contains(t))
                  .map((type) {
                final color = _getTypeColor(type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _countControllers[type],
                              decoration: InputDecoration(
                                labelText: 'Count',
                                hintText: '0',
                                prefixIcon: Icon(Icons.numbers, color: color),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _rateControllers[type],
                              decoration: InputDecoration(
                                labelText: 'Rate/pc',
                                hintText: '0.00',
                                prefixIcon:
                                    Icon(Icons.currency_rupee, color: color),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),

            // Total (read-only, calculated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(_total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Paid amount
            TextFormField(
              controller: _paidController,
              decoration: const InputDecoration(
                labelText: 'Paid Amount',
                hintText: '0',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 16),

            // Pending display
            if (_pending > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_pending),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any additional notes...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isEditing ? 'Update Entry' : 'Save Entry',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
