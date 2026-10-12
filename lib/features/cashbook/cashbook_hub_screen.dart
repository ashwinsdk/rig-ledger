import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/platform_helper.dart';
import 'cashbook_books_screen.dart';
import 'cashbook_home_screen.dart';
import 'cashbook_entry_form_screen.dart';
import 'cashbook_transfer_screen.dart';
import 'cashbook_trash_screen.dart';

class _HubItem {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
  const _HubItem(this.icon, this.label, this.builder);
}

/// Destinations of the Account Ledger (replaces the reference app's drawer).
final List<_HubItem> _hubItems = [
  _HubItem(Icons.account_balance_wallet_outlined, 'Accounts',
      (_) => const CashbookBooksScreen()),
  _HubItem(Icons.swap_horiz, 'Transfer', (_) => const CashbookTransferScreen()),
  _HubItem(Icons.delete_sweep_outlined, 'Deleted Transactions',
      (_) => const CashbookTrashScreen()),
];

/// Account Ledger tab root (PARITY-077, 083). Mobile: ledger home with a
/// drawer holding the destinations. Desktop (wide): two panes, destinations on
/// the left and the ledger on the right.
class CashbookRootScreen extends ConsumerStatefulWidget {
  const CashbookRootScreen({super.key});

  @override
  ConsumerState<CashbookRootScreen> createState() => _CashbookRootScreenState();
}

class _CashbookRootScreenState extends ConsumerState<CashbookRootScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _open(_HubItem item) {
    Navigator.of(context).push(MaterialPageRoute(builder: item.builder));
  }

  @override
  Widget build(BuildContext context) {
    final wide = PlatformHelper.isDesktop &&
        MediaQuery.of(context).size.width >= PlatformHelper.wideBreakpoint;

    if (wide) {
      return Row(
        children: [
          SizedBox(
            width: 260,
            child: _HubPanel(onSelect: _open),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: CashbookHomeScreen()),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: _HubPanel(onSelect: (item) {
          Navigator.pop(context); // close drawer
          _open(item);
        }),
      ),
      body: CashbookHomeScreen(
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }
}

class _HubPanel extends ConsumerWidget {
  final void Function(_HubItem) onSelect;
  const _HubPanel({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(currentCashBookProvider);
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration:
                  const BoxDecoration(gradient: AppColors.appBarGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text('Account Ledger',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Text(book?.name ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in _hubItems)
                    ListTile(
                      leading: Icon(item.icon, color: AppColors.primary),
                      title: Text(item.label),
                      onTap: () => onSelect(item),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the add form for the current book (Cmd+N on desktop).
void openCashbookNewEntry(BuildContext context, WidgetRef ref) {
  final book = ref.read(currentCashBookProvider);
  if (book == null) return;
  Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          CashbookEntryFormScreen(bookId: book.id, initialCashIn: true)));
}
