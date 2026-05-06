import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../repositories/user_setup_repository.dart';

class SearchUserSetupFoodsUseCase {
  final UserSetupRepository repository;

  SearchUserSetupFoodsUseCase(this.repository);

  Future<Either<Failure, List<UserSetupOption>>> execute(String query) {
    return repository.searchFoods(query);
  }
}
