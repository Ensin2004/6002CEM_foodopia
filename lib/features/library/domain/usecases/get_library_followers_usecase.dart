import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';
// Use case for fetching a user's followers list
// Encapsulates the business logic for retrieving followers
class GetLibraryFollowersUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowersUseCase(this.repository);
// Executes the use case to fetch followers
  Future<Either<Failure, List<LibraryProfileUser>>> execute({
    String? ownerUid,
  }) {
    return repository.getFollowers(ownerUid: ownerUid);
  }
}
