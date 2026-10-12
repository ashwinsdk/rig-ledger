import 'package:flutter_test/flutter_test.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';
import 'package:rig_ledger/core/models/ledger_payment.dart';

LedgerEntry entry({double cash = 0, double phonePe = 0, String? json}) {
  final now = DateTime(2026, 1, 1);
  return LedgerEntry(
    id: 'e1',
    date: now,
    billNumber: '1',
    agentId: 'a',
    agentName: 'A',
    address: 'X',
    depth: '7inch',
    depthInFeet: 100,
    depthPerFeetRate: 10,
    pvc: '7inch',
    msPipe: '6inch',
    extraCharges: 0,
    total: 1000,
    isTotalManuallyEdited: false,
    received: cash + phonePe,
    balance: 1000 - cash - phonePe,
    less: 0,
    createdAt: now,
    updatedAt: now,
    receivedCash: cash,
    receivedPhonePe: phonePe,
    paymentsJson: json,
  );
}

void main() {
  test('payments round trip and tolerate bad json', () {
    final list = [
      LedgerPayment(
          id: 'p1',
          date: DateTime(2026, 2, 3, 10),
          amount: 250.5,
          receiverBookId: 'b1',
          notes: 'first'),
      LedgerPayment(
          id: 'p2',
          date: DateTime(2026, 2, 4),
          amount: 100,
          mode: LedgerPayment.modePhonePe,
          payerName: 'Ravi'),
    ];
    final decoded = LedgerPayment.decodeList(LedgerPayment.encodeList(list));
    expect(decoded.length, 2);
    expect(decoded.first.receiverBookId, 'b1');
    expect(decoded.last.isCash, isFalse);
    expect(LedgerPayment.totalCash(decoded), 250.5);
    expect(LedgerPayment.totalPhonePe(decoded), 100);
    expect(LedgerPayment.decodeList('nope'), isEmpty);
    expect(LedgerPayment.decodeList(null), isEmpty);
    expect(LedgerPayment.encodeList([]), isNull);
  });

  test('unlogged amounts are the received minus the logged payments', () {
    final json = LedgerPayment.encodeList([
      LedgerPayment(id: 'p1', date: DateTime(2026), amount: 300),
      LedgerPayment(
          id: 'p2',
          date: DateTime(2026),
          amount: 50,
          mode: LedgerPayment.modePhonePe),
    ]);
    final e = entry(cash: 500, phonePe: 80, json: json);
    expect(e.unloggedCash, 200);
    expect(e.unloggedPhonePe, 30);
    // A bill without a log keeps everything unlogged (older bills).
    final old = entry(cash: 120);
    expect(old.payments, isEmpty);
    expect(old.unloggedCash, 120);
  });

  test('commission = ft x rate per component and is not part of total', () {
    final c = LedgerEntry.calculateCommission(
      depthInFeet: 1000,
      depthCommissionRate: 2,
      pvcInFeet: 150,
      pvcCommissionRate: 40,
      msPipeInFeet: 100,
      msPipeCommissionRate: 60,
    );
    expect(c, 2000 + 6000 + 6000);
    final total = LedgerEntry.calculateTotal(
      depthInFeet: 1000,
      depthPerFeetRate: 10,
      stepRate: 0,
      pvcInFeet: 0,
      pvcPerFeetRate: 0,
      msPipeInFeet: 0,
      msPipePerFeetRate: 0,
      extraCharges: 0,
    );
    expect(total, 10000);
  });

  test('map round trip keeps new fields; old maps default to zero', () {
    final e = entry(cash: 10, json: '[]')
      ..commission = 99.5
      ..isCommissionManuallyEdited = true
      ..depthCommissionRate = 2;
    final back = LedgerEntry.fromMap(e.toMap());
    expect(back.commission, 99.5);
    expect(back.isCommissionManuallyEdited, isTrue);
    expect(back.depthCommissionRate, 2);

    final oldMap = e.toMap()
      ..remove('paymentsJson')
      ..remove('commission')
      ..remove('depthCommissionRate')
      ..remove('isCommissionManuallyEdited');
    final old = LedgerEntry.fromMap(oldMap);
    expect(old.commission, 0);
    expect(old.paymentsJson, isNull);
    expect(old.isCommissionManuallyEdited, isFalse);

    final agent = Agent(
      id: 'a',
      name: 'A',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      depthCommissionRate: 3,
    );
    expect(Agent.fromMap(agent.toMap()).depthCommissionRate, 3);
    final oldAgent = Agent.fromMap(agent.toMap()
      ..remove('depthCommissionRate')
      ..remove('pvcCommissionRate'));
    expect(oldAgent.depthCommissionRate, 0);
  });

  test('CSV row matches headers and includes commission', () {
    final e = entry(cash: 10)..commission = 250.5;
    final row = e.toCsvRow();
    expect(row.length, LedgerEntry.csvHeaders.length);
    expect(LedgerEntry.csvHeaders.last, 'Commission');
    expect(row.last, '250.5');
  });
}
