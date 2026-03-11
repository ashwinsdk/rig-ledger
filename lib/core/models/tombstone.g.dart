// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tombstone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TombstoneAdapter extends TypeAdapter<Tombstone> {
  @override
  final int typeId = 10;

  @override
  Tombstone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tombstone(
      entityId: fields[0] as String,
      collection: fields[1] as String,
      deletedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Tombstone obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.entityId)
      ..writeByte(1)
      ..write(obj.collection)
      ..writeByte(2)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TombstoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
