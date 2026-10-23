import 'package:hive/hive.dart';

import '../../domain/entities/food_category.dart';
import '../../domain/entities/frozen_item.dart';

part 'frozen_item_model.g.dart';

@HiveType(typeId: 0)
class FrozenItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final FoodCategory category;

  @HiveField(3)
  final DateTime frozenDate;

  @HiveField(4)
  final DateTime expirationDate;

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final String unit;

  @HiveField(7)
  final String? locationNotes;

  @HiveField(8)
  final bool isConsumed;

  @HiveField(9)
  final bool reminderEnabled;

  FrozenItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.frozenDate,
    required this.expirationDate,
    required this.quantity,
    required this.unit,
    this.locationNotes,
    required this.isConsumed,
    this.reminderEnabled = true,
  });

  factory FrozenItemModel.fromDomain(FrozenItem item) {
    return FrozenItemModel(
      id: item.id,
      name: item.name,
      category: item.category,
      frozenDate: item.frozenDate,
      expirationDate: item.expirationDate,
      quantity: item.quantity,
      unit: item.unit,
      locationNotes: item.locationNotes,
      isConsumed: item.isConsumed,
      reminderEnabled: item.reminderEnabled,
    );
  }

  FrozenItem toDomain() {
    return FrozenItem(
      id: id,
      name: name,
      category: category,
      frozenDate: frozenDate,
      expirationDate: expirationDate,
      quantity: quantity,
      unit: unit,
      locationNotes: locationNotes,
      isConsumed: isConsumed,
      reminderEnabled: reminderEnabled,
    );
  }
}




