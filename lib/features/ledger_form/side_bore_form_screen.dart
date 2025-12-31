import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/agent.dart';
import '../../core/database/database_service.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/agent_provider.dart';

/// Simplified ledger form for side-bore vehicles
/// Fields: Date, Bill Number, Agent, Address (city only), Depth, Rate, Total,
/// Received (cash/phonepe with name), Balance, Less, Notes
class SideBoreFormScreen extends ConsumerStatefulWidget {
  final LedgerEntry? entry;

  const SideBoreFormScreen({super.key, this.entry});

  @override
  ConsumerState<SideBoreFormScreen> createState() => _SideBoreFormScreenState();
}

class _SideBoreFormScreenState extends ConsumerState<SideBoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late DateTime _date;
  late TextEditingController _billNumberController;
  Agent? _selectedAgent;
  late TextEditingController _addressController;

  // Depth fields only (no PVC, no MS Pipe)
  late TextEditingController _depthInFeetController;
  late TextEditingController _depthPerFeetRateController;

  // Payment fields
  late TextEditingController _totalController;
  bool _isTotalManuallyEdited = false;
  late TextEditingController _cashController;
  late TextEditingController _phonePeController;
  late TextEditingController _balanceController;
  late TextEditingController _lessController;
  late TextEditingController _notesController;

  // PhonePe name dropdown
  String? _selectedPhonePeName;

  bool get isEditing => widget.entry != null;
  bool _isBillNumberDuplicate = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _date = entry?.date ?? DateTime.now();
    _billNumberController =
        TextEditingController(text: entry?.billNumber ?? '');
    _addressController = TextEditingController(text: entry?.address ?? '');

    // Depth
    _depthInFeetController =
        TextEditingController(text: entry?.depthInFeet.toString() ?? '0');
    _depthPerFeetRateController =
        TextEditingController(text: entry?.depthPerFeetRate.toString() ?? '0');

    // Payment - now with separate Cash and PhonePe
    _totalController =
        TextEditingController(text: entry?.total.toString() ?? '0');
    _isTotalManuallyEdited = entry?.isTotalManuallyEdited ?? false;
    _cashController =
        TextEditingController(text: entry?.receivedCash.toString() ?? '0');
    _phonePeController =
        TextEditingController(text: entry?.receivedPhonePe.toString() ?? '0');
    _balanceController =
        TextEditingController(text: entry?.balance.toString() ?? '0');
    _lessController =
        TextEditingController(text: entry?.less.toString() ?? '0');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _selectedPhonePeName = entry?.phonePeName;

    // Set selected agent after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entry != null) {
        final agents = ref.read(agentsProvider);
        final agent = agents.where((a) => a.id == entry.agentId).firstOrNull;
        if (agent != null) {
          setState(() {
            _selectedAgent = agent;
          });
        }
      }
    });

    // Add listeners for calculation
    _depthInFeetController.addListener(_recalculate);
    _depthPerFeetRateController.addListener(_recalculate);
    _cashController.addListener(_updateBalance);
    _phonePeController.addListener(_updateBalance);
    _lessController.addListener(_updateBalance);
    _billNumberController.addListener(_checkBillNumberDuplicate);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _addressController.dispose();
    _depthInFeetController.dispose();
    _depthPerFeetRateController.dispose();
    _totalController.dispose();
    _cashController.dispose();
    _phonePeController.dispose();
    _balanceController.dispose();
    _lessController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    if (!_isTotalManuallyEdited) {
      final depth = double.tryParse(_depthInFeetController.text) ?? 0;
      final rate = double.tryParse(_depthPerFeetRateController.text) ?? 0;
      final total = depth * rate;
      _totalController.text = total.toStringAsFixed(2);
    }
    _updateBalance();
    setState(() {});
  }

  void _updateBalance() {
    final total = double.tryParse(_totalController.text) ?? 0;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final phonePe = double.tryParse(_phonePeController.text) ?? 0;
    final received = cash + phonePe;
    final less = double.tryParse(_lessController.text) ?? 0;
    final balance = total - received - less;
    _balanceController.text = balance.toStringAsFixed(2);
    setState(() {});
  }

  double get _totalReceived {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final phonePe = double.tryParse(_phonePeController.text) ?? 0;
    return cash + phonePe;
  }

  void _checkBillNumberDuplicate() {
    final billNumber = _billNumberController.text.trim();
    if (billNumber.isEmpty) {
      if (_isBillNumberDuplicate) {
        setState(() {
          _isBillNumberDuplicate = false;
        });
      }
      return;
    }

    final existingEntries = DatabaseService.getAllLedgerEntries();
    final isDuplicate = existingEntries.any((entry) =>
        entry.billNumber.toLowerCase() == billNumber.toLowerCase() &&
        entry.id != widget.entry?.id);

    if (isDuplicate != _isBillNumberDuplicate) {
      setState(() {
        _isBillNumberDuplicate = isDuplicate;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _showAddAgentDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Agent'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Agent Name',
            hintText: 'Enter agent name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final agent = await ref.read(agentsProvider.notifier).addAgent(result);
      setState(() {
        _selectedAgent = agent;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an agent')),
      );
      return;
    }

    final cash = double.tryParse(_cashController.text) ?? 0;
    final phonePe = double.tryParse(_phonePeController.text) ?? 0;
    final totalReceived = cash + phonePe;

    final entry = LedgerEntry(
      id: widget.entry?.id ?? _uuid.v4(),
      date: _date,
      billNumber: _billNumberController.text.trim(),
      agentId: _selectedAgent!.id,
      agentName: _selectedAgent!.name,
      address: _addressController.text.trim(),
      // For side-bore, we only use depth fields - no step rate, no PVC, no MS Pipe
      depth: '7inch', // Default, not really used for side-bore
      depthInFeet: double.tryParse(_depthInFeetController.text) ?? 0,
      depthPerFeetRate: double.tryParse(_depthPerFeetRateController.text) ?? 0,
      stepRate: 0, // Not used for side-bore
      isStepRateManuallyEdited: false,
      pvc: '7inch', // Default, not used
      pvcInFeet: 0, // Not used for side-bore
      pvcPerFeetRate: 0,
      msPipe: '6inch', // Default, not used
      msPipeInFeet: 0, // Not used for side-bore
      msPipePerFeetRate: 0,
      extraCharges: 0, // Not used for side-bore
      total: double.tryParse(_totalController.text) ?? 0,
      isTotalManuallyEdited: _isTotalManuallyEdited,
      received: totalReceived,
      receivedCash: cash,
      receivedPhonePe: phonePe,
      phonePeName: _selectedPhonePeName,
      balance: double.tryParse(_balanceController.text) ?? 0,
      less: double.tryParse(_lessController.text) ?? 0,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      vehicleId: widget.entry?.vehicleId ?? DatabaseService.currentVehicleId,
    );

    if (isEditing) {
      await ref.read(ledgerEntriesProvider.notifier).updateEntry(entry);
    } else {
      await ref.read(ledgerEntriesProvider.notifier).addEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Entry updated' : 'Entry added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showAddPhonePeNameDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add PhonePe Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter payer name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedPhonePeName = result;
      });
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.entry != null) {
      await ref
          .read(ledgerEntriesProvider.notifier)
          .deleteEntry(widget.entry!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider);
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
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
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteEntry,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            _buildSectionTitle('Date'),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      dateFormat.format(_date),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bill Number
            _buildSectionTitle('Bill Number'),
            TextFormField(
              controller: _billNumberController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Enter bill number',
                prefixIcon: const Icon(Icons.receipt_outlined),
                suffixIcon: _isBillNumberDuplicate
                    ? const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange)
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bill number is required';
                }
                if (_isBillNumberDuplicate) {
                  return 'Bill number already exists';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Agent
            _buildSectionTitle('Agent'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Agent>(
                    value: _selectedAgent,
                    decoration: const InputDecoration(
                      hintText: 'Select agent',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    items: agents
                        .map((agent) => DropdownMenuItem(
                              value: agent,
                              child: Text(agent.name),
                            ))
                        .toList(),
                    onChanged: (agent) {
                      setState(() {
                        _selectedAgent = agent;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an agent';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showAddAgentDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  tooltip: 'Add new agent',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address (City only - single line)
            _buildSectionTitle('Address (City)'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: Icon(Icons.location_city),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Depth Section
            _buildSectionTitle('Depth Details'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _depthInFeetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Depth (ft)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depthPerFeetRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Rate/ft (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total (auto calculated: Depth x Rate)
            _buildSectionTitle('Total'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Depth × Rate = Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currencyFormat.format(
                              double.tryParse(_totalController.text) ?? 0),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isTotalManuallyEdited = !_isTotalManuallyEdited;
                            if (!_isTotalManuallyEdited) {
                              _recalculate();
                            }
                          });
                        },
                        icon: Icon(
                          _isTotalManuallyEdited ? Icons.lock : Icons.lock_open,
                          size: 16,
                        ),
                        label: Text(_isTotalManuallyEdited ? 'Manual' : 'Auto'),
                      ),
                    ],
                  ),
                  if (_isTotalManuallyEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Manual Total',
                          prefixIcon: Icon(Icons.edit),
                        ),
                        onChanged: (_) => _updateBalance(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Section
            _buildSectionTitle('Payment'),

            // Cash Amount
            TextFormField(
              controller: _cashController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Cash Received (₹)',
                prefixIcon: const Icon(Icons.money, color: AppColors.success),
                filled: true,
                fillColor: AppColors.success.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 12),

            // PhonePe Amount and Name
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _phonePeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'PhonePe (₹)',
                      prefixIcon: const Icon(Icons.phone_android,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final phonePeNames = ref.watch(phonePeNamesProvider);
                      final items = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Select name',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        ...phonePeNames.map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            )),
                        const DropdownMenuItem(
                          value: '__add_new__',
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Add new',
                                  style: TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ];

                      return DropdownButtonFormField<String>(
                        value: phonePeNames.contains(_selectedPhonePeName)
                            ? _selectedPhonePeName
                            : '',
                        decoration: InputDecoration(
                          labelText: 'PhonePe Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: AppColors.primary.withOpacity(0.05),
                        ),
                        items: items,
                        onChanged: (value) {
                          if (value == '__add_new__') {
                            _showAddPhonePeNameDialog();
                          } else {
                            setState(() {
                              _selectedPhonePeName = value ?? '';
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Received Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Total Received',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(_totalReceived),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Less Amount
            TextFormField(
              controller: _lessController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Less (₹)',
                prefixIcon: Icon(Icons.remove_circle_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Balance (auto calculated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (double.tryParse(_balanceController.text) ?? 0) > 0
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (double.tryParse(_balanceController.text) ?? 0) > 0
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat
                        .format(double.tryParse(_balanceController.text) ?? 0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: (double.tryParse(_balanceController.text) ?? 0) > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            _buildSectionTitle('Notes (Optional)'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEditing ? 'Update Entry' : 'Save Entry',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
