// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_expense_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OtherExpenseEntryAdapter extends TypeAdapter<OtherExpenseEntry> {
  @override
  final int typeId = 12;

  @override
  OtherExpenseEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OtherExpenseEntry(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      billNumber: fields[3] as String,
      description: fields[4] as String,
      total: fields[5] as double,
      paid: fields[6] as double,
      pending: fields[7] as double,
      balance: fields[8] as double,
      paidDate: fields[9] as DateTime?,
      notes: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OtherExpenseEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.billNumber)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.paid)
      ..writeByte(7)
      ..write(obj.pending)
      ..writeByte(8)
      ..write(obj.balance)
      ..writeByte(9)
      ..write(obj.paidDate)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtherExpenseEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
