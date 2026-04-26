import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/help_center_repository.dart';

class UpdateIssueStatusUseCase {
  final HelpCenterRepository repository;

  UpdateIssueStatusUseCase(this.repository);

  Future<Either<Failure, void>> execute(String issueId) async {
    if (issueId.isEmpty) {
      return Left(ValidationFailure(message: 'Issue ID cannot be empty'));
    }
    return await repository.markIssueAsReplied(issueId);
  }
}