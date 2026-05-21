import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_remote_datasource.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreRemoteDataSource remoteDataSource;

  const ExploreRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes() async {
    try {
      final recipes = await remoteDataSource.getRecipes();
      return Right(recipes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(
    String recipeId,
  ) async {
    try {
      final recipe = await remoteDataSource.getRecipeDetail(recipeId);
      return Right(recipe);
    } on StateError {
      return Left(NotFoundFailure(message: 'Recipe not found'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitRating({
    required String recipeId,
    required double rating,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (rating < 1 || rating > 5) {
      return Left(
        ValidationFailure(message: 'Please select a rating from 1 to 5.'),
      );
    }

    try {
      await remoteDataSource.submitRating(recipeId: recipeId, rating: rating);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment({
    required String recipeId,
    required String content,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (content.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a comment.'));
    }

    try {
      await remoteDataSource.addComment(recipeId: recipeId, content: content);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<ExploreRecipe>> watchRecipes() {
    return remoteDataSource.watchRecipes();
  }

  @override
  Stream<ExploreRecipe> watchRecipeDetail(String recipeId) {
    return remoteDataSource.watchRecipeDetail(recipeId);
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String recipeId) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.incrementViewCount(recipeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleCommentLike({
    required String recipeId,
    required String commentId,
  }) async {
    if (recipeId.trim().isEmpty || commentId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Comment is missing.'));
    }

    try {
      await remoteDataSource.toggleCommentLike(
        recipeId: recipeId,
        commentId: commentId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCommentReply({
    required String recipeId,
    required String commentId,
    required String content,
  }) async {
    if (recipeId.trim().isEmpty || commentId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Comment is missing.'));
    }
    if (content.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a reply.'));
    }

    try {
      await remoteDataSource.addCommentReply(
        recipeId: recipeId,
        commentId: commentId,
        content: content,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleReplyLike({
    required String replyPath,
  }) async {
    if (replyPath.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Reply is missing.'));
    }

    try {
      await remoteDataSource.toggleReplyLike(replyPath: replyPath);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReplyToReply({
    required String replyPath,
    required String content,
  }) async {
    if (replyPath.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Reply is missing.'));
    }
    if (content.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a reply.'));
    }

    try {
      await remoteDataSource.addReplyToReply(
        replyPath: replyPath,
        content: content,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExploreCreatorDetail>> getCreatorDetail(
    String creatorUid,
  ) async {
    if (creatorUid.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Creator is missing.'));
    }

    try {
      final creator = await remoteDataSource.getCreatorDetail(creatorUid);
      return Right(creator);
    } on StateError {
      return Left(NotFoundFailure(message: 'Creator not found'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleCreatorFollow({
    required String creatorUid,
    required bool follow,
  }) async {
    if (creatorUid.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Creator is missing.'));
    }

    try {
      await remoteDataSource.toggleCreatorFollow(
        creatorUid: creatorUid,
        follow: follow,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
