// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommissionEntryAdapter extends TypeAdapter<CommissionEntry> {
  @override
  final int typeId = 10;

  @override
  CommissionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommissionEntry(
      id: fields[0] as String,
      agentId: fields[1] as String,
      agentName: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      amount: fields[5] as double,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      vehicleId: (fields[8] as String?) ?? 'default',
      isPaid: (fields[9] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CommissionEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.agentId)
      ..writeByte(2)
      ..write(obj.agentName)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.vehicleId)
      ..writeByte(9)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
