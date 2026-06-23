import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remoteDataSource;

  const LibraryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LibraryProfile>> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LibraryProfileUser>>> getFollowers({
    String? ownerUid,
  }) async {
    try {
      final followers = await remoteDataSource.getFollowers(ownerUid: ownerUid);
      return Right(followers);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LibraryProfileUser>>> getFollowing({
    String? ownerUid,
  }) async {
    try {
      final following = await remoteDataSource.getFollowing(ownerUid: ownerUid);
      return Right(following);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LibraryRecipe>>> getRecipes() async {
    try {
      final recipes = await remoteDataSource.getRecipes();
      return Right(recipes);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<LibraryRecipe>>> watchRecipes() async* {
    try {
      await for (final recipes in remoteDataSource.watchRecipes()) {
        yield Right(recipes);
      }
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LibraryRecipe>> getRecipeDetail(
    String recipeId,
  ) async {
    try {
      final recipe = await remoteDataSource.getRecipeDetail(recipeId);
      return Right(recipe);
    } on StateError {
      return Left(NotFoundFailure(message: 'Recipe not found.'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavourite({
    required String recipeId,
    required bool isFavourite,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.toggleFavourite(
        recipeId: recipeId,
        isFavourite: isFavourite,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    try {
      await remoteDataSource.updateProfile(
        name: name,
        bio: bio,
        imageFile: imageFile,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
