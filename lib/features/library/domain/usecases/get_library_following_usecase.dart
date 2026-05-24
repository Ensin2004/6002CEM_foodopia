import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';

class GetLibraryFollowingUseCase {
  final LibraryRepository repository;

  const GetLibraryFollowingUseCase(this.repository);

  Future<Either<Failure, List<LibraryProfileUser>>> execute() {
    return repository.getFollowing();
  }
}
