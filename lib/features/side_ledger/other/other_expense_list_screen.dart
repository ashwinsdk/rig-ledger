import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/other_expense_entry.dart';
import '../../../core/providers/side_ledger_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'other_expense_form_screen.dart';

class OtherExpenseListScreen extends ConsumerStatefulWidget {
  const OtherExpenseListScreen({super.key});

  @override
  ConsumerState<OtherExpenseListScreen> createState() =>
      _OtherExpenseListScreenState();
}

class _OtherExpenseListScreenState
    extends ConsumerState<OtherExpenseListScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otherExpenseEntriesProvider.notifier).refresh();
    });
  }

  List<OtherExpenseEntry> _applyFilter(
      List<OtherExpenseEntry> entries, OtherExpenseFilter filter) {
    var out = entries;
    if (filter.startDate != null) {
      out = out.where((e) => !e.date.isBefore(filter.startDate!)).toList();
    }
    if (filter.endDate != null) {
      final end = DateTime(filter.endDate!.year, filter.endDate!.month,
          filter.endDate!.day, 23, 59, 59);
      out = out.where((e) => !e.date.isAfter(end)).toList();
    }
    return [...out]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _pickRange() async {
    final current = ref.read(otherExpenseFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: current.startDate != null && current.endDate != null
          ? DateTimeRange(start: current.startDate!, end: current.endDate!)
          : null,
    );
    if (picked != null) {
      ref.read(otherExpenseFilterProvider.notifier).state =
          OtherExpenseFilter(startDate: picked.start, endDate: picked.end);
    }
  }

  Future<void> _confirmDelete(OtherExpenseEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content:
            Text('Are you sure you want to delete "${entry.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(otherExpenseEntriesProvider.notifier)
          .deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(otherExpenseEntriesProvider);
    final filter = ref.watch(otherExpenseFilterProvider);
    final shown = _applyFilter(entries, filter);

    var totalAmount = 0.0, totalPaid = 0.0, totalPending = 0.0;
    for (final e in shown) {
      totalAmount += e.total;
      totalPaid += e.paid;
      totalPending += e.pending;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Other Expenses',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.date_range, color: Colors.white),
                          tooltip: 'Filter by date',
                          onPressed: _pickRange,
                        ),
                        if (filter.hasFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade500, Colors.purple.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _summaryItem('Entries', shown.length.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem('Total', _currencyFormat.format(totalAmount)),
                    _summaryItem('Paid', _currencyFormat.format(totalPaid)),
                    _summaryItem(
                        'Pending', _currencyFormat.format(totalPending)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          filter.hasFilters
                              ? 'No entries in this date range'
                              : 'No other expenses yet',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                        if (filter.hasFilters)
                          TextButton(
                            onPressed: () => ref
                                .read(otherExpenseFilterProvider.notifier)
                                .state = const OtherExpenseFilter(),
                            child: const Text('Clear Filter'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final entry = shown[i];
                      return _OtherExpenseCard(
                        entry: entry,
                        dateFormat: _dateFormat,
                        currencyFormat: _currencyFormat,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OtherExpenseFormScreen(entry: entry),
                          ),
                        ),
                        onDelete: () => _confirmDelete(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtherExpenseFormScreen()),
        ),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _OtherExpenseCard extends StatelessWidget {
  final OtherExpenseEntry entry;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OtherExpenseCard({
    required this.entry,
    required this.dateFormat,
    required this.currencyFormat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.pending <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.description,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.shade400,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                entry.billNumber.isEmpty
                    ? dateFormat.format(entry.date)
                    : '#${entry.billNumber}  |  ${dateFormat.format(entry.date)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(entry.total),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  Row(
                    children: [
                      Text('Paid: ${currencyFormat.format(entry.paid)}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 13)),
                      if (!isPaid) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Due: ${currencyFormat.format(entry.pending)}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
