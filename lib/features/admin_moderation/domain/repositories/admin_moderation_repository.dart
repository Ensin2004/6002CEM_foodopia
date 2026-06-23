import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_moderation_recipe.dart';

/// Repository contract for admin recipe moderation.
abstract class AdminModerationRepository {
  /// Watches finalized recipes for moderation.
  Stream<Either<Failure, List<AdminModerationRecipe>>> watchRecipes();

  /// Updates a recipe visibility without changing database structure.
  Future<Either<Failure, void>> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
    String? hiddenReason,
  });

  /// Marks a recipe as reviewed.
  Future<Either<Failure, void>> markRecipeReviewed(String recipeId);
}
