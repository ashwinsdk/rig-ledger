import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/providers/agent_provider.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';
import 'package:rig_ledger/features/ledger_form/ledger_form_screen.dart';

/// Agent commission prices in the dialogs and on the bill (bug 3, v2.0.1).
void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('agent_commission_bill_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('the bill follows the price of the chosen type', (t) async {
    t.view.physicalSize = const Size(900, 3600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() async {
      await container
          .read(ledgerTypesProvider.notifier)
          .addType(LedgerTypeCategory.depth, '9');
      await container.read(agentsProvider.notifier).addAgent('Karthik',
          depthCommissionRate: 10,
          commissionRatesJson: Agent.encodeRates({'depth:9inch': 15}));
    });

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LedgerFormScreen()),
    ));
    await t.pump(const Duration(milliseconds: 300));

    // pick the agent
    await t.tap(find.text('Select agent'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Karthik').last);
    await t.pump(const Duration(milliseconds: 300));

    double depthRate() => double.parse(
        (t.widget(find.widgetWithText(TextFormField, 'Depth rate (₹/ft)'))
                    as TextFormField)
                .controller
                ?.text ??
            '0');
    expect(depthRate(), 10); // 7inch has no price: the default

    // choose 9inch
    await t.tap(find.byType(DropdownButtonFormField<String>).first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('9inch').last);
    await t.pump(const Duration(milliseconds: 300));
    expect(depthRate(), 15);

    // a typed rate is kept when the type changes
    await t.enterText(
        find.widgetWithText(TextFormField, 'Depth rate (₹/ft)'), '20');
    await t.tap(find.byType(DropdownButtonFormField<String>).first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('7inch').last);
    await t.pump(const Duration(milliseconds: 300));
    expect(depthRate(), 20);
  });
}
