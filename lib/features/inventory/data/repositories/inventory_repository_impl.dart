import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/frozen_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_datasource.dart';
import '../models/frozen_item_model.dart';

/// Implementación concreta de [IInventoryRepository] utilizando el DataSource local.
class InventoryRepositoryImpl implements IInventoryRepository {
  final IInventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<FrozenItem>>> getItems() async {
    try {
      final models = await localDataSource.getItems();
      final items = models.map((m) => m.toDomain()).toList();
      return Right(items);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error inesperado al obtener items: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveItem(FrozenItem item) async {
    try {
      final model = FrozenItemModel.fromDomain(item);
      await localDataSource.saveItem(model);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error inesperado al guardar item: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(String id) async {
    try {
      await localDataSource.deleteItem(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error inesperado al eliminar item: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateItem(FrozenItem item) async {
    try {
      final model = FrozenItemModel.fromDomain(item);
      await localDataSource.updateItem(model);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error inesperado al actualizar item: $e'));
    }
  }
}
