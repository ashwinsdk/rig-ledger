import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_book.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'cashbook_book_dialogs.dart';
import 'widgets/cashbook_common.dart';

/// Accounts screen (PARITY-007): search, list, ADD ACCOUNT, row menu with
/// Edit, Delete and Opening Balance.
class CashbookBooksScreen extends ConsumerStatefulWidget {
  const CashbookBooksScreen({super.key});

  @override
  ConsumerState<CashbookBooksScreen> createState() =>
      _CashbookBooksScreenState();
}

class _CashbookBooksScreenState extends ConsumerState<CashbookBooksScreen> {
  String _query = '';

  Future<void> _rowMenu(CashBook book) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(book.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(book.isReceiver ? 'Receiver book' : 'Custom book'),
            ),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(ctx, 'delete')),
            ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Opening Balance'),
                onTap: () => Navigator.pop(ctx, 'opening')),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'edit':
        await showRenameCashBookDialog(context, ref, book);
      case 'delete':
        if (ref.read(cashBooksProvider).length <= 1) {
          showCashSnack(context, 'Cannot delete the last book', error: true);
          return;
        }
        await confirmDeleteCashBook(context, ref, book);
      case 'opening':
        await showOpeningBalanceDialog(context, ref, book);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(cashEntriesProvider);
    final books = ref
        .watch(cashBooksProvider)
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final settings = ref.watch(cashSettingsProvider);

    return Scaffold(
      appBar: cashAppBar('Accounts', actions: [
        TextButton(
          onPressed: () => showAddCashBookDialog(context),
          child: const Text('ADD ACCOUNT',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
      body: CashPageBody(
        maxWidth: 700,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final b = books[i];
                  final mine = entries.where((e) => e.bookId == b.id);
                  final totals = CashbookCalculator.totals(mine);
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(b.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          b.isReceiver ? 'Receiver book' : 'Custom book',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      trailing: Text(
                        settings.formatMoney(totals.balance),
                        style: TextStyle(
                          color: totals.balance < 0
                              ? CashColors.expense
                              : CashColors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _rowMenu(b),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
