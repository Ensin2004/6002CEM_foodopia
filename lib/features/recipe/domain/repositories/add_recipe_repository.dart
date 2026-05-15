import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_basic_info.dart';
import '../entities/add_recipe_setup.dart';

abstract class AddRecipeRepository {
  Future<Either<Failure, AddRecipeSetup>> getSetup();

  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info);
}
