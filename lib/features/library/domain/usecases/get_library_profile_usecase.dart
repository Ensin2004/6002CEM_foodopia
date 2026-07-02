import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';
// Use case for fetching detailed information about a specific recipe
// Encapsulates the business logic for retrieving a recipe by its ID
class GetLibraryProfileUseCase {
  final LibraryRepository repository;

  const GetLibraryProfileUseCase(this.repository);
// Executes the use case to fetch recipe details.
  Future<Either<Failure, LibraryProfile>> execute() {
    return repository.getProfile();
  }
}
