// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pvc_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PvcEntryAdapter extends TypeAdapter<PvcEntry> {
  @override
  final int typeId = 6;

  @override
  PvcEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PvcEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      billNumber: fields[3] as String,
      type: fields[4] as String,
      count: fields[5] as int,
      rate: fields[6] as double,
      total: fields[7] as double,
      paid: fields[8] as double,
      pending: fields[9] as double,
      balance: fields[10] as double,
      paidDate: fields[11] as DateTime?,
      storagePlace: fields[12] as String,
      notes: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PvcEntry obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.billNumber)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.count)
      ..writeByte(6)
      ..write(obj.rate)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.paid)
      ..writeByte(9)
      ..write(obj.pending)
      ..writeByte(10)
      ..write(obj.balance)
      ..writeByte(11)
      ..write(obj.paidDate)
      ..writeByte(12)
      ..write(obj.storagePlace)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PvcEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
