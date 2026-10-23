import 'package:hive/hive.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/frozen_item_model.dart';

/// Contrato abstracto para el origen de datos local de inventario (Hive).
abstract class IInventoryLocalDataSource {
  Future<List<FrozenItemModel>> getItems();
  Future<void> saveItem(FrozenItemModel item);
  Future<void> deleteItem(String id);
  Future<void> updateItem(FrozenItemModel item);
}

/// Implementación concreta de [IInventoryLocalDataSource] persistida en Hive.
class InventoryLocalDataSourceImpl implements IInventoryLocalDataSource {
  static const String boxName = 'frozen_items_box';
  static const String _tag = 'InventoryLocalDS';

  final Box<FrozenItemModel> _box;

  InventoryLocalDataSourceImpl(this._box);

  @override
  Future<List<FrozenItemModel>> getItems() async {
    try {
      return _box.values.toList();
    } catch (e, stack) {
      AppLogger.error('Error al recuperar items desde Hive Box', tag: _tag, error: e, stackTrace: stack);
      throw CacheException(message: 'Error al recuperar items de inventario: $e');
    }
  }

  @override
  Future<void> saveItem(FrozenItemModel item) async {
    try {
      await _box.put(item.id, item);
      AppLogger.debug('Item guardado exitosamente en Hive: ${item.id}', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Error al persistir item en Hive Box', tag: _tag, error: e, stackTrace: stack);
      throw CacheException(message: 'Error al guardar item: $e');
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _box.delete(id);
      AppLogger.debug('Item eliminado de Hive Box: $id', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Error al eliminar item en Hive Box', tag: _tag, error: e, stackTrace: stack);
      throw CacheException(message: 'Error al eliminar item: $e');
    }
  }

  @override
  Future<void> updateItem(FrozenItemModel item) async {
    try {
      await _box.put(item.id, item);
      AppLogger.debug('Item actualizado en Hive Box: ${item.id}', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Error al actualizar item en Hive Box', tag: _tag, error: e, stackTrace: stack);
      throw CacheException(message: 'Error al actualizar item: $e');
    }
  }

}



