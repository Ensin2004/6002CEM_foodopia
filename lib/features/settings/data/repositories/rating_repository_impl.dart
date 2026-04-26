import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';
import '../models/rating_model.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;

  RatingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RatingEntity>> getUserRating(String userId) async {
    try {
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

  @override
  Future<Either<Failure, List<RatingEntity>>> getAllRatings() async {
    try {
      final snapshot = await remoteDataSource.getAllRatings();
      final ratings = snapshot.docs
          .map((doc) => RatingModel.fromFirestore(doc) as RatingEntity)
          .toList();
      return Right(ratings);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveRating({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    try {
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

      await remoteDataSource.saveRating(userId, rating.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRating(String userId) async {
    try {
      await remoteDataSource.deleteRating(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadRatingImage(File imageFile) async {
    try {
      final imageUrl = await remoteDataSource.uploadRatingImage(imageFile);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile(String userId) async {
    try {
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