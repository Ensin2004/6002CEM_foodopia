import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../entities/library_recipe.dart';
import '../entities/library_social_profile.dart';

abstract class LibraryRepository {
  Future<Either<Failure, LibraryProfile>> getProfile();

  Future<Either<Failure, List<LibraryRecipe>>> getRecipes();

  Future<Either<Failure, LibraryRecipe>> getRecipeDetail(String recipeId);

  Future<Either<Failure, List<LibrarySocialProfile>>> getFollowers();

  Future<Either<Failure, List<LibrarySocialProfile>>> getFollowing();

  Future<Either<Failure, void>> toggleFavourite({
    required String recipeId,
    required bool isFavourite,
  });

  Future<Either<Failure, void>> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  });
}
