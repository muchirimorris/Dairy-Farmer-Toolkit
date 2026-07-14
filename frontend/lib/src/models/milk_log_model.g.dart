// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milk_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MilkLogModelAdapter extends TypeAdapter<MilkLogModel> {
  @override
  final int typeId = 1;

  @override
  MilkLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilkLogModel(
      id: fields[0] as String,
      animalId: fields[1] as String,
      animalName: fields[2] as String,
      quantity: fields[3] as double,
      date: fields[4] as DateTime,
      farmerId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MilkLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.animalId)
      ..writeByte(2)
      ..write(obj.animalName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.farmerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilkLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
