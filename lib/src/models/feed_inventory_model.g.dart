// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_inventory_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedInventoryModelAdapter extends TypeAdapter<FeedInventoryModel> {
  @override
  final int typeId = 4;

  @override
  FeedInventoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedInventoryModel(
      id: fields[0] as String,
      type: fields[1] as String,
      name: fields[2] as String,
      quantity: fields[3] as double,
      unit: fields[4] as String,
      cost: fields[5] as double,
      purchaseDate: fields[6] as DateTime,
      threshold: fields[7] as double,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FeedInventoryModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.cost)
      ..writeByte(6)
      ..write(obj.purchaseDate)
      ..writeByte(7)
      ..write(obj.threshold)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedInventoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
