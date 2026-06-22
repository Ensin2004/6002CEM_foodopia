import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_image_result.dart';
import '../repositories/add_recipe_repository.dart';

class GenerateAddRecipeIngredientsFromImageUseCase {
  final AddRecipeRepository repository;

  const GenerateAddRecipeIngredientsFromImageUseCase(this.repository);

  Future<Either<Failure, AddRecipeImageResult>> execute(File imageFile) {
    return repository.generateRecipeFromImage(imageFile);
  }
}
