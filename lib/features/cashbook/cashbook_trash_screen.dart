import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_service.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/cashbook_common.dart';

/// Deleted Transactions (PARITY-053..056). Entries are removed automatically
/// 30 days after deletion.
class CashbookTrashScreen extends ConsumerWidget {
  const CashbookTrashScreen({super.key});

  String _bookName(WidgetRef ref, CashEntry e) {
    final books = ref.read(cashBooksProvider);
    for (final b in books) {
      if (b.id == e.bookId) return b.name;
    }
    return e.bookNameSnapshot ?? 'Deleted account';
  }

  int _daysLeft(CashEntry e) {
    final deleted = e.deletedAt ?? DateTime.now();
    final expires = deleted.add(DatabaseService.cashTrashRetention);
    final d = expires.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d + 1;
  }

  Future<void> _rowMenu(
      BuildContext context, WidgetRef ref, CashEntry e) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore'),
                onTap: () => Navigator.pop(ctx, 'restore')),
            ListTile(
                leading:
                    const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(ctx, 'delete')),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final notifier = ref.read(cashEntriesProvider.notifier);
    if (choice == 'delete') {
      final ok = await confirmCashDialog(context,
          title: 'Delete Transaction',
          message: 'This transaction will be deleted permanently.');
      if (ok) await notifier.purge(e.id);
      return;
    }
    // Restore. If the book no longer exists the user picks another one.
    final books = ref.read(cashBooksProvider);
    String? target;
    if (!books.any((b) => b.id == e.bookId)) {
      target = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Restore into account'),
          children: [
            for (final b in books)
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, b.id),
                  child: Text(b.name)),
          ],
        ),
      );
      if (target == null) return;
    }
    await notifier.restore(e.id, toBookId: target);
    if (context.mounted) showCashSnack(context, 'Transaction restored');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(cashTrashProvider);
    final settings = ref.watch(cashSettingsProvider);
    ref.watch(cashBooksProvider);

    return Scaffold(
      appBar: cashAppBar('Deleted Transactions', actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'all') {
              final ok = await confirmCashDialog(context,
                  title: 'Delete All',
                  message:
                      'All deleted transactions will be removed permanently.');
              if (ok) await ref.read(cashEntriesProvider.notifier).emptyTrash();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'all', child: Text('Delete All')),
          ],
        ),
      ]),
      body: CashPageBody(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                'Deleted transactions are removed automatically after 30 days.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: trash.isEmpty
                  ? const Center(
                      child: Text('No deleted transactions',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.separated(
                      itemCount: trash.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = trash[i];
                        final color =
                            e.isCashIn ? CashColors.income : CashColors.expense;
                        return ListTile(
                          onTap: () => _rowMenu(context, ref, e),
                          title: Text(e.notes.isEmpty ? '-' : e.notes,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${settings.formatDayHeader(e.date)} ${settings.formatTime(e.date)}\n'
                              '${_bookName(ref, e)}  |  ${_daysLeft(e)} days left',
                              style: const TextStyle(fontSize: 12)),
                          isThreeLine: true,
                          trailing: Text(settings.formatMoney(e.amount),
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700)),
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
