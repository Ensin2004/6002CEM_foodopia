import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/user_setup_repository.dart';

/// Use case for checking if user setup is completed.
/// Encapsulates the business logic for retrieving setup completion status.
class GetUserSetupStatusUseCase {
  /// Repository instance for data operations.
  final UserSetupRepository repository;

  /// Creates a new get user setup status use case instance.
  GetUserSetupStatusUseCase(this.repository);

  /// Executes the use case with the given user ID.
  ///
  /// [uid] is the user's unique identifier.
  /// Returns either a failure or a boolean indicating completion status.
  Future<Either<Failure, bool>> execute(String uid) {
    // Delegate to repository to check completion status.
    return repository.isSetupCompleted(uid);
  }
}