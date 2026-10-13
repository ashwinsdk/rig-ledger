import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_service.dart';
import '../../core/models/ledger_types.dart';
import '../../core/providers/ledger_types_provider.dart';
import '../../core/theme/app_colors.dart';

/// Settings > Ledger Types: add, rename and delete the depth, PVC and MS pipe
/// types that bills offer (v2.0.1). Renaming changes every bill that uses the
/// type; a type that bills use cannot be deleted.
class LedgerTypesScreen extends ConsumerWidget {
  const LedgerTypesScreen({super.key});

  Future<String?> _askSize(BuildContext context, String title,
      {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Size in inches',
            hintText: 'for example 9 or 9.5',
            suffixText: 'inch',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
    ));
  }

  Future<void> _add(
      BuildContext context, WidgetRef ref, LedgerTypeCategory c) async {
    final input = await _askSize(context, 'Add ${c.shortName} type');
    if (input == null || !context.mounted) return;
    final (ok, err) =
        await ref.read(ledgerTypesProvider.notifier).addType(c, input);
    if (!ok && context.mounted) _snack(context, err!, error: true);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref,
      LedgerTypeCategory c, String type) async {
    final input = await _askSize(context, 'Rename $type',
        initial: LedgerTypes.inchesOf(type));
    if (input == null || !context.mounted) return;
    final (ok, err) =
        await ref.read(ledgerTypesProvider.notifier).renameType(c, type, input);
    if (!context.mounted) return;
    if (!ok) {
      _snack(context, err!, error: true);
    } else {
      _snack(context, 'Renamed. Bills now use the new name.');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref,
      LedgerTypeCategory c, String type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete type'),
        content: Text('Delete $type from the ${c.shortName} types?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final (done, err) =
        await ref.read(ledgerTypesProvider.notifier).deleteType(c, type);
    if (!done && context.mounted) _snack(context, err!, error: true);
  }

  Future<void> _pickStep(
      BuildContext context, WidgetRef ref, String type, String? current) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Step rate for $type'),
        children: [
          for (final o in const [
            ('none', 'No step rate'),
            ('7inch', 'Use the 7 inch table'),
            ('8inch', 'Use the 8 inch table'),
          ])
            RadioListTile<String>(
              value: o.$1,
              groupValue: current ?? 'none',
              title: Text(o.$2),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await ref
        .read(ledgerTypesProvider.notifier)
        .setStepTable(type, choice == 'none' ? null : choice);
  }

  Widget _section(BuildContext context, WidgetRef ref, LedgerTypes types,
      LedgerTypeCategory c) {
    final list = types.forCategory(c);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: () => _add(context, ref, c),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            for (final type in list)
              _TypeRow(
                type: type,
                bills: DatabaseService.countBillsWithType(c, type),
                stepText: c == LedgerTypeCategory.depth
                    ? switch (types.stepTableFor(type)) {
                        '7inch' => 'Step rate: 7 inch table',
                        '8inch' => 'Step rate: 8 inch table',
                        _ => 'No step rate',
                      }
                    : null,
                onStep: c == LedgerTypeCategory.depth
                    ? () =>
                        _pickStep(context, ref, type, types.stepTableFor(type))
                    : null,
                onRename: () => _rename(context, ref, c, type),
                onDelete: () => _delete(context, ref, c, type),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(ledgerTypesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ledger Types'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(
              'These are the sizes a bill offers for depth, PVC and MS pipe. '
              'Renaming a size updates every bill that uses it. A size that '
              'bills use cannot be deleted.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          for (final c in LedgerTypeCategory.values)
            _section(context, ref, types, c),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final String type;
  final int bills;
  final String? stepText;
  final VoidCallback? onStep;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _TypeRow({
    required this.type,
    required this.bills,
    required this.onRename,
    required this.onDelete,
    this.stepText,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 0, right: 0),
      title: Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        [
          '$bills ${bills == 1 ? 'bill' : 'bills'}',
          if (stepText != null) stepText!,
        ].join('  |  '),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      onTap: onStep,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'Rename',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: onRename),
          IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete),
        ],
      ),
    );
  }
}
