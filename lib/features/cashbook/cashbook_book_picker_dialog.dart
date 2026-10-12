import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_book.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import 'cashbook_book_dialogs.dart';
import 'cashbook_books_screen.dart';

/// Book picker (PARITY-006): "Accounts" title with Edit link, search field,
/// list of books and an "Add Account" row. Returns the selected book.
Future<CashBook?> showCashBookPicker(BuildContext context) {
  return showDialog<CashBook>(
    context: context,
    builder: (_) => const _BookPickerDialog(),
  );
}

class _BookPickerDialog extends ConsumerStatefulWidget {
  const _BookPickerDialog();

  @override
  ConsumerState<_BookPickerDialog> createState() => _BookPickerDialogState();
}

class _BookPickerDialogState extends ConsumerState<_BookPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final books = ref
        .watch(cashBooksProvider)
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final current = ref.watch(currentCashBookProvider);
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Accounts')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CashbookBooksScreen()));
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final b in books)
                    ListTile(
                      dense: true,
                      title: Text(b.name),
                      leading: Icon(
                        b.id == current?.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      trailing: b.isReceiver
                          ? const Icon(Icons.person_pin_outlined,
                              size: 18, color: AppColors.textSecondary)
                          : null,
                      onTap: () => Navigator.pop(context, b),
                    ),
                  if (books.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No books found',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text('Add Account',
                  style: TextStyle(color: AppColors.primary)),
              onTap: () async {
                await showAddCashBookDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
