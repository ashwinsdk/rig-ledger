// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashBookAdapter extends TypeAdapter<CashBook> {
  @override
  final int typeId = 2;

  @override
  CashBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashBook(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      sortOrder: fields[4] as int,
      kind: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CashBook obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.sortOrder)
      ..writeByte(5)
      ..write(obj.kind);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashBookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
