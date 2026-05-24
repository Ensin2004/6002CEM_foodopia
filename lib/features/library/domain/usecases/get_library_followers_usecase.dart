import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_social_profile.dart';
import '../repositories/library_repository.dart';

class GetLibraryFollowersUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowersUseCase(this.repository);

  Future<Either<Failure, List<LibrarySocialProfile>>> execute() {
    return repository.getFollowers();
  }
}
