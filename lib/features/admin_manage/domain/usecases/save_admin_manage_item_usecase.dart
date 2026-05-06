import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

class SaveAdminManageItemUseCase {
  final AdminManageRepository repository;

  SaveAdminManageItemUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String categoryId,
    required AdminManageItem item,
  }) async {
    return repository.saveItem(categoryId: categoryId, item: item);
  }
}
