// Implements repository operations for rating.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';
import '../models/rating_model.dart';

/// Defines behavior for rating repository impl.
class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;

  /// Creates a rating repository impl instance.
  RatingRepositoryImpl({required this.remoteDataSource});

  /// Loads data for the get user rating operation.
  @override
  Future<Either<Failure, RatingEntity>> getUserRating(String userId) async {
    try {
      // Runs the guarded operation that can throw.
      final doc = await remoteDataSource.getUserRating(userId);
      if (!doc.exists) {
        return Left(NotFoundFailure(message: 'No rating found'));
      }
      final rating = RatingModel.fromFirestore(doc);
      return Right(rating);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Loads data for the get all ratings operation.
  @override
  Future<Either<Failure, List<RatingEntity>>> getAllRatings() async {
    try {
      // Runs the guarded operation that can throw.
      final snapshot = await remoteDataSource.getAllRatings();
      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc) as RatingEntity)
          .toList();
      return Right(ratings);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the save rating operation.
  @override
  Future<Either<Failure, void>> saveRating({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      String? finalImageUrl = existingImageUrl;

      if (imageFile != null) {
        finalImageUrl = await remoteDataSource.uploadRatingImage(imageFile);
      }

      final rating = RatingModel(
        userId: userId,
        stars: stars,
        comment: comment,
        imageUrl: finalImageUrl,
        updatedAt: DateTime.now(),
      );

      final profile = await remoteDataSource.getUserProfile(userId);
      final profileData = profile.data() as Map<String, dynamic>?;
      final userName = profileData?['name'] as String? ?? '';

      await remoteDataSource.saveRating(userId, {
        ...rating.toJson(),
        'userName': userName,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the delete rating operation.
  @override
  Future<Either<Failure, void>> deleteRating(String userId) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.deleteRating(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the upload rating image operation.
  @override
  Future<Either<Failure, String>> uploadRatingImage(File imageFile) async {
    try {
      // Runs the guarded operation that can throw.
      final imageUrl = await remoteDataSource.uploadRatingImage(imageFile);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Loads data for the get user profile operation.
  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile(
    String userId,
  ) async {
    try {
      // Runs the guarded operation that can throw.
      final doc = await remoteDataSource.getUserProfile(userId);
      if (doc.exists) {
        return Right(doc.data() as Map<String, dynamic>);
      }
      return Right({});
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
