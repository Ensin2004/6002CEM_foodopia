import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_moderation_recipe.dart';
import '../repositories/admin_moderation_repository.dart';

/// Watches recipe summaries used by the admin moderation page.
class WatchAdminModerationRecipesUseCase {
  /// Repository dependency.
  final AdminModerationRepository repository;

  /// Creates a watch admin moderation recipes use case.
  const WatchAdminModerationRecipesUseCase(this.repository);

  /// Executes the watch operation.
  Stream<Either<Failure, List<AdminModerationRecipe>>> execute() {
    return repository.watchRecipes();
  }
}
