import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for generating AI meal ideas.
/// Encapsulates the business logic for AI meal generation.
class GenerateAiMealIdeasUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new generate AI meal ideas use case instance.
  const GenerateAiMealIdeasUseCase(this.repository);

  /// Executes the use case with the given request.
  ///
  /// [request] contains the parameters for AI meal generation.
  /// Returns either a failure or a list of AI-generated recipes on success.
  Future<Either<Failure, List<AddMealAiRecipe>>> execute(
      AddMealAiGenerationRequest request,
      ) {
    // Delegate to repository to generate meal ideas.
    return repository.generateAiMealIdeas(request);
  }
}