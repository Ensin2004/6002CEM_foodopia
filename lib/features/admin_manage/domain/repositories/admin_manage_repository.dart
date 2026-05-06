import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';

/// Repository contract for admin-managed option lists.
abstract class AdminManageRepository {
  Future<Either<Failure, List<AdminManageItem>>> getItems(String categoryId);

  Future<Either<Failure, void>> saveItem({
    required String categoryId,
    required AdminManageItem item,
  });

  Future<Either<Failure, void>> deleteItem({
    required String categoryId,
    required String id,
  });

  Future<Either<Failure, void>> reorderItems({
    required String categoryId,
    required List<AdminManageItem> items,
  });

  Future<Either<Failure, void>> seedDefaults({
    required String categoryId,
    required List<String> values,
  });
}
