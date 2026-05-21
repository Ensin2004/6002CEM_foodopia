// Declares repository contracts for rating.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating.dart';

/// Defines behavior for rating repository.
abstract class RatingRepository {
  /// Loads data for the get user rating operation.
  Future<Either<Failure, RatingEntity>> getUserRating(String userId);
  /// Loads data for the get all ratings operation.
  Future<Either<Failure, List<RatingEntity>>> getAllRatings();
  /// Runs the save rating operation.
  Future<Either<Failure, void>> saveRating({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  });
  /// Runs the delete rating operation.
  Future<Either<Failure, void>> deleteRating(String userId);
  /// Runs the upload rating image operation.
  Future<Either<Failure, String>> uploadRatingImage(File imageFile);
  /// Loads data for the get user profile operation.
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile(String userId);
}
