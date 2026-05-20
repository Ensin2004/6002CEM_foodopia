import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class ToggleCreatorFollowUseCase {
  final ExploreRepository repository;

  const ToggleCreatorFollowUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String creatorUid,
    required bool follow,
  }) {
    return repository.toggleCreatorFollow(
      creatorUid: creatorUid,
      follow: follow,
    );
  }
}
