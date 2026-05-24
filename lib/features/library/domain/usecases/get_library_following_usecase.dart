import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_social_profile.dart';
import '../repositories/library_repository.dart';

class GetLibraryFollowingUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowingUseCase(this.repository);

  Future<Either<Failure, List<LibrarySocialProfile>>> execute() {
    return repository.getFollowing();
  }
}
