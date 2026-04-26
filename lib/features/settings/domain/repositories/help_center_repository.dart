import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../entities/help_center_issue.dart';

abstract class HelpCenterRepository {
  Future<Either<Failure, List<HelpCenterIssue>>> getUserIssues(String uid);
  Future<Either<Failure, List<HelpCenterIssue>>> getAllIssues();
  Future<Either<Failure, void>> submitIssue({
    required String uid,
    required String message,
    File? imageFile,
  });
  Future<Either<Failure, void>> markIssueAsReplied(String issueId);
  Future<Either<Failure, String>> uploadIssueImage(File imageFile);
  Future<Either<Failure, String>> getUserEmail(String uid);
}