import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_manage_repository.dart';

class SeedAdminManageDefaultsUseCase {
  final AdminManageRepository repository;

  SeedAdminManageDefaultsUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String categoryId,
    required List<String> values,
  }) async {
    return repository.seedDefaults(categoryId: categoryId, values: values);
  }
}
