import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/providers/portfolio_provider.dart';
import 'package:rig_ledger/features/portfolio/portfolio_view.dart';

/// Portfolio This rig / All rigs control (bug 7, v2.0.1).
void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('portfolio_scope_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('scope toggle changes the shared provider and the hint',
      (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: PortfolioView())),
    ));
    await t.pump(const Duration(milliseconds: 100));

    final container =
        ProviderScope.containerOf(t.element(find.byType(PortfolioView)));
    expect(container.read(portfolioAllRigsProvider), isFalse);
    expect(find.textContaining('Main Rig only'), findsOneWidget);

    await t.tap(find.text('All rigs'));
    await t.pump(const Duration(milliseconds: 100));
    expect(container.read(portfolioAllRigsProvider), isTrue);
    expect(find.textContaining('Showing all 1 rig together'), findsOneWidget);

    await t.tap(find.text('This rig'));
    await t.pump(const Duration(milliseconds: 100));
    expect(container.read(portfolioAllRigsProvider), isFalse);
    expect(t.takeException(), isNull);
  });
}
