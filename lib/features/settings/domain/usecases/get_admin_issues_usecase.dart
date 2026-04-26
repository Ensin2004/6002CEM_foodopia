import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_center_issue.dart';
import '../repositories/help_center_repository.dart';

class GetAdminIssuesUseCase {
  final HelpCenterRepository repository;

  GetAdminIssuesUseCase(this.repository);

  Future<Either<Failure, List<HelpCenterIssue>>> execute() async {
    return await repository.getAllIssues();
  }
}