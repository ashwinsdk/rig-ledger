import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/features/ledger_form/widgets/commission_section.dart';

void main() {
  testWidgets('commission section shows separate totals', (t) async {
    final depth = TextEditingController(text: '10');
    final pvc = TextEditingController(text: '5');
    final ms = TextEditingController(text: '2');
    final total = TextEditingController(text: '1250.00');
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CommissionSection(
            rows: [
              CommissionRow(
                  category: 'depth',
                  label: 'Depth 7inch',
                  feet: 100,
                  rate: depth),
              CommissionRow(
                  category: 'pvc', label: 'PVC 7inch', feet: 50, rate: pvc),
              CommissionRow(
                  category: 'ms', label: 'MS pipe 6inch', feet: 0, rate: ms),
            ],
            commission: total,
            isManual: true,
            onChanged: () {},
            onManualChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(find.text('Depth commission'), findsOneWidget);
    expect(find.text('PVC commission'), findsOneWidget);
    expect(find.text('MS pipe commission'), findsOneWidget);
    expect(find.text('Total commission'), findsOneWidget);
    expect(find.text('manual'), findsOneWidget);
    expect(find.text('₹1,000'), findsOneWidget);
    expect(find.text('₹250'), findsWidgets);
    expect(find.text('₹1,250'), findsOneWidget);
  });
}
