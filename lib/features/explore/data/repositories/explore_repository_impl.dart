import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_remote_datasource.dart';

// Implementation of ExploreRepository that delegates to a remote data source.
class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreRemoteDataSource remoteDataSource;

  const ExploreRepositoryImpl({required this.remoteDataSource});

  // Fetches a list of recipes from the remote source and wraps in Either.
  @override
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes() async {
    try {
      final recipes = await remoteDataSource.getRecipes();
      return Right(recipes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Retrieves detailed information for a single recipe by ID.
  @override
  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(
      String recipeId,
      ) async {
    try {
      final recipe = await remoteDataSource.getRecipeDetail(recipeId);
      return Right(recipe);
    } on StateError {
      // Handles missing recipe case specifically.
      return Left(NotFoundFailure(message: 'Recipe not found'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Submits a user rating with validation of recipe ID and rating range.
  @override
  Future<Either<Failure, void>> submitRating({
    required String recipeId,
    required double rating,
  }) async {
    // Validate that recipe ID is not empty.
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    // Validate rating is within acceptable range.
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

  // Adds a comment to a recipe with content validation.
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

  // Establishes a real-time stream of recipe list updates.
  @override
  Stream<List<ExploreRecipe>> watchRecipes() {
    return remoteDataSource.watchRecipes();
  }

  // Establishes a real-time stream of a single recipe detail updates.
  @override
  Stream<ExploreRecipe> watchRecipeDetail(String recipeId) {
    return remoteDataSource.watchRecipeDetail(recipeId);
  }

  // Increments the view count for a recipe with ID validation.
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

  // Toggles like status on a specific comment.
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

  // Adds a reply to a comment with content validation.
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

  // Toggles like status on a reply using its document path.
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

  // Adds a nested reply to an existing reply.
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

  // Fetches detailed profile information for a recipe creator.
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
      // Indicates creator document does not exist.
      return Left(NotFoundFailure(message: 'Creator not found'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Follows or unfollows a creator based on the follow flag.
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

  // Updates the visibility (published/draft) status of a recipe.
  @override
  Future<Either<Failure, void>> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.updateRecipeVisibility(
        recipeId: recipeId,
        isPublished: isPublished,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}