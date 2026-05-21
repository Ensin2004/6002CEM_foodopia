// Declares repository contracts for help center.

import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../entities/help_center_issue.dart';

/// Defines behavior for help center repository.
abstract class HelpCenterRepository {
  /// Loads data for the get user issues operation.
  Future<Either<Failure, List<HelpCenterIssue>>> getUserIssues(String uid);
  /// Loads data for the get all issues operation.
  Future<Either<Failure, List<HelpCenterIssue>>> getAllIssues();
  /// Runs the submit issue operation.
  Future<Either<Failure, void>> submitIssue({
    required String uid,
    required String message,
    File? imageFile,
  });
  /// Handles the mark issue as replied operation.
  Future<Either<Failure, void>> markIssueAsReplied(String issueId);
  /// Runs the upload issue image operation.
  Future<Either<Failure, String>> uploadIssueImage(File imageFile);
  /// Loads data for the get user email operation.
  Future<Either<Failure, String>> getUserEmail(String uid);
}
