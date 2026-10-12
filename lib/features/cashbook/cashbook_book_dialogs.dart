import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_book.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'widgets/cashbook_common.dart';

/// Add Account dialog (PARITY-002..005). Returns the created book or null.
/// Creating a book does not switch to it.
Future<CashBook?> showAddCashBookDialog(BuildContext context) {
  return showDialog<CashBook>(
    context: context,
    builder: (_) => const _AddBookDialog(),
  );
}

class _AddBookDialog extends ConsumerStatefulWidget {
  const _AddBookDialog();

  @override
  ConsumerState<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends ConsumerState<_AddBookDialog> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  bool _positive = true;
  bool _receiver = false;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // An empty name closes the dialog and creates nothing (PARITY-003).
    if (_name.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    final (book, error) = await ref.read(cashBooksProvider.notifier).addBook(
          name: _name.text,
          kind: _receiver ? 1 : 0,
          openingBalance: parseAmount(_opening.text) ?? 0,
          openingIsPositive: _positive,
          openingDate: _date,
        );
    if (!mounted) return;
    if (error != null) {
      showCashSnack(context, error, error: true);
      return;
    }
    Navigator.pop(context, book);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    return AlertDialog(
      title: const Text('Add Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _opening,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              decoration: const InputDecoration(
                  labelText: 'Opening Balance [Optional]'),
            ),
            const SizedBox(height: 12),
            CashSignToggle(
                positive: _positive,
                onChanged: (v) => setState(() => _positive = v)),
            const SizedBox(height: 12),
            CashDateField(
                value: _date,
                format: settings.formatDate,
                onChanged: (d) => setState(() => _date = d)),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Receiver book'),
              subtitle: const Text('Receives payments logged on bills'),
              value: _receiver,
              onChanged: (v) => setState(() => _receiver = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Rename dialog (PARITY-008).
Future<void> showRenameCashBookDialog(
    BuildContext context, WidgetRef ref, CashBook book) async {
  final controller = TextEditingController(text: book.name);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Account'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save')),
      ],
    ),
  );
  if (ok != true || !context.mounted) {
    controller.dispose();
    return;
  }
  final (success, error) = await ref
      .read(cashBooksProvider.notifier)
      .renameBook(book.id, controller.text);
  controller.dispose();
  if (!success && context.mounted && error != null) {
    showCashSnack(context, error, error: true);
  }
}

/// Opening Balance dialog (PARITY-011): edits the entry in place.
Future<void> showOpeningBalanceDialog(
    BuildContext context, WidgetRef ref, CashBook book) async {
  final entries = ref.read(cashEntriesProvider);
  final existing = entries
      .where((e) =>
          e.bookId == book.id &&
          !e.isDeleted &&
          e.sourceType == null &&
          e.notes == cashOpeningBalanceNotes)
      .toList()
    ..sort(CashbookCalculator.compareChronological);
  final first = existing.isEmpty ? null : existing.first;
  final controller = TextEditingController(
      text: first == null ? '' : CashbookCalculator.formatNumber(first.amount));
  var positive = first?.isCashIn ?? true;
  var date = first?.date ?? DateTime.now();
  final settings = ref.read(cashSettingsProvider);

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Opening Balance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              CashSignToggle(
                  positive: positive,
                  onChanged: (v) => setState(() => positive = v)),
              const SizedBox(height: 12),
              CashDateField(
                  value: date,
                  format: settings.formatDate,
                  onChanged: (d) => setState(() => date = d)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    ),
  );
  final amount = parseAmount(controller.text) ?? 0;
  controller.dispose();
  if (ok != true || !context.mounted) return;
  final (success, error) =
      await ref.read(cashBooksProvider.notifier).setOpeningBalance(
            bookId: book.id,
            amount: amount,
            isPositive: positive,
            date: date,
          );
  if (!success && context.mounted && error != null) {
    showCashSnack(context, error, error: true);
  }
}

/// Two step delete (PARITY-009). Entries go to the trash (PARITY-010).
Future<void> confirmDeleteCashBook(
    BuildContext context, WidgetRef ref, CashBook book) async {
  final first = await confirmCashDialog(
    context,
    title: 'Delete',
    message:
        'If you delete this account then all transactions in this account will also get deleted',
  );
  if (!first || !context.mounted) return;
  final second = await confirmCashDialog(
    context,
    title: 'Are You Sure ?',
    message: 'Transactions go to Deleted Transactions for 30 days.',
  );
  if (!second) return;
  await ref.read(cashBooksProvider.notifier).deleteBook(book.id);
}
