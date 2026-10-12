// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashEntryAdapter extends TypeAdapter<CashEntry> {
  @override
  final int typeId = 3;

  @override
  CashEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashEntry(
      id: fields[0] as String,
      bookId: fields[1] as String,
      date: fields[2] as DateTime,
      amount: fields[3] as double,
      isCashIn: fields[4] as bool,
      notes: fields[5] as String,
      description: fields[6] as String?,
      attachmentPaths: (fields[7] as List?)?.cast<String>(),
      itemsJson: fields[8] as String?,
      isDeleted: fields[9] as bool,
      deletedAt: fields[10] as DateTime?,
      transferGroupId: fields[11] as String?,
      importedLegacyId: fields[12] as int?,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      bookNameSnapshot: fields[15] as String?,
      sourceType: fields[16] as String?,
      sourceId: fields[17] as String?,
      sourcePaymentId: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CashEntry obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.isCashIn)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.attachmentPaths)
      ..writeByte(8)
      ..write(obj.itemsJson)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.transferGroupId)
      ..writeByte(12)
      ..write(obj.importedLegacyId)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.bookNameSnapshot)
      ..writeByte(16)
      ..write(obj.sourceType)
      ..writeByte(17)
      ..write(obj.sourceId)
      ..writeByte(18)
      ..write(obj.sourcePaymentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
