import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/cashbook_common.dart';

/// Short how-to for the Account Ledger (PARITY-077 "Help").
class CashbookHelpScreen extends StatelessWidget {
  const CashbookHelpScreen({super.key});

  static const _items = <(String, String)>[
    (
      'What is Account Ledger?',
      'A cash book. Each book (account) has dated Income and Expense entries. '
          'Balances and totals are calculated from the entries, they are never typed in.'
    ),
    (
      'Receivers and bill payments',
      'A receiver is a book. When you add a payment to a bill and pick "Received by", '
          'the amount appears as Income in that book. Editing it in the book also edits '
          'the bill. Deleting it in the book keeps the payment on the bill without a receiver.'
    ),
    (
      'Previous Balance',
      'In Daily, Weekly, Monthly and Yearly views the list starts from the balance '
          'before the period. Turn this off in Account Ledger settings.'
    ),
    (
      'Deleted transactions',
      'Deleted transactions stay in Deleted Transactions for 30 days. You can restore '
          'them there. After 30 days they are removed permanently.'
    ),
    (
      'Transfer',
      'Moves money between two books. It creates an Expense in the first book and an '
          'Income in the second one. Each side can be edited on its own.'
    ),
    (
      'Reports',
      'The report button creates a PDF or CSV of what is on screen (period, search and '
          'filters apply). Report-All Accounts covers every book.'
    ),
    (
      'Backup',
      'Account Ledger data is included in the normal RigLedger backup and in Google Drive sync. '
          'Use Settings > Backup & Restore.'
    ),
    (
      'Import',
      'Import from cashbook app reads a backup .db file made with that app. You see a dry run '
          'first, and importing the same file twice does not create duplicates.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: cashAppBar('Help'),
      body: CashPageBody(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (title, body) in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.35)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
