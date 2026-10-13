import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/vehicle.dart';
import 'package:rig_ledger/core/providers/ledger_provider.dart';
import 'package:rig_ledger/core/providers/rig_switch.dart';
import 'package:rig_ledger/core/providers/side_ledger_provider.dart';
import 'package:rig_ledger/core/providers/vehicle_provider.dart';

/// switchRig (LR-01): one implementation for the Ledger header, the Portfolio
/// header and Vehicle Management.
void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('switch_rig_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('switching clears search and filters and changes the rig',
      (t) async {
    late WidgetRef captured;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        }),
      ),
    ));

    final second = Vehicle(
      id: 'rig_two',
      name: 'Side Rig',
      vehicleTypeIndex: 1,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    await t.runAsync(
        () => captured.read(vehiclesProvider.notifier).addVehicle(second));

    final first = captured.read(currentVehicleProvider)!;
    captured.read(searchQueryProvider.notifier).state = 'salem';
    captured.read(ledgerFilterProvider.notifier).state =
        const LedgerFilter(depthType: '8inch');
    captured.read(dieselFilterProvider.notifier).state =
        const DieselFilter(bunk: 'x');

    // Same rig: nothing happens.
    expect(await t.runAsync(() => switchRig(captured, first)), isFalse);
    expect(captured.read(searchQueryProvider), 'salem');

    // Other rig: stored and provider state change, filters are cleared.
    expect(await t.runAsync(() => switchRig(captured, second)), isTrue);
    expect(captured.read(currentVehicleProvider)!.id, 'rig_two');
    expect(DatabaseService.getCurrentVehicle()!.id, 'rig_two');
    expect(captured.read(searchQueryProvider), '');
    expect(captured.read(ledgerFilterProvider).hasFilters, isFalse);
    expect(captured.read(dieselFilterProvider).bunk, isNull);
  });
}
