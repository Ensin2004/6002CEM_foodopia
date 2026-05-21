// Executes the get user email use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/help_center_repository.dart';

/// Loads data for the get user email use case operation.
class GetUserEmailUseCase {
  final HelpCenterRepository repository;

  /// Loads data for the get user email use case operation.
  GetUserEmailUseCase(this.repository);

  /// Validates input and delegates the get user email request to the repository.
  Future<Either<Failure, String>> execute(String uid) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserEmail(uid);
  }
}
