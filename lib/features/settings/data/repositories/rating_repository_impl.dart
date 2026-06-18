// Implements repository operations for rating.

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';
import '../models/rating_model.dart';

/// Defines behavior for rating repository impl.
/// Implements the RatingRepository interface using remote data source.
class RatingRepositoryImpl implements RatingRepository {
  /// Remote data source for rating operations.
  final RatingRemoteDataSource remoteDataSource;

  /// Creates a rating repository impl instance.
  RatingRepositoryImpl({required this.remoteDataSource});

  /// Loads data for the get user rating operation.
  @override
  Future<Either<Failure, RatingEntity>> getUserRating(String userId) async {
    try {
      // Runs the guarded operation that can throw.
      final doc = await remoteDataSource.getUserRating(userId);

      // Return not found if rating doesn't exist.
      if (!doc.exists) {
        return Left(NotFoundFailure(message: 'No rating found'));
      }

      // Parse and return the rating.
      final rating = RatingModel.fromFirestore(doc);
      return Right(rating);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Loads data for the get all ratings operation.
  @override
  Future<Either<Failure, List<RatingEntity>>> getAllRatings() async {
    try {
      // Runs the guarded operation that can throw.
      final snapshot = await remoteDataSource.getAllRatings();

      // Map Firestore documents to domain entities.
      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc) as RatingEntity)
          .toList();

      return Right(ratings);
    } catch (e) {
      // Map any exception to a server failure.
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

      // Upload new image if provided.
      if (imageFile != null) {
        finalImageUrl = await remoteDataSource.uploadRatingImage(imageFile);
      }

      // Create rating model.
      final rating = RatingModel(
        userId: userId,
        stars: stars,
        comment: comment,
        imageUrl: finalImageUrl,
        updatedAt: DateTime.now(),
      );

      // Get user profile for name.
      final profile = await remoteDataSource.getUserProfile(userId);
      final profileData = profile.data() as Map<String, dynamic>?;
      final userName = profileData?['name'] as String? ?? '';

      // Prepare rating data with user name.
      final ratingData = {...rating.toJson(), 'userName': userName};

      // Handle image deletion if no image provided.
      if (finalImageUrl == null) {
        ratingData['imageUrl'] = FieldValue.delete();
      }

      // Save the rating.
      await remoteDataSource.saveRating(userId, ratingData);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
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
      // Map any exception to a server failure.
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
      // Map any exception to a server failure.
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

      // Return profile data if exists, otherwise empty map.
      if (doc.exists) {
        return Right(doc.data() as Map<String, dynamic>);
      }
      return Right({});
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}