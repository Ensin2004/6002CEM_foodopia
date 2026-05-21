import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_instruction.dart';
import '../repositories/add_recipe_repository.dart';

class SaveAddRecipeInstructionsUseCase {
  final AddRecipeRepository repository;

  const SaveAddRecipeInstructionsUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) {
    return repository.saveInstructions(
      recipeId: recipeId,
      useSections: useSections,
      instructions: instructions,
    );
  }
}
