import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';
import 'package:rig_ledger/features/agents/agent_dialogs.dart';

/// Agent commission prices in the dialogs and on the bill (bug 3, v2.0.1).
void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('agent_commission_widget_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('add agent dialog saves a price per type', (t) async {
    t.view.physicalSize = const Size(900, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.runAsync(() => container
        .read(ledgerTypesProvider.notifier)
        .addType(LedgerTypeCategory.depth, '9'));

    late WidgetRef captured;
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            captured = ref;
            return Builder(
              builder: (ctx) => TextButton(
                  onPressed: () => showAddAgentDialog(ctx, captured),
                  child: const Text('open')),
            );
          }),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 300));

    await t.enterText(find.widgetWithText(TextField, 'Name *'), 'Selvam');
    // One field per depth type: 7inch, 8inch, 9inch.
    await t.enterText(find.widgetWithText(TextField, '9inch').first, '15');
    await t.enterText(find.widgetWithText(TextField, '7inch').first, '11');
    await t.tap(find.text('Add'));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump(const Duration(milliseconds: 300));

    final saved = DatabaseService.getAgentByName('Selvam')!;
    expect(saved.commissionRates['depth:9inch'], 15);
    expect(saved.commissionRates['depth:7inch'], 11);
    expect(saved.commissionRates.containsKey('depth:8inch'), isFalse);
    expect(saved.rateFor('depth', '8inch'), 0); // default
  });
}
