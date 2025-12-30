import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/agent.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/agent_provider.dart';

class LedgerFormScreen extends ConsumerStatefulWidget {
  final LedgerEntry? entry;

  const LedgerFormScreen({super.key, this.entry});

  @override
  ConsumerState<LedgerFormScreen> createState() => _LedgerFormScreenState();
}

class _LedgerFormScreenState extends ConsumerState<LedgerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late DateTime _date;
  late TextEditingController _billNumberController;
  Agent? _selectedAgent;
  late TextEditingController _addressController;
  String _depth = '7inch';
  late TextEditingController _depthInFeetController;
  late TextEditingController _depthPerFeetRateController;
  String _pvc = '7inch';
  late TextEditingController _pvcRateController;
  late TextEditingController _msPipeController;
  late TextEditingController _msPipeRateController;
  late TextEditingController _extraChargesController;
  late TextEditingController _totalController;
  bool _isTotalManuallyEdited = false;
  late TextEditingController _receivedController;
  late TextEditingController _balanceController;
  late TextEditingController _lessController;
  late TextEditingController _notesController;

  bool get isEditing => widget.entry != null;
  LedgerEntry? _deletedEntry;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _date = entry?.date ?? DateTime.now();
    _billNumberController =
        TextEditingController(text: entry?.billNumber ?? '');
    _addressController = TextEditingController(text: entry?.address ?? '');
    _depth = entry?.depth ?? '7inch';
    _depthInFeetController =
        TextEditingController(text: entry?.depthInFeet.toString() ?? '0');
    _depthPerFeetRateController =
        TextEditingController(text: entry?.depthPerFeetRate.toString() ?? '0');
    _pvc = entry?.pvc ?? '7inch';
    _pvcRateController =
        TextEditingController(text: entry?.pvcRate.toString() ?? '0');
    _msPipeController = TextEditingController(text: entry?.msPipe ?? '');
    _msPipeRateController =
        TextEditingController(text: entry?.msPipeRate.toString() ?? '0');
    _extraChargesController =
        TextEditingController(text: entry?.extraCharges.toString() ?? '0');
    _totalController =
        TextEditingController(text: entry?.total.toString() ?? '0');
    _isTotalManuallyEdited = entry?.isTotalManuallyEdited ?? false;
    _receivedController =
        TextEditingController(text: entry?.received.toString() ?? '0');
    _balanceController =
        TextEditingController(text: entry?.balance.toString() ?? '0');
    _lessController =
        TextEditingController(text: entry?.less.toString() ?? '0');
    _notesController = TextEditingController(text: entry?.notes ?? '');

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
    _depthInFeetController.addListener(_updateCalculatedTotal);
    _depthPerFeetRateController.addListener(_updateCalculatedTotal);
    _pvcRateController.addListener(_updateCalculatedTotal);
    _msPipeRateController.addListener(_updateCalculatedTotal);
    _extraChargesController.addListener(_updateCalculatedTotal);
    _receivedController.addListener(_updateBalance);
    _lessController.addListener(_updateBalance);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _addressController.dispose();
    _depthInFeetController.dispose();
    _depthPerFeetRateController.dispose();
    _pvcRateController.dispose();
    _msPipeController.dispose();
    _msPipeRateController.dispose();
    _extraChargesController.dispose();
    _totalController.dispose();
    _receivedController.dispose();
    _balanceController.dispose();
    _lessController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCalculatedTotal() {
    if (_isTotalManuallyEdited) return;

    final depthInFeet = double.tryParse(_depthInFeetController.text) ?? 0;
    final depthRate = double.tryParse(_depthPerFeetRateController.text) ?? 0;
    final pvcRate = double.tryParse(_pvcRateController.text) ?? 0;
    final msPipeRate = double.tryParse(_msPipeRateController.text) ?? 0;
    final extraCharges = double.tryParse(_extraChargesController.text) ?? 0;

    final total = LedgerEntry.calculateTotal(
      depthInFeet: depthInFeet,
      depthPerFeetRate: depthRate,
      pvcRate: pvcRate,
      msPipeRate: msPipeRate,
      extraCharges: extraCharges,
    );

    _totalController.text = total.toStringAsFixed(2);
    _updateBalance();
  }

  void _updateBalance() {
    final total = double.tryParse(_totalController.text) ?? 0;
    final received = double.tryParse(_receivedController.text) ?? 0;
    final less = double.tryParse(_lessController.text) ?? 0;

    final balance = LedgerEntry.calculateBalance(
      total: total,
      received: received,
      less: less,
    );

    _balanceController.text = balance.toStringAsFixed(2);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _showAddAgentDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Agent Name *',
                hintText: 'Enter agent name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agent name is required')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final agent = await ref.read(agentsProvider.notifier).addAgent(
            nameController.text.trim(),
            phone: phoneController.text.trim().isNotEmpty
                ? phoneController.text.trim()
                : null,
          );
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

    final entry = LedgerEntry(
      id: widget.entry?.id ?? _uuid.v4(),
      date: _date,
      billNumber: _billNumberController.text.trim(),
      agentId: _selectedAgent!.id,
      agentName: _selectedAgent!.name,
      address: _addressController.text.trim(),
      depth: _depth,
      depthInFeet: double.tryParse(_depthInFeetController.text) ?? 0,
      depthPerFeetRate: double.tryParse(_depthPerFeetRateController.text) ?? 0,
      pvc: _pvc,
      pvcRate: double.tryParse(_pvcRateController.text) ?? 0,
      msPipe: _msPipeController.text.trim(),
      msPipeRate: double.tryParse(_msPipeRateController.text) ?? 0,
      extraCharges: double.tryParse(_extraChargesController.text) ?? 0,
      total: double.tryParse(_totalController.text) ?? 0,
      isTotalManuallyEdited: _isTotalManuallyEdited,
      received: double.tryParse(_receivedController.text) ?? 0,
      balance: double.tryParse(_balanceController.text) ?? 0,
      less: double.tryParse(_lessController.text) ?? 0,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
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
      _deletedEntry = widget.entry;
      await ref
          .read(ledgerEntriesProvider.notifier)
          .deleteEntry(widget.entry!.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                if (_deletedEntry != null) {
                  ref
                      .read(ledgerEntriesProvider.notifier)
                      .addEntry(_deletedEntry!);
                }
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider);
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
              decoration: const InputDecoration(
                hintText: 'Enter bill number',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bill number is required';
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

            // Address
            _buildSectionTitle('Address (City)'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter city/address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
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
                  child: DropdownButtonFormField<String>(
                    value: _depth,
                    decoration: const InputDecoration(
                      labelText: 'Depth Type',
                    ),
                    items: ['7inch', '8inch']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _depth = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depthInFeetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Depth (feet)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _depthPerFeetRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Depth per feet rate',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),

            // PVC Section
            _buildSectionTitle('PVC Details'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pvc,
                    decoration: const InputDecoration(
                      labelText: 'PVC Type',
                    ),
                    items: ['7inch', '8inch']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _pvc = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pvcRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PVC Rate',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // MS Pipe Section
            _buildSectionTitle('MS Pipe Details'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _msPipeController,
                    decoration: const InputDecoration(
                      labelText: 'MS Pipe',
                      hintText: 'Enter MS pipe details',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _msPipeRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'MS Pipe Rate',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Extra Charges
            TextFormField(
              controller: _extraChargesController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Extra Charges',
                prefixIcon: Icon(Icons.add_circle_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Calculation Preview
            _buildCalculationPreview(),
            const SizedBox(height: 24),

            // Total (with manual override)
            _buildSectionTitle('Total'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calculate),
                      suffixIcon: _isTotalManuallyEdited
                          ? const Tooltip(
                              message: 'Manually edited',
                              child: Icon(Icons.edit, color: AppColors.warning),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (!_isTotalManuallyEdited) {
                        setState(() {
                          _isTotalManuallyEdited = true;
                        });
                      }
                      _updateBalance();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (_isTotalManuallyEdited)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isTotalManuallyEdited = false;
                      });
                      _updateCalculatedTotal();
                    },
                    child: const Text('Auto'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Received
            TextFormField(
              controller: _receivedController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Received',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Less (Discounts)
            TextFormField(
              controller: _lessController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Less (Discounts/Deductions)',
                prefixIcon: Icon(Icons.remove_circle_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Balance
            TextFormField(
              controller: _balanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Balance',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              readOnly: true,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveEntry,
                child: Text(isEditing ? 'Update Entry' : 'Save Entry'),
              ),
            ),
            const SizedBox(height: 32),
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

  Widget _buildCalculationPreview() {
    final depthInFeet = double.tryParse(_depthInFeetController.text) ?? 0;
    final depthRate = double.tryParse(_depthPerFeetRateController.text) ?? 0;
    final pvcRate = double.tryParse(_pvcRateController.text) ?? 0;
    final msPipeRate = double.tryParse(_msPipeRateController.text) ?? 0;
    final extraCharges = double.tryParse(_extraChargesController.text) ?? 0;
    final format = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculation Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalcRow('Depth ($depthInFeet ft × $depthRate)',
              format.format(depthInFeet * depthRate)),
          _buildCalcRow('PVC Rate', format.format(pvcRate)),
          _buildCalcRow('MS Pipe Rate', format.format(msPipeRate)),
          _buildCalcRow('Extra Charges', format.format(extraCharges)),
          const Divider(),
          _buildCalcRow(
            'Total',
            format.format(LedgerEntry.calculateTotal(
              depthInFeet: depthInFeet,
              depthPerFeetRate: depthRate,
              pvcRate: pvcRate,
              msPipeRate: msPipeRate,
              extraCharges: extraCharges,
            )),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBold ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
