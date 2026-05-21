// Executes the get admin issues use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/help_center_issue.dart';
import '../../../repositories/help_center_repository.dart';

/// Loads data for the get admin issues use case operation.
class GetAdminIssuesUseCase {
  final HelpCenterRepository repository;

  /// Loads data for the get admin issues use case operation.
  GetAdminIssuesUseCase(this.repository);

  /// Validates input and delegates the get admin issues request to the repository.
  Future<Either<Failure, List<HelpCenterIssue>>> execute() async {
    return await repository.getAllIssues();
  }
}
