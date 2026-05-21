import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../repositories/user_setup_repository.dart';

class GetUserSetupOptionsUseCase {
  final UserSetupRepository repository;

  GetUserSetupOptionsUseCase(this.repository);

  Future<Either<Failure, List<UserSetupOption>>> execute(String categoryId) {
    return repository.getAdminOptions(categoryId);
  }
}
