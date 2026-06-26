import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../entities/library_recipe.dart';

// Repository interface for the library feature.
// Defines the contract for data operations related to library profiles
abstract class LibraryRepository {
  Future<Either<Failure, LibraryProfile>> getProfile();

  Future<Either<Failure, List<LibraryProfileUser>>> getFollowers({
    String? ownerUid,
  });

  Future<Either<Failure, List<LibraryProfileUser>>> getFollowing({
    String? ownerUid,
  });

  Future<Either<Failure, List<LibraryRecipe>>> getRecipes();

  Stream<Either<Failure, List<LibraryRecipe>>> watchRecipes();

  Future<Either<Failure, LibraryRecipe>> getRecipeDetail(String recipeId);

  Future<Either<Failure, void>> toggleFavourite({
    required String recipeId,
    required bool isFavourite,
  });

// Updates the current user's profile information.
  Future<Either<Failure, void>> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  });
}
