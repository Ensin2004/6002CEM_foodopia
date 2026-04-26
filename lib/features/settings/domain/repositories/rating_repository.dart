import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating.dart';

abstract class RatingRepository {
  Future<Either<Failure, RatingEntity>> getUserRating(String userId);
  Future<Either<Failure, List<RatingEntity>>> getAllRatings();
  Future<Either<Failure, void>> saveRating({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  });
  Future<Either<Failure, void>> deleteRating(String userId);
  Future<Either<Failure, String>> uploadRatingImage(File imageFile);
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile(String userId);
}