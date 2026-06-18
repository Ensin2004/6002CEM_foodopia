import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../repositories/user_setup_repository.dart';

/// Use case for searching foods during user setup.
/// Encapsulates the business logic for food search.
class SearchUserSetupFoodsUseCase {
  /// Repository instance for data operations.
  final UserSetupRepository repository;

  /// Creates a new search user setup foods use case instance.
  SearchUserSetupFoodsUseCase(this.repository);

  /// Executes the use case with the given search query.
  ///
  /// [query] is the search string.
  /// Returns either a failure or a list of matching food options on success.
  Future<Either<Failure, List<UserSetupOption>>> execute(String query) {
    // Delegate to repository to search foods.
    return repository.searchFoods(query);
  }
}