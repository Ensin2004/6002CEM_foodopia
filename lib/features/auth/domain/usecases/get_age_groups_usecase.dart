import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

/// Loads the configured age groups used during signup and profile editing.
/// Encapsulates the business logic for fetching age group options.
class GetAgeGroupsUseCase {
  /// Repository instance for data operations.
  final AuthRepository repository;

  /// Creates a new get age groups use case instance.
  GetAgeGroupsUseCase(this.repository);

  /// Executes the use case.
  ///
  /// Returns either an auth failure or a list of age group maps on success.
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> execute() async {
    // Delegate to repository to fetch age groups.
    return await repository.getAgeGroups();
  }
}