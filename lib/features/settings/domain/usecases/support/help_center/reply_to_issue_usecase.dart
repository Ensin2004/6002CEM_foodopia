import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/help_center_repository.dart';

/// Use case for replying to a help center issue.
/// Handles replying to an issue with validation.
class ReplyToIssueUseCase {
  /// Repository instance for data operations.
  final HelpCenterRepository repository;

  /// Creates a new reply to issue use case instance.
  const ReplyToIssueUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [issueId] is the ID of the issue to reply to.
  /// [userUid] is the ID of the user who owns the issue.
  /// [reply] is the reply text from the admin.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String issueId,
    required String userUid,
    required String reply,
  }) {
    // Trim the reply text.
    final trimmedReply = reply.trim();

    // Validate the issue ID.
    if (issueId.trim().isEmpty) {
      return Future.value(
        Left(ValidationFailure(message: 'Issue ID cannot be empty')),
      );
    }

    // Validate the reply.
    if (trimmedReply.isEmpty) {
      return Future.value(
        Left(ValidationFailure(message: 'Reply cannot be empty')),
      );
    }

    // Delegate to repository to reply to the issue.
    return repository.replyToIssue(
      issueId: issueId.trim(),
      userUid: userUid.trim(),
      reply: trimmedReply,
    );
  }
}