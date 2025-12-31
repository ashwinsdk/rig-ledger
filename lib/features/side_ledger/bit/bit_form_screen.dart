import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/bit_entry.dart';
import '../../../core/providers/side_ledger_provider.dart';

class BitFormScreen extends ConsumerStatefulWidget {
  final BitEntry? entry;

  const BitFormScreen({super.key, this.entry});

  @override
  ConsumerState<BitFormScreen> createState() => _BitFormScreenState();
}

class _BitFormScreenState extends ConsumerState<BitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  static const List<String> bitTypes = [
    '6.5 inch',
    '7.25 inch',
    '7.5 inch',
    '9 inch',
    '9.5 inch',
  ];

  late TextEditingController _billNumberController;
  late TextEditingController _bitIdController;
  late TextEditingController _countController;
  late TextEditingController _rateController;
  late TextEditingController _paidController;
  late TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  String _selectedType = '6.5 inch';
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
    _bitIdController = TextEditingController(
      text: entry?.bitId ?? '',
    );
    _countController = TextEditingController(
      text: entry?.count.toString() ?? '',
    );
    _rateController = TextEditingController(
      text: entry?.rate.toString() ?? '',
    );
    _paidController = TextEditingController(
      text: entry?.paid.toString() ?? '0',
    );
    _notesController = TextEditingController(
      text: entry?.notes ?? '',
    );

    if (entry != null) {
      _selectedDate = entry.date;
      _selectedType = entry.type;
      _total = entry.total;
      _pending = entry.pending;
    }

    _countController.addListener(_recalculate);
    _rateController.addListener(_recalculate);
    _paidController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _bitIdController.dispose();
    _countController.dispose();
    _rateController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final count = int.tryParse(_countController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final paid = double.tryParse(_paidController.text) ?? 0;

    setState(() {
      _total = count * rate;
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
    final entries = DatabaseService.getBitEntriesByVehicle(vehicleId);

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
    final entry = BitEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      vehicleId: DatabaseService.currentVehicleId,
      date: _selectedDate,
      billNumber: billNumber,
      type: _selectedType,
      bitId: _bitIdController.text.trim(),
      count: int.tryParse(_countController.text) ?? 0,
      rate: double.tryParse(_rateController.text) ?? 0,
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
      await ref.read(bitEntriesProvider.notifier).updateEntry(entry);
    } else {
      await ref.read(bitEntriesProvider.notifier).addEntry(entry);
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
        return Colors.teal;
      case '7.25 inch':
        return Colors.blue;
      case '7.5 inch':
        return Colors.indigo;
      case '9 inch':
        return Colors.purple;
      case '9.5 inch':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Bit Entry' : 'Add Bit Entry'),
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
                leading: const Icon(Icons.calendar_today, color: Colors.green),
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

            // Bit Type selection
            const Text(
              'Bit Type *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bitTypes.map((type) {
                final isSelected = _selectedType == type;
                final color = _getTypeColor(type);
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? color : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bit ID
            TextFormField(
              controller: _bitIdController,
              decoration: const InputDecoration(
                labelText: 'Bit ID',
                hintText: 'Enter unique bit identifier',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Count and Rate row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    decoration: const InputDecoration(
                      labelText: 'Count *',
                      hintText: '0',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate/pc *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                backgroundColor: Colors.purple,
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
