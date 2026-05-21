import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

class GetExploreCreatorDetailUseCase {
  final ExploreRepository repository;

  const GetExploreCreatorDetailUseCase(this.repository);

  Future<Either<Failure, ExploreCreatorDetail>> execute(String creatorUid) {
    return repository.getCreatorDetail(creatorUid);
  }
}
