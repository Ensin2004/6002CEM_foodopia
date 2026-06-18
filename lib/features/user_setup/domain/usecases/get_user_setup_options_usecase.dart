import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../repositories/user_setup_repository.dart';

/// Use case for retrieving user setup options from admin configuration.
/// Encapsulates the business logic for fetching setup options by category.
class GetUserSetupOptionsUseCase {
  /// Repository instance for data operations.
  final UserSetupRepository repository;

  /// Creates a new get user setup options use case instance.
  GetUserSetupOptionsUseCase(this.repository);

  /// Executes the use case with the given category ID.
  ///
  /// [categoryId] is the ID of the category (e.g., 'diet', 'allergies').
  /// Returns either a failure or a list of setup options on success.
  Future<Either<Failure, List<UserSetupOption>>> execute(String categoryId) {
    // Delegate to repository to fetch admin options.
    return repository.getAdminOptions(categoryId);
  }
}