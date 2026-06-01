// Declares repository contracts for about.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/about_content.dart';

/// Defines behavior for about repository.
abstract class AboutRepository {
  /// Loads data for the get about content operation.
  Future<Either<Failure, AboutContent>> getAboutContent(String documentId);
  Stream<Either<Failure, AboutContent>> watchAboutContent(String documentId);

  /// Runs the save about content operation.
  Future<Either<Failure, void>> saveAboutContent(
    String documentId,
    String content,
  ); // Changed from update to save
  Future<Either<Failure, void>> deleteAboutContent(String documentId);
}
