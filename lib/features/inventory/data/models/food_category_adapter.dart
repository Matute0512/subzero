import 'package:hive/hive.dart';

import '../../domain/entities/food_category.dart';

/// Adaptador Hive personalizado para el enum [FoodCategory] (typeId: 1).
class FoodCategoryAdapter extends TypeAdapter<FoodCategory> {
  @override
  final int typeId = 1;

  @override
  FoodCategory read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < FoodCategory.values.length) {
      return FoodCategory.values[index];
    }
    return FoodCategory.other;
  }

  @override
  void write(BinaryWriter writer, FoodCategory obj) {
    writer.writeByte(obj.index);
  }
}

