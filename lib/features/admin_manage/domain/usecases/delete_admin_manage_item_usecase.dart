import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_manage_repository.dart';

class DeleteAdminManageItemUseCase {
  final AdminManageRepository repository;

  DeleteAdminManageItemUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String categoryId,
    required String id,
  }) async {
    return repository.deleteItem(categoryId: categoryId, id: id);
  }
}
