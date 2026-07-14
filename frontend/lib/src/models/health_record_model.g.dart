// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthRecordModelAdapter extends TypeAdapter<HealthRecordModel> {
  @override
  final int typeId = 5;

  @override
  HealthRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthRecordModel(
      id: fields[0] as String,
      animalId: fields[1] as String,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      description: fields[4] as String,
      medicineUsed: fields[5] as String?,
      cost: fields[6] as double?,
      nextFollowUp: fields[7] as DateTime?,
      isSynced: fields[8] as bool,
      farmerId: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecordModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.animalId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.medicineUsed)
      ..writeByte(6)
      ..write(obj.cost)
      ..writeByte(7)
      ..write(obj.nextFollowUp)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.farmerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
