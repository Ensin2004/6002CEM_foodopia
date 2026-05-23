import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../entities/add_meal_ai_plan.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../entities/meal_plan_dashboard.dart';
import '../entities/meal_plan_inspiration_input.dart';

abstract class MealPlanRepository {
  Future<Either<Failure, MealPlanDashboard>> getDashboard();
  Future<Either<Failure, MealPlanWeather>> getTodayWeather();
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(String uid);
  Future<Either<Failure, List<MealPlanPreferenceOption>>>
  getInspirationPreferenceOptions(String categoryId);
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  getDefaultInspirationIngredients();
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  searchInspirationIngredients(String query);
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan();
  Future<Either<Failure, AddMealAiPlan>> getAddMealAiPlan({
    required String userId,
    required String mealType,
  });
  Future<Either<Failure, List<AddMealCategoryOption>>> getMealCategories();
  Future<Either<Failure, List<AddMealAiRecipe>>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  );
  Future<Either<Failure, void>> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  });
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  );
}
