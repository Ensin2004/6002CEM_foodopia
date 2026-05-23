import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealPlanInspirationOptionsUseCase {
  final MealPlanRepository repository;

  const GetMealPlanInspirationOptionsUseCase(this.repository);

  Future<Either<Failure, List<MealPlanPreferenceOption>>> execute(
    String categoryId,
  ) {
    return repository.getInspirationPreferenceOptions(categoryId);
  }
}
