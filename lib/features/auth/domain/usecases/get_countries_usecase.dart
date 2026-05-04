// Executes the get countries use case.

import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

/// Loads data for the get countries use case operation.
class GetCountriesUseCase {
  final AuthRepository repository;

  /// Loads data for the get countries use case operation.
  GetCountriesUseCase(this.repository);

  /// Validates input and delegates the get countries request to the repository.
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> execute() async {
    return await repository.getCountries();
  }
}
