// Executes the get user issues use case.

import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../entities/help_center_issue.dart';
import '../../../repositories/help_center_repository.dart';

/// Loads data for the get user issues use case operation.
class GetUserIssuesUseCase {
  final HelpCenterRepository repository;

  /// Loads data for the get user issues use case operation.
  GetUserIssuesUseCase(this.repository);

  /// Validates input and delegates the get user issues request to the repository.
  Future<Either<Failure, List<HelpCenterIssue>>> execute(String uid) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserIssues(uid);
  }
}
