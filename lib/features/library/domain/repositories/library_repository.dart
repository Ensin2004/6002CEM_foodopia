import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../entities/library_recipe.dart';

abstract class LibraryRepository {
  Future<Either<Failure, LibraryProfile>> getProfile();

  Future<Either<Failure, List<LibraryRecipe>>> getRecipes();

  Future<Either<Failure, LibraryRecipe>> getRecipeDetail(String recipeId);

  Future<Either<Failure, void>> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  });
}
