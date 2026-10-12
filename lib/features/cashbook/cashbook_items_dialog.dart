import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import 'widgets/cashbook_common.dart';

/// One line item of an entry ("Add Items").
class CashItem {
  final String name;
  final double quantity;
  final String unit;
  final double rate;

  const CashItem({
    required this.name,
    required this.quantity,
    this.unit = '',
    required this.rate,
  });

  double get total => CashbookCalculator.roundMoney(quantity * rate);

  Map<String, dynamic> toJson() =>
      {'name': name, 'quantity': quantity, 'unit': unit, 'rate': rate};

  factory CashItem.fromJson(Map<String, dynamic> m) => CashItem(
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? '',
        rate: (m['rate'] as num?)?.toDouble() ?? 0,
      );

  static String? encodeList(List<CashItem> items) =>
      items.isEmpty ? null : jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CashItem> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List)
          .map((e) => CashItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static double totalOf(List<CashItem> items) =>
      CashbookCalculator.sumMoney(items.map((e) => e.total));
}

/// "Add Items" dialog (PARITY-029). Returns the edited list, or null when
/// cancelled.
Future<List<CashItem>?> showCashItemsDialog(
    BuildContext context, List<CashItem> initial) {
  return showDialog<List<CashItem>>(
    context: context,
    builder: (_) => _ItemsDialog(initial: initial),
  );
}

class _ItemsDialog extends StatefulWidget {
  final List<CashItem> initial;
  const _ItemsDialog({required this.initial});

  @override
  State<_ItemsDialog> createState() => _ItemsDialogState();
}

class _ItemsDialogState extends State<_ItemsDialog> {
  late final List<CashItem> _items = List.of(widget.initial);
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _unit = TextEditingController();
  final _rate = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _add() {
    final qty = parseAmount(_qty.text);
    final rate = parseAmount(_rate.text);
    if (_name.text.trim().isEmpty || qty == null || rate == null) {
      showCashSnack(context, 'Enter item, quantity and rate', error: true);
      return;
    }
    setState(() {
      _items.add(CashItem(
          name: _name.text.trim(),
          quantity: qty,
          unit: _unit.text.trim(),
          rate: rate));
      _name.clear();
      _qty.clear();
      _unit.clear();
      _rate.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const num = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: const Text('Add Items'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Item')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                        controller: _qty,
                        keyboardType: num,
                        inputFormatters: [AmountInputFormatter()],
                        decoration:
                            const InputDecoration(labelText: 'Quantity')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Unit')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                        controller: _rate,
                        keyboardType: num,
                        inputFormatters: [AmountInputFormatter()],
                        decoration: const InputDecoration(labelText: 'Rate')),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add')),
              ),
              Row(
                children: [
                  Text('Item (${_items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                      'Total ${CashbookCalculator.formatNumber(CashItem.totalOf(_items))}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const Divider(),
              for (var i = 0; i < _items.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_items[i].name),
                  subtitle: Text(
                      '${CashbookCalculator.formatNumber(_items[i].quantity)} ${_items[i].unit} x ${CashbookCalculator.formatNumber(_items[i].rate)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(CashbookCalculator.formatNumber(_items[i].total)),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.error),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, _items),
            child: const Text('OK')),
      ],
    );
  }
}
