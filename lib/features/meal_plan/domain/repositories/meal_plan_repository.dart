import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../entities/add_meal_ai_plan.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../entities/meal_plan_dashboard.dart';
import '../entities/meal_plan_inspiration_input.dart';

abstract class MealPlanRepository {
  Future<Either<Failure, MealPlanDashboard>> getDashboard({
    required String userId,
    required DateTime selectedDate,
  });
  Future<Either<Failure, MealPlanWeather>> getWeatherForDate(DateTime date);
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(String uid);
  Future<Either<Failure, List<MealPlanPreferenceOption>>>
  getInspirationPreferenceOptions(String categoryId);
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  getDefaultInspirationIngredients();
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  searchInspirationIngredients(String query);
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan(
    String userId,
  );
  Future<Either<Failure, String>> createGroceryList(
    CreateGroceryListRequest request,
  );
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
  Future<Either<Failure, void>> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
  });
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  );
  Future<Either<Failure, void>> addGroceryItem(AddGroceryItemRequest request);
  Future<Either<Failure, void>> deleteGroceryItem({
    required String listId,
    required String itemId,
  });
  Future<Either<Failure, void>> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  });
  Future<Either<Failure, void>> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Either<Failure, void>> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  });
}
