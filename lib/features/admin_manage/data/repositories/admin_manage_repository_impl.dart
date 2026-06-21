import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_manage_item.dart';
import '../../domain/repositories/admin_manage_repository.dart';
import '../datasources/admin_manage_remote_datasource.dart';
import '../models/admin_manage_item_model.dart';

/// Implementation of the admin manage repository.
/// Coordinates data from the remote data source.
class AdminManageRepositoryImpl implements AdminManageRepository {
  /// Remote data source for admin manage operations.
  final AdminManageRemoteDataSource remoteDataSource;

  /// Creates a new admin manage repository implementation instance.
  AdminManageRepositoryImpl({required this.remoteDataSource});

  /// Retrieves items for a category.
  @override
  Future<Either<Failure, List<AdminManageItem>>> getItems(
      String categoryId,
      ) async {
    try {
      // Delegate to remote data source.
      final items = await remoteDataSource.getItems(categoryId);
      return Right(items);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Saves an item (creates or updates).
  @override
  Future<Either<Failure, void>> saveItem({
    required String categoryId,
    required AdminManageItem item,
  }) async {
    try {
      // Convert entity to model and delegate to remote data source.
      await remoteDataSource.saveItem(
        categoryId: categoryId,
        item: AdminManageItemModel.fromEntity(item),
      );
      return const Right(null);
    } on StateError catch (e) {
      // Handle duplicate name errors.
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Deletes an item.
  @override
  Future<Either<Failure, void>> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.deleteItem(categoryId: categoryId, id: id);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Reorders items.
  @override
  Future<Either<Failure, void>> reorderItems({
    required String categoryId,
    required List<AdminManageItem> items,
  }) async {
    try {
      // Convert entities to models and delegate to remote data source.
      await remoteDataSource.reorderItems(
        categoryId: categoryId,
        items: items.map(AdminManageItemModel.fromEntity).toList(),
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}