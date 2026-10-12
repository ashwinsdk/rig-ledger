import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/features/cashbook/cashbook_calculator_sheet.dart';
import 'package:rig_ledger/features/cashbook/cashbook_items_dialog.dart';

void main() {
  test('evaluateCashExpression precedence and decimals', () {
    expect(evaluateCashExpression('12+3.5*2'), 19);
    expect(evaluateCashExpression('100-30-20'), 50);
    expect(evaluateCashExpression('10/4'), 2.5);
    expect(evaluateCashExpression('1,000+500'), 1500);
  });

  test('evaluateCashExpression rejects invalid input', () {
    expect(evaluateCashExpression(''), isNull);
    expect(evaluateCashExpression('5+'), isNull);
    expect(evaluateCashExpression('5/0'), isNull);
    expect(evaluateCashExpression('+5'), isNull);
    expect(evaluateCashExpression('1..2+3'), isNull);
  });

  test('CashItem round trip and totals', () {
    final items = [
      const CashItem(name: 'Pipe', quantity: 3, unit: 'pc', rate: 12.5),
      const CashItem(name: 'Cap', quantity: 1, rate: 4),
    ];
    final decoded = CashItem.decodeList(CashItem.encodeList(items));
    expect(decoded.length, 2);
    expect(decoded.first.name, 'Pipe');
    expect(CashItem.totalOf(decoded), 41.5);
    expect(CashItem.decodeList('not json'), isEmpty);
    expect(CashItem.encodeList([]), isNull);
  });
}
