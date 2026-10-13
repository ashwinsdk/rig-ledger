// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgentAdapter extends TypeAdapter<Agent> {
  @override
  final int typeId = 1;

  @override
  Agent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Agent(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      notes: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      vehicleId: fields[6] as String,
      depthCommissionRate: fields[7] == null ? 0.0 : fields[7] as double,
      pvcCommissionRate: fields[8] == null ? 0.0 : fields[8] as double,
      msPipeCommissionRate: fields[9] == null ? 0.0 : fields[9] as double,
      commissionRatesJson: fields[10] == null ? '' : fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Agent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.vehicleId)
      ..writeByte(7)
      ..write(obj.depthCommissionRate)
      ..writeByte(8)
      ..write(obj.pvcCommissionRate)
      ..writeByte(9)
      ..write(obj.msPipeCommissionRate)
      ..writeByte(10)
      ..write(obj.commissionRatesJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
