import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/providers/cashbook_provider.dart';
import 'package:rig_ledger/core/utils/platform_helper.dart';
import 'package:rig_ledger/features/cashbook/cashbook_hub_screen.dart';

/// Account Ledger home on a narrow phone layout (bug 9, v2.0.1): no overflow,
/// period chips in the gradient header, summary card on top.
/// (Each flow file uses its own database; Hive writes started inside a widget
/// test cannot be cleared mid-file, so tests here do not reset the database.)
void main() {
  late Directory dir;

  /// Pumps (fake time) and waits (real time) until [cond] holds. Hive work is
  /// real async work, so a fixed delay is not reliable under load.
  Future<void> pumpUntil(WidgetTester t, bool Function() cond,
      {int maxMs = 8000}) async {
    var waited = 0;
    while (!cond() && waited < maxMs) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 25)));
      await t.pump(const Duration(milliseconds: 100));
      waited += 25;
    }
    // A few extra frames so route animations finish.
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> settle(WidgetTester t) => pumpUntil(t, () => false, maxMs: 150);

  Widget app(Widget home) => ProviderScope(
        child: MaterialApp(home: home),
      );

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('flow_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  // Hive.close() can wait forever for writes that were started inside a widget
  // test's fake-async zone, so the box is left open; the process exit and the
  // temp directory clean-up below are enough.
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('phone layout: chips in the header, summary card, entry cards',
      (t) async {
    PlatformHelper.debugIsDesktopOverride = false;
    addTearDown(() => PlatformHelper.debugIsDesktopOverride = null);
    t.view.physicalSize = const Size(360, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const CashbookRootScreen()));
    await settle(t);
    expect(find.text('No transactions'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget); // chip in the header
    expect(find.text('Total Income'), findsOneWidget); // summary card

    final container =
        ProviderScope.containerOf(t.element(find.byType(CashbookRootScreen)));
    await t
        .runAsync(() => container.read(cashEntriesProvider.notifier).addEntry(
              bookId: DatabaseService.getAllCashBooks().first.id,
              date: DateTime.now(),
              amount: 123456789.5,
              isCashIn: true,
              notes:
                  'A very long note that has to wrap onto a second line to check the card',
            ));
    await settle(t);
    expect(find.textContaining('very long note'), findsOneWidget);
    expect(t.takeException(), isNull); // no overflow
  });
}
