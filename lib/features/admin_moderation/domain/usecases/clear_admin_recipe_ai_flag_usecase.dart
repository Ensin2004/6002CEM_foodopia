import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_moderation_repository.dart';

/// Clears AI review flag metadata from an admin moderation recipe.
class ClearAdminRecipeAiFlagUseCase {
  /// Repository dependency.
  final AdminModerationRepository repository;

  /// Creates a clear AI flag use case.
  const ClearAdminRecipeAiFlagUseCase(this.repository);

  /// Executes the clear flag operation.
  Future<Either<Failure, void>> execute(String recipeId) {
    return repository.clearRecipeAiFlag(recipeId);
  }
}
