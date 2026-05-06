import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

class ReorderAdminManageItemsUseCase {
  final AdminManageRepository repository;

  ReorderAdminManageItemsUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String categoryId,
    required List<AdminManageItem> items,
  }) {
    return repository.reorderItems(categoryId: categoryId, items: items);
  }
}
