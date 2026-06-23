import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_moderation_recipe.dart';
import '../../domain/repositories/admin_moderation_repository.dart';
import '../datasources/admin_moderation_remote_datasource.dart';

/// Repository implementation for admin moderation.
class AdminModerationRepositoryImpl implements AdminModerationRepository {
  /// Remote datasource dependency.
  final AdminModerationRemoteDataSource remoteDataSource;

  /// Creates an admin moderation repository implementation.
  const AdminModerationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<AdminModerationRecipe>>> watchRecipes() async* {
    try {
      await for (final recipes in remoteDataSource.watchRecipes()) {
        yield Right(recipes);
      }
    } catch (error) {
      yield Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
    String? hiddenReason,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (!isPublished && (hiddenReason?.trim().isEmpty ?? true)) {
      return Left(ValidationFailure(message: 'Hide reason is required.'));
    }

    try {
      await remoteDataSource.updateRecipeVisibility(
        recipeId: recipeId,
        isPublished: isPublished,
        hiddenReason: hiddenReason,
      );
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markRecipeReviewed(String recipeId) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.markRecipeReviewed(recipeId);
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }
}
