// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerEntryAdapter extends TypeAdapter<LedgerEntry> {
  @override
  final int typeId = 0;

  @override
  LedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      billNumber: fields[2] as String,
      agentId: fields[3] as String,
      agentName: fields[4] as String,
      address: fields[5] as String,
      depth: fields[6] as String,
      depthInFeet: fields[7] as double,
      depthPerFeetRate: fields[8] as double,
      pvc: fields[9] as String,
      pvcRate: fields[10] as double,
      msPipe: fields[11] as String,
      msPipeRate: fields[12] as double,
      extraCharges: fields[13] as double,
      total: fields[14] as double,
      isTotalManuallyEdited: fields[15] as bool,
      received: fields[16] as double,
      balance: fields[17] as double,
      less: fields[18] as double,
      notes: fields[19] as String?,
      createdAt: fields[20] as DateTime,
      updatedAt: fields[21] as DateTime,
      pvcInFeet: fields[22] as double? ?? 0,
      pvcPerFeetRate: fields[23] as double? ?? 0,
      msPipeInFeet: fields[24] as double? ?? 0,
      msPipePerFeetRate: fields[25] as double? ?? 0,
      stepRate: fields[26] as double? ?? 0,
      isStepRateManuallyEdited: fields[27] as bool? ?? false,
      vehicleId: (fields[28] as String?) ?? 'default',
      receivedCash: fields[29] as double? ?? 0,
      receivedPhonePe: fields[30] as double? ?? 0,
      phonePeName: fields[31] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntry obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.billNumber)
      ..writeByte(3)
      ..write(obj.agentId)
      ..writeByte(4)
      ..write(obj.agentName)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.depth)
      ..writeByte(7)
      ..write(obj.depthInFeet)
      ..writeByte(8)
      ..write(obj.depthPerFeetRate)
      ..writeByte(9)
      ..write(obj.pvc)
      ..writeByte(10)
      ..write(obj.pvcRate)
      ..writeByte(11)
      ..write(obj.msPipe)
      ..writeByte(12)
      ..write(obj.msPipeRate)
      ..writeByte(13)
      ..write(obj.extraCharges)
      ..writeByte(14)
      ..write(obj.total)
      ..writeByte(15)
      ..write(obj.isTotalManuallyEdited)
      ..writeByte(16)
      ..write(obj.received)
      ..writeByte(17)
      ..write(obj.balance)
      ..writeByte(18)
      ..write(obj.less)
      ..writeByte(19)
      ..write(obj.notes)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt)
      ..writeByte(22)
      ..write(obj.pvcInFeet)
      ..writeByte(23)
      ..write(obj.pvcPerFeetRate)
      ..writeByte(24)
      ..write(obj.msPipeInFeet)
      ..writeByte(25)
      ..write(obj.msPipePerFeetRate)
      ..writeByte(26)
      ..write(obj.stepRate)
      ..writeByte(27)
      ..write(obj.isStepRateManuallyEdited)
      ..writeByte(28)
      ..write(obj.vehicleId)
      ..writeByte(29)
      ..write(obj.receivedCash)
      ..writeByte(30)
      ..write(obj.receivedPhonePe)
      ..writeByte(31)
      ..write(obj.phonePeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
