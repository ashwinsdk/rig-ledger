import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rig_ledger/core/models/agent.dart';
import 'package:rig_ledger/core/models/ledger_entry.dart';

/// Writes records the way app versions before 2.0.0 did (no fields 32-37 on
/// LedgerEntry, no fields 7-9 on Agent) so we can prove new builds read them.
class _LegacyLedgerAdapter extends LedgerEntryAdapter {
  @override
  void write(BinaryWriter w, LedgerEntry o) {
    w
      ..writeByte(32)
      ..writeByte(0)
      ..write(o.id)
      ..writeByte(1)
      ..write(o.date)
      ..writeByte(2)
      ..write(o.billNumber)
      ..writeByte(3)
      ..write(o.agentId)
      ..writeByte(4)
      ..write(o.agentName)
      ..writeByte(5)
      ..write(o.address)
      ..writeByte(6)
      ..write(o.depth)
      ..writeByte(7)
      ..write(o.depthInFeet)
      ..writeByte(8)
      ..write(o.depthPerFeetRate)
      ..writeByte(9)
      ..write(o.pvc)
      ..writeByte(10)
      ..write(o.pvcRate)
      ..writeByte(11)
      ..write(o.msPipe)
      ..writeByte(12)
      ..write(o.msPipeRate)
      ..writeByte(13)
      ..write(o.extraCharges)
      ..writeByte(14)
      ..write(o.total)
      ..writeByte(15)
      ..write(o.isTotalManuallyEdited)
      ..writeByte(16)
      ..write(o.received)
      ..writeByte(17)
      ..write(o.balance)
      ..writeByte(18)
      ..write(o.less)
      ..writeByte(19)
      ..write(o.notes)
      ..writeByte(20)
      ..write(o.createdAt)
      ..writeByte(21)
      ..write(o.updatedAt)
      ..writeByte(22)
      ..write(o.pvcInFeet)
      ..writeByte(23)
      ..write(o.pvcPerFeetRate)
      ..writeByte(24)
      ..write(o.msPipeInFeet)
      ..writeByte(25)
      ..write(o.msPipePerFeetRate)
      ..writeByte(26)
      ..write(o.stepRate)
      ..writeByte(27)
      ..write(o.isStepRateManuallyEdited)
      ..writeByte(28)
      ..write(o.vehicleId)
      ..writeByte(29)
      ..write(o.receivedCash)
      ..writeByte(30)
      ..write(o.receivedPhonePe)
      ..writeByte(31)
      ..write(o.phonePeName);
  }
}

class _LegacyAgentAdapter extends AgentAdapter {
  @override
  void write(BinaryWriter w, Agent o) {
    w
      ..writeByte(7)
      ..writeByte(0)
      ..write(o.id)
      ..writeByte(1)
      ..write(o.name)
      ..writeByte(2)
      ..write(o.phone)
      ..writeByte(3)
      ..write(o.notes)
      ..writeByte(4)
      ..write(o.createdAt)
      ..writeByte(5)
      ..write(o.updatedAt)
      ..writeByte(6)
      ..write(o.vehicleId);
  }
}

void main() {
  test('records written before v2.0.0 load with safe defaults', () async {
    final dir = Directory.systemTemp.createTempSync('legacy_hive');
    Hive.init(dir.path);
    final now = DateTime(2026, 1, 1);

    Hive.registerAdapter(_LegacyLedgerAdapter());
    Hive.registerAdapter(_LegacyAgentAdapter());
    var ledger = await Hive.openBox<LedgerEntry>('l');
    var agents = await Hive.openBox<Agent>('a');
    await ledger.put(
      'e1',
      LedgerEntry(
        id: 'e1',
        date: now,
        billNumber: '7',
        agentId: 'a1',
        agentName: 'Agent',
        address: 'Town',
        depth: '7inch',
        depthInFeet: 300,
        depthPerFeetRate: 10,
        pvc: '7inch',
        msPipe: '6inch',
        extraCharges: 0,
        total: 3000,
        isTotalManuallyEdited: false,
        received: 500,
        balance: 2500,
        less: 0,
        createdAt: now,
        updatedAt: now,
        receivedCash: 500,
      ),
    );
    await agents.put(
        'a1', Agent(id: 'a1', name: 'Agent', createdAt: now, updatedAt: now));
    await ledger.close();
    await agents.close();

    // Reads always go through the real (current) adapters' read().
    ledger = await Hive.openBox<LedgerEntry>('l');
    agents = await Hive.openBox<Agent>('a');

    final e = ledger.get('e1')!;
    expect(e.billNumber, '7');
    expect(e.receivedCash, 500);
    expect(e.paymentsJson, isNull);
    expect(e.payments, isEmpty);
    expect(e.unloggedCash, 500);
    expect(e.commission, 0);
    expect(e.depthCommissionRate, 0);
    expect(e.isCommissionManuallyEdited, isFalse);
    final a = agents.get('a1')!;
    expect(a.name, 'Agent');
    expect(a.depthCommissionRate, 0);

    await Hive.close();
    dir.deleteSync(recursive: true);
  });
}
