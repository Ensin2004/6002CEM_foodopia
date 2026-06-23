import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_moderation_repository.dart';

/// Updates recipe visibility from admin moderation flows.
class UpdateAdminRecipeVisibilityUseCase {
  /// Repository dependency.
  final AdminModerationRepository repository;

  /// Creates an update admin recipe visibility use case.
  const UpdateAdminRecipeVisibilityUseCase(this.repository);

  /// Executes the visibility update.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required bool isPublished,
  }) {
    return repository.updateRecipeVisibility(
      recipeId: recipeId,
      isPublished: isPublished,
    );
  }
}
