import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/help_center_repository.dart';

class ReplyToIssueUseCase {
  final HelpCenterRepository repository;

  const ReplyToIssueUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String issueId,
    required String userUid,
    required String reply,
  }) {
    final trimmedReply = reply.trim();
    if (issueId.trim().isEmpty) {
      return Future.value(
        Left(ValidationFailure(message: 'Issue ID cannot be empty')),
      );
    }
    if (trimmedReply.isEmpty) {
      return Future.value(
        Left(ValidationFailure(message: 'Reply cannot be empty')),
      );
    }
    return repository.replyToIssue(
      issueId: issueId.trim(),
      userUid: userUid.trim(),
      reply: trimmedReply,
    );
  }
}
