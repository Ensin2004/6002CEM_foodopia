import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_manage_item.dart';
import '../../domain/repositories/admin_manage_repository.dart';
import '../datasources/admin_manage_remote_datasource.dart';
import '../models/admin_manage_item_model.dart';

class AdminManageRepositoryImpl implements AdminManageRepository {
  final AdminManageRemoteDataSource remoteDataSource;

  AdminManageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AdminManageItem>>> getItems(
    String categoryId,
  ) async {
    try {
      final items = await remoteDataSource.getItems(categoryId);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveItem({
    required String categoryId,
    required AdminManageItem item,
  }) async {
    try {
      await remoteDataSource.saveItem(
        categoryId: categoryId,
        item: AdminManageItemModel.fromEntity(item),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    try {
      await remoteDataSource.deleteItem(categoryId: categoryId, id: id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderItems({
    required String categoryId,
    required List<AdminManageItem> items,
  }) async {
    try {
      await remoteDataSource.reorderItems(
        categoryId: categoryId,
        items: items.map(AdminManageItemModel.fromEntity).toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> seedDefaults({
    required String categoryId,
    required List<String> values,
  }) async {
    try {
      await remoteDataSource.seedDefaults(
        categoryId: categoryId,
        values: values,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
