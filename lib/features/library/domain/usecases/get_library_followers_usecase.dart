import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';

class GetLibraryFollowersUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowersUseCase(this.repository);

  Future<Either<Failure, List<LibraryProfileUser>>> execute({
    String? ownerUid,
  }) {
    return repository.getFollowers(ownerUid: ownerUid);
  }
}
