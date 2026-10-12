import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';

/// Evaluates "12+3.5*2" style expressions (+ - * / and decimals, left to right
/// with the usual precedence). Returns null for incomplete or invalid input
/// and for division by zero.
double? evaluateCashExpression(String input) {
  final src = input.replaceAll(',', '').replaceAll(' ', '');
  if (src.isEmpty) return null;
  final nums = <double>[];
  final ops = <String>[];

  int prec(String op) => (op == '*' || op == '/') ? 2 : 1;

  bool apply() {
    if (nums.length < 2 || ops.isEmpty) return false;
    final b = nums.removeLast();
    final a = nums.removeLast();
    final op = ops.removeLast();
    switch (op) {
      case '+':
        nums.add(a + b);
      case '-':
        nums.add(a - b);
      case '*':
        nums.add(a * b);
      case '/':
        if (b == 0) return false;
        nums.add(a / b);
    }
    return true;
  }

  var i = 0;
  var expectNumber = true;
  while (i < src.length) {
    final c = src[i];
    if (expectNumber) {
      var j = i;
      while (j < src.length && RegExp(r'[0-9.]').hasMatch(src[j])) {
        j++;
      }
      if (j == i) return null;
      final v = double.tryParse(src.substring(i, j));
      if (v == null) return null;
      nums.add(v);
      i = j;
      expectNumber = false;
    } else {
      if (!'+-*/'.contains(c)) return null;
      while (ops.isNotEmpty && prec(ops.last) >= prec(c)) {
        if (!apply()) return null;
      }
      ops.add(c);
      i++;
      expectNumber = true;
    }
  }
  if (expectNumber) return null;
  while (ops.isNotEmpty) {
    if (!apply()) return null;
  }
  return nums.length == 1 ? CashbookCalculator.roundMoney(nums.single) : null;
}

/// Calculator bottom sheet for the amount field (PARITY-026). Returns the
/// result when the user taps "Use", or null when dismissed.
Future<double?> showCashCalculatorSheet(BuildContext context,
    {double? initial}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CalculatorSheet(initial: initial),
  );
}

class _CalculatorSheet extends StatefulWidget {
  final double? initial;
  const _CalculatorSheet({this.initial});

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  late String _expr;

  @override
  void initState() {
    super.initState();
    _expr = widget.initial == null || widget.initial == 0
        ? ''
        : CashbookCalculator.formatNumber(widget.initial!).replaceAll(',', '');
  }

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
        case 'DEL':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '=':
          final r = evaluateCashExpression(_expr);
          if (r != null) {
            _expr = CashbookCalculator.formatNumber(r).replaceAll(',', '');
          }
        default:
          _expr += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = evaluateCashExpression(_expr);
    const keys = [
      ['7', '8', '9', '/'],
      ['4', '5', '6', '*'],
      ['1', '2', '3', '-'],
      ['.', '0', '00', '+'],
      ['C', 'DEL', '000', '='],
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_expr.isEmpty ? '0' : _expr,
                      style: const TextStyle(
                          fontSize: 22, color: AppColors.textSecondary)),
                  Text(
                    result == null
                        ? ''
                        : CashbookCalculator.formatNumber(result),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final row in keys)
              Row(
                children: [
                  for (final k in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: '+-*/='.contains(k)
                                  ? AppColors.primary
                                  : AppColors.surface,
                              foregroundColor: '+-*/='.contains(k)
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _press(k),
                            child: k == 'DEL'
                                ? const Icon(Icons.backspace_outlined)
                                : Text(k, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: result == null
                    ? null
                    : () => Navigator.pop(context, result),
                child: const Text('Use'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
