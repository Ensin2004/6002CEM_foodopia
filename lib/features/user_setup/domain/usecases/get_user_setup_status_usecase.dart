import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/user_setup_repository.dart';

class GetUserSetupStatusUseCase {
  final UserSetupRepository repository;

  GetUserSetupStatusUseCase(this.repository);

  Future<Either<Failure, bool>> execute(String uid) {
    return repository.isSetupCompleted(uid);
  }
}
