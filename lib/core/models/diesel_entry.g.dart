// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diesel_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DieselEntryAdapter extends TypeAdapter<DieselEntry> {
  @override
  final int typeId = 5;

  @override
  DieselEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DieselEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      billNumber: fields[3] as String,
      litre: fields[4] as double,
      rate: fields[5] as double,
      total: fields[6] as double,
      paid: fields[7] as double,
      pending: fields[8] as double,
      balance: fields[9] as double,
      paidDate: fields[10] as DateTime?,
      bunkDetails: fields[11] as String,
      notes: fields[12] as String?,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DieselEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.billNumber)
      ..writeByte(4)
      ..write(obj.litre)
      ..writeByte(5)
      ..write(obj.rate)
      ..writeByte(6)
      ..write(obj.total)
      ..writeByte(7)
      ..write(obj.paid)
      ..writeByte(8)
      ..write(obj.pending)
      ..writeByte(9)
      ..write(obj.balance)
      ..writeByte(10)
      ..write(obj.paidDate)
      ..writeByte(11)
      ..write(obj.bunkDetails)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DieselEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
