import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';

/// Repository interface for exploring recipes, creators, and social interactions.
/// Handles data operations for recipe discovery, ratings, comments, and follows.
abstract class ExploreRepository {
  /// Retrieves all available recipes from the data source.
  /// Returns either a Failure or a list of ExploreRecipe entities.
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes();

  /// Provides a reactive stream of recipe lists that emits updates when data changes.
  /// Useful for real-time UI updates in response to data mutations.
  Stream<List<ExploreRecipe>> watchRecipes();

  /// Emits recipe detail updates for a specific recipe ID over time.
  /// Enables live updates to recipe details without manual polling.
  Stream<ExploreRecipe> watchRecipeDetail(String recipeId);

  /// Fetches detailed information for a single recipe by its identifier.
  /// Returns either a Failure or the requested ExploreRecipe entity.
  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(String recipeId);

  /// Retrieves detailed profile information for a recipe creator.
  /// Returns either a Failure or ExploreCreatorDetail for the given UID.
  Future<Either<Failure, ExploreCreatorDetail>> getCreatorDetail(
      String creatorUid,
      );

  /// Submits a numerical rating for a specific recipe.
  /// Returns either a Failure or void on successful rating submission.
  Future<Either<Failure, void>> submitRating({
    required String recipeId,
    required double rating,
  });

  /// Adds a new comment to a recipe's discussion thread.
  /// Returns either a Failure or void when comment creation succeeds.
  Future<Either<Failure, void>> addComment({
    required String recipeId,
    required String content,
  });

  /// Increments the view counter for a recipe to track popularity.
  /// Returns either a Failure or void after successful view count update.
  Future<Either<Failure, void>> incrementViewCount(String recipeId);

  /// Toggles the like status on a specific comment within a recipe.
  /// Returns either a Failure or void after like state change.
  Future<Either<Failure, void>> toggleCommentLike({
    required String recipeId,
    required String commentId,
  });

  /// Adds a reply to an existing comment in a recipe's discussion.
  /// Returns either a Failure or void after reply creation.
  Future<Either<Failure, void>> addCommentReply({
    required String recipeId,
    required String commentId,
    required String content,
  });

  /// Toggles like status on a reply using a path identifier.
  /// Returns either a Failure or void after toggling reply like.
  Future<Either<Failure, void>> toggleReplyLike({required String replyPath});

  /// Adds a nested reply to an existing reply within a comment thread.
  /// Returns either a Failure or void after nested reply creation.
  Future<Either<Failure, void>> addReplyToReply({
    required String replyPath,
    required String content,
  });

  /// Follows or unfollows a recipe creator based on the follow flag.
  /// Returns either a Failure or void after follow state changes.
  Future<Either<Failure, void>> toggleCreatorFollow({
    required String creatorUid,
    required bool follow,
  });

  /// Updates the publication visibility status of a recipe.
  /// Returns either a Failure or void after visibility update.
  Future<Either<Failure, void>> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
  });
}