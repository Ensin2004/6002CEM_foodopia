import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

class GetAdminManageItemsUseCase {
  final AdminManageRepository repository;

  GetAdminManageItemsUseCase(this.repository);

  Future<Either<Failure, List<AdminManageItem>>> execute(
    String categoryId,
  ) async {
    return repository.getItems(categoryId);
  }
}
