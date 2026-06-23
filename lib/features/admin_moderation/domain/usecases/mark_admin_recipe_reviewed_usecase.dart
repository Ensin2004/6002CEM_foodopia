import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_moderation_repository.dart';

/// Marks an admin moderation recipe as reviewed.
class MarkAdminRecipeReviewedUseCase {
  /// Repository dependency.
  final AdminModerationRepository repository;

  /// Creates a mark admin recipe reviewed use case.
  const MarkAdminRecipeReviewedUseCase(this.repository);

  /// Executes the mark reviewed operation.
  Future<Either<Failure, void>> execute(String recipeId) {
    return repository.markRecipeReviewed(recipeId);
  }
}
