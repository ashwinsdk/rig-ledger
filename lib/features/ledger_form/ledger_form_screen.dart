import '../../core/models/ledger_types.dart';
import '../../core/providers/ledger_types_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/ledger_line.dart';
import '../../core/models/ledger_payment.dart';
import 'widgets/line_editor.dart';
import 'widgets/payment_log_editor.dart';
import 'widgets/address_autocomplete_field.dart';
import 'widgets/commission_section.dart';
import '../../core/models/agent.dart';
import '../../core/database/database_service.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/widgets/adaptive_header.dart';

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

  // Bill lines (v2.0.2): one or more per category
  late List<LineController> _depthLines;
  late List<LineController> _pvcLines;
  late List<LineController> _msLines;
  late TextEditingController _stepRateController;
  bool _isStepRateManuallyEdited = false;

  // Other fields
  late TextEditingController _extraChargesController;
  late TextEditingController _totalController;
  bool _isTotalManuallyEdited = false;
  // Payment log (v2.0.0): main bore receives cash only.
  List<LedgerPayment> _payments = [];
  double _baseCash = 0; // received before payments were logged
  late TextEditingController _balanceController;
  late TextEditingController _lessController;
  late TextEditingController _notesController;

  // Commission (v2.0.0): informational, never part of the total
  late TextEditingController _commissionController;
  bool _isCommissionManuallyEdited = false;

  double get _totalReceived => _baseCash + LedgerPayment.totalCash(_payments);

  bool get isEditing => widget.entry != null;
  bool _isBillNumberDuplicate = false;

  static String _rateText(double? v) =>
      (v == null || v == 0) ? '' : v.toString();

  double _num(TextEditingController c) => double.tryParse(c.text) ?? 0;

  List<LineController> _ctlOf(String category) => switch (category) {
        LedgerLine.pvc => _pvcLines,
        LedgerLine.ms => _msLines,
        _ => _depthLines,
      };

  LedgerTypeCategory _typeCat(String category) => switch (category) {
        LedgerLine.pvc => LedgerTypeCategory.pvc,
        LedgerLine.ms => LedgerTypeCategory.ms,
        _ => LedgerTypeCategory.depth,
      };

  /// Every line the user entered, in category order.
  List<LedgerLine> get _allLines => [
        for (final c in LedgerLine.categories)
          for (final l in _ctlOf(c)) l.toLine(c),
      ];

  List<CommissionRow> get _commissionRows => [
        for (final c in LedgerLine.categories)
          for (final (i, l) in _ctlOf(c).indexed)
            CommissionRow(
              category: c,
              label: _ctlOf(c).length > 1
                  ? '${_catTitle(c)} ${i + 1} ${l.type}'
                  : '${_catTitle(c)} ${l.type}',
              feet: l.feetValue,
              rate: l.comm,
            ),
      ];

  static String _catTitle(String c) => switch (c) {
        LedgerLine.pvc => 'PVC',
        LedgerLine.ms => 'MS pipe',
        _ => 'Depth',
      };

  /// Recomputes commission unless the user typed an override.
  void _updateCommission() {
    if (_isCommissionManuallyEdited) return;
    final c = CommissionSection.calculate(_commissionRows);
    _commissionController.text = c.toStringAsFixed(2);
  }

  /// New bills start with the agent's price for the type of each line.
  void _applyAgentCommissionDefaults(Agent agent) {
    if (isEditing) return;
    for (final c in LedgerLine.categories) {
      for (final l in _ctlOf(c)) {
        l.comm.text = _rateText(agent.rateFor(c, l.type));
      }
    }
    _updateCommission();
  }

  /// A type changed: the commission rate follows the agent's price for the
  /// new type, unless the rate was typed by hand (it no longer equals the
  /// agent's price for the old type).
  void _followTypePrice(String category, String oldType, String newType,
      TextEditingController c) {
    final agent = _selectedAgent;
    if (agent == null) return;
    final typed = double.tryParse(c.text) ?? 0;
    if (c.text.trim().isNotEmpty && typed != agent.rateFor(category, oldType)) {
      return;
    }
    c.text = _rateText(agent.rateFor(category, newType));
    _updateCommission();
  }

  void _wire(LineController l) =>
      l.addListeners(_onCalculationFieldChanged, _onCommissionFieldChanged);

  LineController _newLine(String category, {String? type}) {
    final types = ref.read(ledgerTypesProvider);
    final t = type ?? types.forCategory(_typeCat(category)).first;
    final line = LineController(type: t);
    final agent = _selectedAgent;
    if (agent != null) line.comm.text = _rateText(agent.rateFor(category, t));
    _wire(line);
    return line;
  }

  void _addLine(String category) {
    setState(() => _ctlOf(category).add(_newLine(category)));
    _onCalculationFieldChanged();
  }

  void _removeLine(String category, int index) {
    final list = _ctlOf(category);
    if (list.length <= 1) return;
    setState(() => list.removeAt(index).dispose());
    _onCalculationFieldChanged();
  }

  void _lineTypeChanged(String category, int i, String old, String neu) {
    setState(() {});
    _followTypePrice(category, old, neu, _ctlOf(category)[i].comm);
    _onCalculationFieldChanged();
  }

  Widget _linesSection(String category, String title) => LinesSection(
        category: category,
        title: title,
        types: ref.watch(ledgerTypesProvider),
        lines: _ctlOf(category),
        onAdd: () => _addLine(category),
        onRemove: (i) => _removeLine(category, i),
        onTypeChanged: (i, o, n) => _lineTypeChanged(category, i, o, n),
        onChanged: _onCalculationFieldChanged,
      );

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _date = entry?.date ?? DateTime.now();
    _billNumberController =
        TextEditingController(text: entry?.billNumber ?? '');
    _addressController = TextEditingController(text: entry?.address ?? '');

    // Lines: the saved ones, at least one per category
    final types = ref.read(ledgerTypesProvider);
    List<LineController> build(String c, String fallbackType) {
      final saved = entry?.linesOf(c) ?? const <LedgerLine>[];
      if (saved.isEmpty) {
        return [LineController(type: fallbackType)];
      }
      return [for (final l in saved) LineController.fromLine(l)];
    }

    _depthLines = build(LedgerLine.depth, entry?.depth ?? types.depth.first);
    _pvcLines = build(LedgerLine.pvc, entry?.pvc ?? types.pvc.first);
    _msLines = build(LedgerLine.ms, entry?.msPipe ?? types.ms.first);
    _stepRateController =
        TextEditingController(text: entry?.stepRate.toString() ?? '0');
    _isStepRateManuallyEdited = entry?.isStepRateManuallyEdited ?? false;

    // Other
    _extraChargesController =
        TextEditingController(text: entry?.extraCharges.toString() ?? '0');
    _totalController =
        TextEditingController(text: entry?.total.toString() ?? '0');
    _isTotalManuallyEdited = entry?.isTotalManuallyEdited ?? false;
    _payments = entry?.payments ?? [];
    _baseCash = entry?.unloggedCash ?? 0;
    _balanceController =
        TextEditingController(text: entry?.balance.toString() ?? '0');
    _lessController =
        TextEditingController(text: entry?.less.toString() ?? '0');
    _notesController = TextEditingController(text: entry?.notes ?? '');

    // Commission
    _commissionController = TextEditingController(
        text: (entry?.commission ?? 0).toStringAsFixed(2));
    _isCommissionManuallyEdited = entry?.isCommissionManuallyEdited ?? false;

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

    // Add listeners for calculation - using wrapper that calls setState for live preview
    for (final c in LedgerLine.categories) {
      for (final l in _ctlOf(c)) {
        _wire(l);
      }
    }
    _stepRateController.addListener(_onTotalFieldChanged);
    _extraChargesController.addListener(_onCalculationFieldChanged);
    _lessController.addListener(_onBalanceFieldChanged);
    _billNumberController.addListener(_checkBillNumberDuplicate);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _addressController.dispose();
    for (final c in LedgerLine.categories) {
      for (final l in _ctlOf(c)) {
        l.dispose();
      }
    }
    _stepRateController.dispose();
    _extraChargesController.dispose();
    _totalController.dispose();
    _balanceController.dispose();
    _lessController.dispose();
    _notesController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  // Wrapper methods that call setState for live preview updates
  void _onCalculationFieldChanged() {
    _updateStepRate();
    _updateCommission();
    setState(() {}); // Trigger rebuild for calculation preview
  }

  void _onCommissionFieldChanged() {
    _updateCommission();
    setState(() {});
  }

  void _onTotalFieldChanged() {
    _updateCalculatedTotal();
    setState(() {}); // Trigger rebuild for calculation preview
  }

  void _onBalanceFieldChanged() {
    _updateBalance();
    setState(() {}); // Trigger rebuild for calculation preview
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

  void _updateStepRate() {
    if (_isStepRateManuallyEdited) {
      _updateCalculatedTotal();
      return;
    }

    final stepRate = LedgerEntry.calculateLinesStepRate(
        _allLines, ref.read(ledgerTypesProvider));

    _stepRateController.text = stepRate.toStringAsFixed(2);
    _updateCalculatedTotal();
  }

  void _updateCalculatedTotal() {
    if (_isTotalManuallyEdited) return;

    final total = LedgerEntry.calculateLinesTotal(
      lines: _allLines,
      stepRate: double.tryParse(_stepRateController.text) ?? 0,
      extraCharges: double.tryParse(_extraChargesController.text) ?? 0,
    );

    _totalController.text = total.toStringAsFixed(2);
    _updateBalance();
  }

  void _updateBalance() {
    final total = double.tryParse(_totalController.text) ?? 0;
    final received = _totalReceived;
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
        _applyAgentCommissionDefaults(agent);
      });
    }
  }

  /// Lines to store: empty PVC and MS pipe lines are dropped; depth always
  /// keeps at least its first line.
  List<LedgerLine> _savedLines() {
    final out = <LedgerLine>[];
    for (final c in LedgerLine.categories) {
      final lines = [for (final l in _ctlOf(c)) l];
      final kept = [
        for (final l in lines)
          if (!l.isEmpty) l.toLine(c)
      ];
      if (kept.isEmpty && c == LedgerLine.depth) {
        kept.add(lines.first.toLine(c));
      }
      out.addAll(kept);
    }
    return out;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an agent')),
      );
      return;
    }

    final cash = _totalReceived;
    final totalReceived = cash;

    final entry = LedgerEntry(
      id: widget.entry?.id ?? _uuid.v4(),
      date: _date,
      billNumber: _billNumberController.text.trim(),
      agentId: _selectedAgent!.id,
      agentName: _selectedAgent!.name,
      address: _addressController.text.trim(),
      depth: _depthLines.first.type,
      depthInFeet: 0,
      depthPerFeetRate: 0,
      stepRate: double.tryParse(_stepRateController.text) ?? 0,
      isStepRateManuallyEdited: _isStepRateManuallyEdited,
      pvc: _pvcLines.first.type,
      msPipe: _msLines.first.type,
      extraCharges: double.tryParse(_extraChargesController.text) ?? 0,
      total: double.tryParse(_totalController.text) ?? 0,
      isTotalManuallyEdited: _isTotalManuallyEdited,
      received: totalReceived,
      receivedCash: cash,
      receivedPhonePe: 0, // Main-bore: No PhonePe
      phonePeName: null, // Main-bore: No PhonePe name
      paymentsJson: LedgerPayment.encodeList(_payments),
      commission: _num(_commissionController),
      isCommissionManuallyEdited: _isCommissionManuallyEdited,
      balance: double.tryParse(_balanceController.text) ?? 0,
      less: double.tryParse(_lessController.text) ?? 0,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      vehicleId: widget.entry?.vehicleId ?? DatabaseService.currentVehicleId,
    ).withLines(_savedLines());

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
      body: AdaptiveContent(
        maxWidth: 700,
        child: Form(
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
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
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
              if (_isBillNumberDuplicate)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This bill number already exists. Please use a unique bill number.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          if (agent != null) {
                            _applyAgentCommissionDefaults(agent);
                          }
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
              AddressAutocompleteField(controller: _addressController),
              const SizedBox(height: 24),

              // Depth lines
              _buildSectionTitle('Depth Details'),
              _linesSection(LedgerLine.depth, 'Depth'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stepRateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        labelText: _depthLines.length > 1
                            ? 'Step Rate, all depth lines (₹)'
                            : 'Step Rate (₹)',
                        prefixIcon: const Icon(Icons.trending_up),
                        suffixIcon: _isStepRateManuallyEdited
                            ? const Tooltip(
                                message: 'Manually edited',
                                child: Icon(Icons.edit,
                                    color: AppColors.warning, size: 18),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        if (!_isStepRateManuallyEdited) {
                          setState(() {
                            _isStepRateManuallyEdited = true;
                          });
                        }
                      },
                    ),
                  ),
                  if (_isStepRateManuallyEdited)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isStepRateManuallyEdited = false;
                        });
                        _updateStepRate();
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Auto calculate',
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // PVC lines
              _buildSectionTitle('PVC Details'),
              _linesSection(LedgerLine.pvc, 'PVC'),
              const SizedBox(height: 12),

              // MS pipe lines
              _buildSectionTitle('MS Pipe Details'),
              _linesSection(LedgerLine.ms, 'MS Pipe'),
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
                  labelText: 'Extra Charges (₹)',
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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee),
                        suffixIcon: _isTotalManuallyEdited
                            ? const Tooltip(
                                message: 'Manually edited',
                                child:
                                    Icon(Icons.edit, color: AppColors.warning),
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

              // Commission (not added to total)
              CommissionSection(
                rows: _commissionRows,
                commission: _commissionController,
                isManual: _isCommissionManuallyEdited,
                onChanged: () {
                  _updateCommission();
                  setState(() {});
                },
                onManualChanged: (manual) {
                  setState(() => _isCommissionManuallyEdited = manual);
                  if (!manual) _updateCommission();
                },
              ),
              const SizedBox(height: 16),

              // Payment Section Header
              _buildSectionTitle('Payment'),

              // Payment log: each payment with date and receiver
              PaymentLogEditor(
                payments: _payments,
                baseCash: _baseCash,
                basePhonePe: 0,
                allowPhonePe: false,
                onChanged: (list) {
                  setState(() => _payments = list);
                  _updateBalance();
                },
                onBaseChanged: (cash, _) {
                  setState(() => _baseCash = cash);
                  _updateBalance();
                },
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
                  labelText: 'Less (Discounts/Deductions) (₹)',
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
                  labelText: 'Balance (₹)',
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
    final stepRate = double.tryParse(_stepRateController.text) ?? 0;
    final extraCharges = double.tryParse(_extraChargesController.text) ?? 0;
    final format = NumberFormat('#,##0.00');
    final lines = _allLines;

    String label(String cat, LedgerLine l, int i, int n) {
      final name = switch (cat) {
        LedgerLine.pvc => 'PVC',
        LedgerLine.ms => 'MS Pipe',
        _ => 'Depth',
      };
      final head = n > 1 ? '$name ${i + 1} ${l.type}' : '$name ${l.type}';
      return '$head (${l.feet} ft × ₹${l.rate})';
    }

    final rows = <Widget>[];
    for (final c in LedgerLine.categories) {
      final cl = [
        for (final l in lines)
          if (l.category == c) l
      ];
      for (final (i, l) in cl.indexed) {
        rows.add(_buildCalcRow(
            label(c, l, i, cl.length), '₹${format.format(l.feet * l.rate)}'));
      }
      if (c == LedgerLine.depth) {
        rows.add(_buildCalcRow('Step Rate', '₹${format.format(stepRate)}'));
      }
    }

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
          ...rows,
          _buildCalcRow('Extra Charges', '₹${format.format(extraCharges)}'),
          const Divider(),
          _buildCalcRow(
            'Total',
            '₹${format.format(LedgerEntry.calculateLinesTotal(
              lines: lines,
              stepRate: stepRate,
              extraCharges: extraCharges,
            ))}',
            isBold: true,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Commission (not in total)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          for (final r in _commissionRows)
            _buildCalcRow(
                '${r.label} (${r.feet} ft × ₹${r.rate.text.isEmpty ? 0 : r.rate.text})',
                '₹${format.format(r.amount)}'),
          _buildCalcRow(
            _isCommissionManuallyEdited
                ? 'Total commission (manual)'
                : 'Total commission',
            '₹${format.format(double.tryParse(_commissionController.text) ?? 0)}',
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
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
