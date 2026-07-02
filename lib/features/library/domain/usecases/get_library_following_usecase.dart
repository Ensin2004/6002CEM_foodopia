import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';
// Use case for fetching the list of users that a user is following
// Encapsulates the business logic for retrieving the following list
class GetLibraryFollowingUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowingUseCase(this.repository);
  // Executes the use case to fetch following list
  Future<Either<Failure, List<LibraryProfileUser>>> execute({
    String? ownerUid,
  }) {
    return repository.getFollowing(ownerUid: ownerUid);
  }
}
