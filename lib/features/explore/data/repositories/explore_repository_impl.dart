import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_mock_datasource.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreMockDataSource mockDataSource;

  const ExploreRepositoryImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes() async {
    try {
      final recipes = await mockDataSource.getRecipes();
      return Right(recipes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(String recipeId) async {
    try {
      final recipe = await mockDataSource.getRecipeDetail(recipeId);
      return Right(recipe);
    } on StateError {
      return Left(NotFoundFailure(message: 'Recipe not found'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
