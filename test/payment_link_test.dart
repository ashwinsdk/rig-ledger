import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/database/database_service.dart';
import 'package:rig_ledger/core/models/cash_entry.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/vehicle.dart';
import 'package:rig_ledger/core/models/ledger_payment.dart';
import 'package:rig_ledger/core/providers/cashbook_provider.dart';
import 'package:rig_ledger/core/providers/ledger_provider.dart';
import 'package:rig_ledger/core/providers/vehicle_provider.dart';
import 'package:rig_ledger/core/services/payment_link_service.dart';

LedgerEntry bill({
  String id = 'bill1',
  double total = 10000,
  List<LedgerPayment> payments = const [],
  double baseCash = 0,
}) {
  final now = DateTime(2026, 5, 1);
  final cash = baseCash + LedgerPayment.totalCash(payments);
  final pe = LedgerPayment.totalPhonePe(payments);
  return LedgerEntry(
    id: id,
    date: now,
    billNumber: '101',
    agentId: 'a1',
    agentName: 'Agent',
    address: 'Salem',
    depth: '7inch',
    depthInFeet: 100,
    depthPerFeetRate: 100,
    pvc: '7inch',
    msPipe: '6inch',
    extraCharges: 0,
    total: total,
    isTotalManuallyEdited: false,
    received: cash + pe,
    balance: total - cash - pe,
    less: 0,
    createdAt: now,
    updatedAt: now,
    receivedCash: cash,
    receivedPhonePe: pe,
    paymentsJson: LedgerPayment.encodeList(payments),
    vehicleId: 'default_vehicle',
  );
}

void main() {
  late Directory dir;
  late ProviderContainer c;
  late String receiverId;
  late String otherId;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('paylink_test');
    Hive.init(dir.path);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.clearAllData();
    c = ProviderContainer();
    c.read(cashBooksProvider.notifier).refresh();
    final books = c.read(cashBooksProvider.notifier);
    receiverId = (await books.addBook(name: 'Ravi', kind: 1)).$1!.id;
    otherId = (await books.addBook(name: 'Kumar', kind: 1)).$1!.id;
  });

  tearDown(() => c.dispose());

  tearDownAll(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  List<CashEntry> linked() => DatabaseService.cashEntryBox.values
      .where((e) => e.sourceType == 'ledger_payment')
      .toList();

  LedgerPayment pay(String id, double amount, {String? receiver}) =>
      LedgerPayment(
          id: id,
          date: DateTime(2026, 5, 2, 10),
          amount: amount,
          receiverBookId: receiver);

  test('a payment with a receiver creates an income in that book', () async {
    await c
        .read(ledgerEntriesProvider.notifier)
        .addEntry(bill(payments: [pay('p1', 2500, receiver: receiverId)]));
    final l = linked();
    expect(l.length, 1);
    expect(l.first.bookId, receiverId);
    expect(l.first.amount, 2500);
    expect(l.first.isCashIn, isTrue);
    expect(l.first.sourceId, 'bill1');
    expect(l.first.sourcePaymentId, 'p1');
    expect(l.first.notes, 'Bill 101 - Salem');
    // the income carries the rig of the bill (v2.0.4)
    expect(l.first.vehicleId, 'default_vehicle');
    // Payments without a receiver create nothing.
    await c
        .read(ledgerEntriesProvider.notifier)
        .addEntry(bill(id: 'bill2', payments: [pay('p9', 100)]));
    expect(linked().length, 1);
  });

  test('editing and removing the payment updates the book', () async {
    final n = c.read(ledgerEntriesProvider.notifier);
    await n.addEntry(bill(payments: [pay('p1', 2500, receiver: receiverId)]));
    await n.updateEntry(bill(payments: [pay('p1', 3000, receiver: otherId)]));
    var l = linked();
    expect(l.length, 1);
    expect(l.first.amount, 3000);
    expect(l.first.bookId, otherId);
    await n.updateEntry(bill(payments: []));
    l = linked();
    expect(l.single.isDeleted, isTrue);
  });

  test('editing the income in the book updates the bill', () async {
    await c.read(ledgerEntriesProvider.notifier).addEntry(
        bill(baseCash: 500, payments: [pay('p1', 2500, receiver: receiverId)]));
    final cashEntry = c
        .read(cashEntriesProvider)
        .firstWhere((e) => e.sourceType == 'ledger_payment');
    cashEntry.amount = 4000;
    cashEntry.bookId = otherId;
    final (ok, _) =
        await c.read(cashEntriesProvider.notifier).updateEntry(cashEntry);
    expect(ok, isTrue);
    final b = DatabaseService.ledgerBox.get('bill1')!;
    expect(b.payments.single.amount, 4000);
    expect(b.payments.single.receiverBookId, otherId);
    // Unlogged base (500) is preserved, totals follow the log.
    expect(b.receivedCash, 4500);
    expect(b.received, 4500);
    expect(b.balance, 5500);
  });

  test('trashing keeps the payment but clears the receiver; restore relinks',
      () async {
    await c
        .read(ledgerEntriesProvider.notifier)
        .addEntry(bill(payments: [pay('p1', 2500, receiver: receiverId)]));
    final id = linked().first.id;
    await c.read(cashEntriesProvider.notifier).moveToTrash(id);
    var b = DatabaseService.ledgerBox.get('bill1')!;
    expect(b.payments.single.receiverBookId, isNull);
    expect(b.receivedCash, 2500); // money was still received
    await c.read(cashEntriesProvider.notifier).restore(id, toBookId: otherId);
    b = DatabaseService.ledgerBox.get('bill1')!;
    expect(b.payments.single.receiverBookId, otherId);
    expect(DatabaseService.getCashEntry(id)!.bookId, otherId);
  });

  test('deleting the bill trashes its incomes', () async {
    final n = c.read(ledgerEntriesProvider.notifier);
    await n.addEntry(bill(payments: [pay('p1', 100, receiver: receiverId)]));
    await n.deleteEntry('bill1');
    expect(linked().single.isDeleted, isTrue);
  });

  test('deleting a receiver book clears the receiver on payments', () async {
    await c
        .read(ledgerEntriesProvider.notifier)
        .addEntry(bill(payments: [pay('p1', 100, receiver: receiverId)]));
    await c.read(cashBooksProvider.notifier).deleteBook(receiverId);
    final b = DatabaseService.ledgerBox.get('bill1')!;
    expect(b.payments.single.receiverBookId, isNull);
    expect(b.receivedCash, 100);
    expect(linked().single.isDeleted, isTrue);
  });

  test('reconcile creates missing incomes and trashes orphans', () async {
    // Bill saved without going through the notifier (for example restored).
    await DatabaseService.saveLedgerEntry(
        bill(payments: [pay('p1', 700, receiver: receiverId)]));
    expect(linked(), isEmpty);
    await PaymentLinkService.reconcileAll();
    expect(linked().length, 1);
    // Payment removed on another device: the income is trashed.
    await DatabaseService.saveLedgerEntry(bill(payments: []));
    await PaymentLinkService.reconcileAll();
    expect(linked().single.isDeleted, isTrue);
  });

  test('newer income edit wins during reconcile', () async {
    await c
        .read(ledgerEntriesProvider.notifier)
        .addEntry(bill(payments: [pay('p1', 1000, receiver: receiverId)]));
    final e = linked().first;
    e.amount = 1200;
    e.updatedAt = DateTime.now().add(const Duration(minutes: 5));
    await DatabaseService.saveCashEntry(e);
    await PaymentLinkService.reconcileAll();
    final b = DatabaseService.ledgerBox.get('bill1')!;
    expect(b.payments.single.amount, 1200);
    expect(b.receivedCash, 1200);
  });

  test('backup and restore keep payments, commission and links', () async {
    final b = bill(payments: [pay('p1', 2500, receiver: receiverId)])
      ..commission = 321.5
      ..depthCommissionRate = 3
      ..isCommissionManuallyEdited = true;
    await c.read(ledgerEntriesProvider.notifier).addEntry(b);
    final backup = await DatabaseService.createBackup();
    await DatabaseService.restoreBackup(backup);
    final restored = DatabaseService.ledgerBox.get('bill1')!;
    expect(restored.payments.single.id, 'p1');
    expect(restored.payments.single.receiverBookId, receiverId);
    expect(restored.commission, 321.5);
    expect(restored.depthCommissionRate, 3);
    expect(restored.isCommissionManuallyEdited, isTrue);
    expect(linked().length, 1);
    expect(linked().single.sourcePaymentId, 'p1');
    // Reconcile after a restore finds everything already consistent.
    expect(await PaymentLinkService.reconcileAll(), 0);
    expect(linked().length, 1);
  });

  test('deleting a vehicle removes its bills and agents and trashes incomes',
      () async {
    final now = DateTime(2026, 5, 1);
    await DatabaseService.saveVehicle(Vehicle(
        id: 'v2',
        name: 'Rig 2',
        vehicleTypeIndex: 0,
        createdAt: now,
        updatedAt: now));
    await DatabaseService.saveAgent(Agent(
        id: 'a-v2',
        name: 'Agent v2',
        createdAt: now,
        updatedAt: now,
        vehicleId: 'v2'));
    final b =
        bill(id: 'v2bill', payments: [pay('p1', 900, receiver: receiverId)])
          ..vehicleId = 'v2';
    await c.read(ledgerEntriesProvider.notifier).addEntry(b);
    expect(linked().length, 1);

    await c.read(vehiclesProvider.notifier).deleteVehicle('v2');
    expect(DatabaseService.ledgerBox.get('v2bill'), isNull);
    expect(DatabaseService.getAgent('a-v2'), isNull);
    expect(linked().single.isDeleted, isTrue);
    expect(DatabaseService.vehicleBox.containsKey('v2'), isFalse);
  });

  test('restoring an income whose payment is gone makes it a normal income',
      () async {
    final n = c.read(ledgerEntriesProvider.notifier);
    await n.addEntry(bill(payments: [pay('p1', 100, receiver: receiverId)]));
    final id = linked().first.id;
    await c.read(cashEntriesProvider.notifier).moveToTrash(id);
    // The payment is removed from the bill while the income is in the trash.
    await n.updateEntry(bill(payments: []));
    await c.read(cashEntriesProvider.notifier).restore(id);
    final e = DatabaseService.getCashEntry(id)!;
    expect(e.isDeleted, isFalse);
    expect(e.sourceType, isNull);
    // A later reconcile leaves it alone.
    await PaymentLinkService.reconcileAll();
    expect(DatabaseService.getCashEntry(id)!.isDeleted, isFalse);
  });
}
