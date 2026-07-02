import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_video_result.dart';
import '../repositories/add_recipe_repository.dart';

/// Generates editable recipe data from an uploaded cooking video.
class GenerateAddRecipeFromVideoUseCase {
  final AddRecipeRepository repository;

  const GenerateAddRecipeFromVideoUseCase(this.repository);

  Future<Either<Failure, AddRecipeVideoResult>> execute(String videoPath) {
    return repository.generateRecipeFromVideo(videoPath);
  }
}
