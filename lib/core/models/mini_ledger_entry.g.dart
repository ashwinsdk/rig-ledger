// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mini_ledger_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MiniLedgerEntryAdapter extends TypeAdapter<MiniLedgerEntry> {
  @override
  final int typeId = 9;

  @override
  MiniLedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MiniLedgerEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      billNumber: fields[3] as String,
      agentId: fields[4] as String,
      agentName: fields[5] as String,
      address: fields[6] as String,
      depth: fields[7] as double,
      depthPerFeetRate: fields[8] as double,
      total: fields[9] as double,
      receivedCash: fields[10] as double,
      receivedPhonePe: fields[11] as double,
      phonePeName: fields[12] as String?,
      balance: fields[13] as double,
      less: fields[14] as double,
      notes: fields[15] as String?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MiniLedgerEntry obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.billNumber)
      ..writeByte(4)
      ..write(obj.agentId)
      ..writeByte(5)
      ..write(obj.agentName)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.depth)
      ..writeByte(8)
      ..write(obj.depthPerFeetRate)
      ..writeByte(9)
      ..write(obj.total)
      ..writeByte(10)
      ..write(obj.receivedCash)
      ..writeByte(11)
      ..write(obj.receivedPhonePe)
      ..writeByte(12)
      ..write(obj.phonePeName)
      ..writeByte(13)
      ..write(obj.balance)
      ..writeByte(14)
      ..write(obj.less)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniLedgerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
