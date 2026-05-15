import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_setup.dart';
import '../../domain/repositories/add_recipe_repository.dart';
import '../datasources/add_recipe_remote_datasource.dart';

class AddRecipeRepositoryImpl implements AddRecipeRepository {
  final AddRecipeRemoteDataSource remoteDataSource;

  const AddRecipeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AddRecipeSetup>> getSetup() async {
    try {
      final setup = await remoteDataSource.getSetup();
      return Right(setup);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load recipe categories.'));
    }
  }

  @override
  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info) async {
    if (info.mediaFiles.isEmpty) {
      return Left(ValidationFailure(message: 'Please upload a recipe image.'));
    }
    if (info.recipeName.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a recipe name.'));
    }
    if (info.categories.isEmpty) {
      return Left(ValidationFailure(message: 'Please select a category.'));
    }
    if (info.preparationMinutes <= 0) {
      return Left(ValidationFailure(message: 'Preparation time must be more than 0.'));
    }
    if (info.difficultyLevel < 1 || info.difficultyLevel > 5) {
      return Left(ValidationFailure(message: 'Please select a difficulty level from 1 to 5.'));
    }
    if (info.servings <= 0) {
      return Left(ValidationFailure(message: 'Servings must be more than 0.'));
    }

    try {
      final recipeId = await remoteDataSource.saveBasicInfo(info);
      return Right(recipeId);
    } catch (error) {
      return Left(ServerFailure(message: 'Unable to save recipe basic info: $error'));
    }
  }
}
