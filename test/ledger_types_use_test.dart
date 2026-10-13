import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_types.dart';
import 'package:rig_ledger/core/providers/ledger_types_provider.dart';
import 'package:rig_ledger/core/utils/feet_totals.dart';
import 'package:rig_ledger/features/ledger_form/ledger_form_screen.dart';

LedgerEntry bill(String id,
    {String depth = '7inch', double ft = 100, String pvc = '7inch'}) {
  final now = DateTime(2026, 1, 1);
  return LedgerEntry(
    id: id,
    date: now,
    billNumber: id,
    agentId: 'a',
    agentName: 'A',
    address: 'X',
    depth: depth,
    depthInFeet: ft,
    depthPerFeetRate: 10,
    pvc: pvc,
    pvcInFeet: 20,
    msPipe: '6inch',
    msPipeInFeet: 5,
    extraCharges: 0,
    total: 1000,
    isTotalManuallyEdited: false,
    received: 0,
    balance: 1000,
    less: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('feet totals follow the type list and drop nothing', () {
    final types =
        LedgerTypes.defaults().copyWith(depth: const ['7inch', '9inch']);
    final t = FeetTotals.compute([
      bill('1', depth: '7inch', ft: 100),
      bill('2', depth: '9inch', ft: 50),
      bill('3', depth: '12inch', ft: 25), // not in the list
    ], types);
    expect(t.depth['7inch'], 100);
    expect(t.depth['9inch'], 50);
    expect(t.depth['12inch'], 25); // shown anyway
    expect(t.depth.containsKey('8inch'), isFalse);
    expect(t.depthTotal, 175);
    expect(t.pvc['7inch'], 60);
    expect(t.msPipeTotal, 15);
    // Listed types with no bills still show (zero).
    expect(FeetTotals.compute(const [], types).depth, {'7inch': 0, '9inch': 0});
  });

  group('forms and import', () {
    late Directory dir;

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('ledger_types_use_test');
      Hive.init(dir.path);
      await DatabaseService.initialize();
    });

    tearDownAll(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('the bill form offers a new type and survives an unlisted one',
        (t) async {
      t.view.physicalSize = const Size(900, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await t.runAsync(() async {
        await container
            .read(ledgerTypesProvider.notifier)
            .addType(LedgerTypeCategory.depth, '9');
      });

      // An old bill whose type is not in the list opens without an assertion.
      final old = bill('old', depth: '11inch');
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: LedgerFormScreen(entry: old)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.text('11inch'), findsWidgets); // its own value is selectable

      // Open the depth dropdown: the new 9inch is offered.
      await t.tap(find.byType(DropdownButtonFormField<String>).first);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('9inch'), findsWidgets);
      expect(find.text('7inch'), findsWidgets);
    });

    test('import keeps new sizes: they join the lists', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(ledgerTypesProvider.notifier);
      await n.ensureTypes(LedgerTypeCategory.ms, ['10inch', 'weird', '']);
      expect(c.read(ledgerTypesProvider).ms, containsAll(['6inch', '10inch']));
      expect(c.read(ledgerTypesProvider).ms.contains('weird'), isFalse);
    });
  });
}
