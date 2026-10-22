import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/agent.dart';
import '../../core/models/ledger_types.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/ledger_types_provider.dart';
import '../../core/theme/app_colors.dart';

// Add, edit and delete agent dialogs. Shared by the Agents screen and the
// Portfolio agents section (v2.0.1).

void showAddAgentDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final ratesKey = GlobalKey<CommissionRatesFieldsState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Agent'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter agent name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional notes',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CommissionRatesFields(key: ratesKey),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }

            // Check if agent with same name exists
            final existing = ref
                .read(agentsProvider.notifier)
                .getAgentByName(nameController.text.trim());
            if (existing != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('An agent with this name already exists')),
              );
              return;
            }

            final rates = ratesKey.currentState!.collect();
            ref.read(agentsProvider.notifier).addAgent(
                  nameController.text.trim(),
                  phone: phoneController.text.trim().isNotEmpty
                      ? phoneController.text.trim()
                      : null,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                  depthCommissionRate: rates.depth,
                  pvcCommissionRate: rates.pvc,
                  msPipeCommissionRate: rates.ms,
                  commissionRatesJson: rates.json,
                );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Agent added'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

void showEditAgentDialog(BuildContext context, WidgetRef ref, Agent agent) {
  final nameController = TextEditingController(text: agent.name);
  final phoneController = TextEditingController(text: agent.phone ?? '');
  final notesController = TextEditingController(text: agent.notes ?? '');
  final ratesKey = GlobalKey<CommissionRatesFieldsState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Agent'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CommissionRatesFields(key: ratesKey, agent: agent),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }

            final rates = ratesKey.currentState!.collect();
            final updated = agent.copyWith(
              name: nameController.text.trim(),
              phone: phoneController.text.trim().isNotEmpty
                  ? phoneController.text.trim()
                  : null,
              notes: notesController.text.trim().isNotEmpty
                  ? notesController.text.trim()
                  : null,
              depthCommissionRate: rates.depth,
              pvcCommissionRate: rates.pvc,
              msPipeCommissionRate: rates.ms,
              commissionRatesJson: rates.json,
            );
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            ref.read(agentsProvider.notifier).updateAgent(updated).then((n) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(n == 0
                      ? 'Agent updated'
                      : 'Agent updated. Commission changed on $n '
                          '${n == 1 ? 'bill' : 'bills'}'),
                  backgroundColor: AppColors.success,
                ),
              );
            });
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void showDeleteAgentDialog(
  BuildContext context,
  WidgetRef ref,
  Agent agent,
  List<Agent> allAgents,
) {
  final billCount = ref.read(agentBillCountsProvider)[agent.id] ?? 0;
  String? reassignToAgentId;
  final otherAgents = allAgents.where((a) => a.id != agent.id).toList();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Delete Agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${agent.name}"?',
                style: const TextStyle(fontSize: 16),
              ),
              if (billCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This agent has $billCount ledger ${billCount == 1 ? 'entry' : 'entries'}.',
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What would you like to do with these entries?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                RadioListTile<String?>(
                  value: null,
                  groupValue: reassignToAgentId,
                  onChanged: (value) {
                    setState(() {
                      reassignToAgentId = value;
                    });
                  },
                  title: const Text('Delete all entries'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (otherAgents.isNotEmpty) ...[
                  RadioListTile<String?>(
                    value: 'reassign',
                    groupValue: reassignToAgentId == null ? null : 'reassign',
                    onChanged: (value) {
                      setState(() {
                        reassignToAgentId = otherAgents.first.id;
                      });
                    },
                    title: const Text('Reassign to another agent'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  if (reassignToAgentId != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: DropdownButtonFormField<String>(
                        value: reassignToAgentId,
                        decoration: const InputDecoration(
                          labelText: 'Select agent',
                          isDense: true,
                        ),
                        items: otherAgents
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            reassignToAgentId = value;
                          });
                        },
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(agentsProvider.notifier)
                  .deleteAgent(agent.id, reassignToAgentId: reassignToAgentId);
              ref.read(ledgerEntriesProvider.notifier).refresh();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(reassignToAgentId != null
                      ? 'Agent deleted and entries reassigned'
                      : 'Agent and entries deleted'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ),
  );
}

/// What the commission fields collected.
typedef CommissionRatesValue = ({
  double depth,
  double pvc,
  double ms,
  String json
});

/// Commission prices (Rs per foot) of an agent: one field per depth, PVC and
/// MS pipe type (the user-defined lists), plus a default for types that have
/// no price. A bill takes the price of its own type when it is created and the
/// rate stays editable on the bill. Never part of a bill total.
class CommissionRatesFields extends ConsumerStatefulWidget {
  final Agent? agent;
  const CommissionRatesFields({super.key, this.agent});

  @override
  ConsumerState<CommissionRatesFields> createState() =>
      CommissionRatesFieldsState();
}

class CommissionRatesFieldsState extends ConsumerState<CommissionRatesFields> {
  final _typed = <String, TextEditingController>{};
  late final TextEditingController _defaultDepth;
  late final TextEditingController _defaultPvc;
  late final TextEditingController _defaultMs;

  static String _text(double? v) => (v == null || v == 0) ? '' : v.toString();

  @override
  void initState() {
    super.initState();
    final types = ref.read(ledgerTypesProvider);
    final agent = widget.agent;
    final rates = agent?.commissionRates ?? const <String, double>{};
    for (final c in LedgerTypeCategory.values) {
      for (final t in types.forCategory(c)) {
        final key = Agent.rateKey(c.name, t);
        _typed[key] = TextEditingController(text: _text(rates[key]));
      }
    }
    _defaultDepth =
        TextEditingController(text: _text(agent?.depthCommissionRate));
    _defaultPvc = TextEditingController(text: _text(agent?.pvcCommissionRate));
    _defaultMs =
        TextEditingController(text: _text(agent?.msPipeCommissionRate));
  }

  @override
  void dispose() {
    for (final c in _typed.values) {
      c.dispose();
    }
    _defaultDepth.dispose();
    _defaultPvc.dispose();
    _defaultMs.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  /// The defaults and the per-type prices as typed (empty field = no price).
  CommissionRatesValue collect() {
    final rates = <String, double>{};
    _typed.forEach((key, c) {
      final v = double.tryParse(c.text);
      if (v != null && c.text.trim().isNotEmpty) rates[key] = v;
    });
    return (
      depth: _val(_defaultDepth),
      pvc: _val(_defaultPvc),
      ms: _val(_defaultMs),
      json: Agent.encodeRates(rates),
    );
  }

  Widget _field(TextEditingController c, String label, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixText: '₹ ',
            suffixText: 'per ft',
          ),
        ),
      );

  Widget _group(String title, LedgerTypeCategory c, LedgerTypes types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary)),
        ),
        for (final t in types.forCategory(c))
          if (_typed.containsKey(Agent.rateKey(c.name, t)))
            _field(_typed[Agent.rateKey(c.name, t)]!, t, hint: 'default'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(ledgerTypesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Commission (price per foot)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        const Text(
            'Set a price for each type. A bill takes the price of its type. '
            'Empty uses the default below. Not added to bill totals.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        _group('Depth', LedgerTypeCategory.depth, types),
        _group('PVC', LedgerTypeCategory.pvc, types),
        _group('MS pipe', LedgerTypeCategory.ms, types),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6),
          child: Text('Default for types without a price',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary)),
        ),
        _field(_defaultDepth, 'Depth'),
        _field(_defaultPvc, 'PVC'),
        _field(_defaultMs, 'MS pipe'),
      ],
    );
  }
}
