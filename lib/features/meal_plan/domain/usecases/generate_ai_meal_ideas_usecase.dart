import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

class GenerateAiMealIdeasUseCase {
  final MealPlanRepository repository;

  const GenerateAiMealIdeasUseCase(this.repository);

  Future<Either<Failure, List<AddMealAiRecipe>>> execute(
    AddMealAiGenerationRequest request,
  ) {
    return repository.generateAiMealIdeas(request);
  }
}
