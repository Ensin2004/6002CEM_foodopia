import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_center_issue.dart';
import '../repositories/help_center_repository.dart';

class GetUserIssuesUseCase {
  final HelpCenterRepository repository;

  GetUserIssuesUseCase(this.repository);

  Future<Either<Failure, List<HelpCenterIssue>>> execute(String uid) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserIssues(uid);
  }
}