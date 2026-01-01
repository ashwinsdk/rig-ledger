import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bit_entry.dart';
import '../../../core/providers/side_ledger_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'bit_form_screen.dart';

class BitListScreen extends ConsumerStatefulWidget {
  const BitListScreen({super.key});

  @override
  ConsumerState<BitListScreen> createState() => _BitListScreenState();
}

class _BitListScreenState extends ConsumerState<BitListScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bitEntriesProvider.notifier).refresh();
    });
  }

  List<BitEntry> _applyFilters(List<BitEntry> entries, BitFilter filter) {
    var filtered = entries;

    if (filter.type != null && filter.type!.isNotEmpty) {
      filtered = filtered.where((e) => e.type == filter.type).toList();
    }

    if (filter.startDate != null) {
      filtered =
          filtered.where((e) => !e.date.isBefore(filter.startDate!)).toList();
    }

    if (filter.endDate != null) {
      final endOfDay = DateTime(filter.endDate!.year, filter.endDate!.month,
          filter.endDate!.day, 23, 59, 59);
      filtered = filtered.where((e) => !e.date.isAfter(endOfDay)).toList();
    }

    // Sort by date descending (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _BitFilterSheet(),
    );
  }

  Future<void> _confirmDelete(BitEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
            'Are you sure you want to delete bit entry #${entry.billNumber}?'),
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
      await ref.read(bitEntriesProvider.notifier).deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case '6.5 inch':
        return Colors.teal;
      case '7.25 inch':
        return Colors.blue;
      case '7.5 inch':
        return Colors.indigo;
      case '9 inch':
        return Colors.purple;
      case '9.5 inch':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(bitEntriesProvider);
    final filter = ref.watch(bitFilterProvider);
    final filteredEntries = _applyFilters(entries, filter);

    // Calculate totals by type
    Map<String, int> countByType = {};
    double totalAmount = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (final entry in filteredEntries) {
      // Use type details if available
      final details = entry.typeDetails;
      if (details != null && details.isNotEmpty) {
        for (final detail in details) {
          countByType[detail.type] =
              (countByType[detail.type] ?? 0) + detail.count;
        }
      } else {
        countByType[entry.type] = (countByType[entry.type] ?? 0) + entry.count;
      }
      totalAmount += entry.calculatedTotal;
      totalPaid += entry.paid;
      totalPending += entry.pending;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
            ),
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
                        'Bit Ledger',
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
                          icon: const Icon(Icons.filter_list,
                              color: Colors.white),
                          onPressed: _showFilterSheet,
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
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.purple.shade800],
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
                // Type counts
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: countByType.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                        'Total', _currencyFormat.format(totalAmount)),
                    _buildSummaryItem(
                        'Paid', _currencyFormat.format(totalPaid)),
                    _buildSummaryItem(
                        'Pending', _currencyFormat.format(totalPending)),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter.hasFilters
                              ? 'No entries match your filters'
                              : 'No bit entries yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (filter.hasFilters)
                          TextButton(
                            onPressed: () {
                              ref.read(bitFilterProvider.notifier).state =
                                  const BitFilter();
                            },
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _BitEntryCard(
                        entry: entry,
                        dateFormat: _dateFormat,
                        currencyFormat: _currencyFormat,
                        typeColor: _getTypeColor(entry.type),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BitFormScreen(entry: entry),
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
          MaterialPageRoute(builder: (_) => const BitFormScreen()),
        ),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BitEntryCard extends StatelessWidget {
  final BitEntry entry;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final Color typeColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BitEntryCard({
    required this.entry,
    required this.dateFormat,
    required this.currencyFormat,
    required this.typeColor,
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
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${entry.billNumber}',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(entry.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
              const SizedBox(height: 12),

              // Highlighted values - Type, Count, Total
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightBox(entry.displayType, typeColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHighlightBox(
                        '${entry.totalCount} pcs', Colors.indigo),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHighlightBox(
                      currencyFormat.format(entry.calculatedTotal),
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type details (if multiple)
              if (entry.typeDetails != null &&
                  entry.typeDetails!.length > 1) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.typeDetails!.map((detail) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${detail.type}: ${detail.count} × ₹${detail.rate.toStringAsFixed(0)} = ₹${detail.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bit ID and payment info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (entry.bitId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.bitId,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      Text(
                        'Paid: ${currencyFormat.format(entry.paid)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                      if (!isPaid) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Due: ${currencyFormat.format(entry.pending)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildHighlightBox(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BitFilterSheet extends ConsumerStatefulWidget {
  const _BitFilterSheet();

  @override
  ConsumerState<_BitFilterSheet> createState() => _BitFilterSheetState();
}

class _BitFilterSheetState extends ConsumerState<_BitFilterSheet> {
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  static const List<String> bitTypes = [
    '6.5 inch',
    '7.25 inch',
    '7.5 inch',
    '9 inch',
    '9.5 inch',
  ];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(bitFilterProvider);
    _selectedType = filter.type;
    _startDate = filter.startDate;
    _endDate = filter.endDate;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    ref.read(bitFilterProvider.notifier).state = BitFilter(
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    ref.read(bitFilterProvider.notifier).state = const BitFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type filter
          const Text(
            'Bit Type',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bitTypes.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date range
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _startDate != null
                        ? dateFormat.format(_startDate!)
                        : 'Start Date',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _endDate != null
                        ? dateFormat.format(_endDate!)
                        : 'End Date',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
