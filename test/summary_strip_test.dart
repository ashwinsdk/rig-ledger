import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/features/home/widgets/summary_row.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('summary_strip_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('pinned totals are one slim strip that scrolls sideways',
      (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: SummaryRow())),
    ));
    await t.pump(const Duration(milliseconds: 300));

    final size = t.getSize(find.byType(SummaryRow));
    expect(size.height, lessThan(100)); // was about 190 with two cards
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Commission'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // feet tiles sit at the end of the same strip
    await t.drag(find.byType(SingleChildScrollView), const Offset(-600, 0));
    await t.pump();
    expect(find.text('MS Pipe'), findsOneWidget);
  });
}
