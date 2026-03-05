// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialRecordModelAdapter extends TypeAdapter<FinancialRecordModel> {
  @override
  final int typeId = 3;

  @override
  FinancialRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialRecordModel(
      id: fields[0] as String,
      type: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      date: fields[4] as DateTime,
      animalId: fields[5] as String?,
      description: fields[6] as String?,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialRecordModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.animalId)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
