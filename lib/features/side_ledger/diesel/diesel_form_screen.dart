import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/diesel_entry.dart';
import '../../../core/providers/side_ledger_provider.dart';

class DieselFormScreen extends ConsumerStatefulWidget {
  final DieselEntry? entry;

  const DieselFormScreen({super.key, this.entry});

  @override
  ConsumerState<DieselFormScreen> createState() => _DieselFormScreenState();
}

class _DieselFormScreenState extends ConsumerState<DieselFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late TextEditingController _billNumberController;
  late TextEditingController _litreController;
  late TextEditingController _rateController;
  late TextEditingController _paidController;
  late TextEditingController _bunkController;
  late TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  DateTime? _paidDate;
  double _total = 0;
  double _pending = 0;
  double _balance = 0;

  bool get isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _billNumberController = TextEditingController(
      text: entry?.billNumber ?? '',
    );
    _litreController = TextEditingController(
      text: entry?.litre.toString() ?? '',
    );
    _rateController = TextEditingController(
      text: entry?.rate.toString() ?? '',
    );
    _paidController = TextEditingController(
      text: entry?.paid.toString() ?? '0',
    );
    _bunkController = TextEditingController(
      text: entry?.bunkDetails ?? '',
    );
    _notesController = TextEditingController(
      text: entry?.notes ?? '',
    );

    if (entry != null) {
      _selectedDate = entry.date;
      _paidDate = entry.paidDate;
      _total = entry.total;
      _pending = entry.pending;
      _balance = entry.balance;
    }

    _litreController.addListener(_recalculate);
    _rateController.addListener(_recalculate);
    _paidController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _litreController.dispose();
    _rateController.dispose();
    _paidController.dispose();
    _bunkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final litre = double.tryParse(_litreController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final paid = double.tryParse(_paidController.text) ?? 0;

    setState(() {
      _total = litre * rate;
      _pending = _total - paid;
      _balance = paid - _total;
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

  Future<void> _selectPaidDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _paidDate = picked);
    }
  }

  bool _isBillNumberUnique(String billNumber) {
    if (billNumber.isEmpty) return true;

    final vehicleId = DatabaseService.currentVehicleId;
    final entries = DatabaseService.getDieselEntriesByVehicle(vehicleId);

    for (final entry in entries) {
      if (entry.billNumber == billNumber) {
        // If editing, skip the current entry
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
    final entry = DieselEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      vehicleId: DatabaseService.currentVehicleId,
      date: _selectedDate,
      billNumber: billNumber,
      litre: double.tryParse(_litreController.text) ?? 0,
      rate: double.tryParse(_rateController.text) ?? 0,
      total: _total,
      paid: double.tryParse(_paidController.text) ?? 0,
      pending: _pending,
      balance: _balance,
      paidDate: _paidDate,
      bunkDetails: _bunkController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEditing) {
      await ref.read(dieselEntriesProvider.notifier).updateEntry(entry);
    } else {
      await ref.read(dieselEntriesProvider.notifier).addEntry(entry);
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Diesel Entry' : 'Add Diesel Entry'),
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
                leading: const Icon(Icons.calendar_today, color: Colors.orange),
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

            // Litre and Rate row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _litreController,
                    decoration: const InputDecoration(
                      labelText: 'Litres *',
                      hintText: '0.0',
                      prefixIcon: Icon(Icons.local_gas_station),
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
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate/L *',
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

            // Pending/Balance display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _pending > 0
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pending > 0
                      ? Colors.red.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _pending > 0 ? 'Pending' : 'Balance (Advance)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat
                        .format(_pending > 0 ? _pending : _balance.abs()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _pending > 0 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Paid date
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: const Text('Paid Date (Optional)'),
                subtitle: Text(
                  _paidDate != null
                      ? _dateFormat.format(_paidDate!)
                      : 'Not set',
                ),
                trailing: _paidDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _paidDate = null),
                      )
                    : null,
                onTap: _selectPaidDate,
              ),
            ),
            const SizedBox(height: 16),

            // Bunk details
            TextFormField(
              controller: _bunkController,
              decoration: const InputDecoration(
                labelText: 'Bunk Details',
                hintText: 'Enter bunk name or location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
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
                backgroundColor: Colors.orange,
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
