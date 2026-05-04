// Executes the update issue status use case.

import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/help_center_repository.dart';

/// Runs the update issue status use case operation.
class UpdateIssueStatusUseCase {
  final HelpCenterRepository repository;

  /// Runs the update issue status use case operation.
  UpdateIssueStatusUseCase(this.repository);

  /// Validates input and delegates the update issue status request to the repository.
  Future<Either<Failure, void>> execute(String issueId) async {
    if (issueId.isEmpty) {
      return Left(ValidationFailure(message: 'Issue ID cannot be empty'));
    }
    return await repository.markIssueAsReplied(issueId);
  }
}
