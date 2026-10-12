import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_payment.dart';
import 'package:rig_ledger/features/ledger_form/widgets/payment_log_editor.dart';

void main() {
  late Directory dir;

  Future<void> pumpUntil(WidgetTester t, bool Function() cond,
      {int maxMs = 8000}) async {
    var waited = 0;
    while (!cond() && waited < maxMs) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 25)));
      await t.pump(const Duration(milliseconds: 100));
      waited += 25;
    }
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('paydlg_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('add a payment with a brand new receiver', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    var payments = <LedgerPayment>[];
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (ctx, setState) => SingleChildScrollView(
              child: PaymentLogEditor(
                payments: payments,
                baseCash: 0,
                basePhonePe: 0,
                allowPhonePe: true,
                onChanged: (l) => setState(() => payments = l),
                onBaseChanged: (c, p) {},
              ),
            ),
          ),
        ),
      ),
    ));
    await pumpUntil(t, () => false, maxMs: 150);

    await t.tap(find.text('Add payment'));
    await pumpUntil(t, () => false, maxMs: 150);
    await t.enterText(find.widgetWithText(TextField, 'Amount (₹)'), '20000');

    // Choose "New receiver" in the dropdown and create it.
    await t.tap(find.text('No receiver'));
    await pumpUntil(t, () => false, maxMs: 150);
    await t.tap(find.text('New receiver').last);
    await pumpUntil(t, () => false, maxMs: 150);
    await t.enterText(find.widgetWithText(TextField, 'Name'), 'Ravi');
    await t.tap(find.widgetWithText(ElevatedButton, 'Add'));
    // Regression: disposing the name controller right after the prompt closed
    // used to throw while the dialog was still animating out.
    await pumpUntil(t,
        () => DatabaseService.getAllCashBooks().any((b) => b.name == 'Ravi'));
    await pumpUntil(t, () => false, maxMs: 500);
    final ravi =
        DatabaseService.getAllCashBooks().firstWhere((b) => b.name == 'Ravi');
    expect(ravi.isReceiver, isTrue);
    expect(t.takeException(), isNull);
  });
}
