import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';

abstract class ExploreRepository {
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes();

  Stream<List<ExploreRecipe>> watchRecipes();

  Stream<ExploreRecipe> watchRecipeDetail(String recipeId);

  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(String recipeId);

  Future<Either<Failure, ExploreCreatorDetail>> getCreatorDetail(
    String creatorUid,
  );

  Future<Either<Failure, void>> submitRating({
    required String recipeId,
    required double rating,
  });

  Future<Either<Failure, void>> addComment({
    required String recipeId,
    required String content,
  });

  Future<Either<Failure, void>> incrementViewCount(String recipeId);

  Future<Either<Failure, void>> toggleCommentLike({
    required String recipeId,
    required String commentId,
  });

  Future<Either<Failure, void>> addCommentReply({
    required String recipeId,
    required String commentId,
    required String content,
  });

  Future<Either<Failure, void>> toggleReplyLike({required String replyPath});

  Future<Either<Failure, void>> addReplyToReply({
    required String replyPath,
    required String content,
  });

  Future<Either<Failure, void>> toggleCreatorFollow({
    required String creatorUid,
    required bool follow,
  });

  Future<Either<Failure, void>> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
  });
}
