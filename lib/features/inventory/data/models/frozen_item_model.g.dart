// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frozen_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrozenItemModelAdapter extends TypeAdapter<FrozenItemModel> {
  @override
  final int typeId = 0;

  @override
  FrozenItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrozenItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as FoodCategory,
      frozenDate: fields[3] as DateTime,
      expirationDate: fields[4] as DateTime,
      quantity: fields[5] as double,
      unit: fields[6] as String,
      locationNotes: fields[7] as String?,
      isConsumed: fields[8] as bool,
      reminderEnabled: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FrozenItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.frozenDate)
      ..writeByte(4)
      ..write(obj.expirationDate)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.locationNotes)
      ..writeByte(8)
      ..write(obj.isConsumed)
      ..writeByte(9)
      ..write(obj.reminderEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrozenItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
