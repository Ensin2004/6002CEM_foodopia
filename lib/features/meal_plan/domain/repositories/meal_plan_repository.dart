import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../entities/add_meal_ai_plan.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../entities/meal_plan_dashboard.dart';
import '../entities/meal_plan_inspiration_input.dart';

/// Repository interface for meal planning operations.
/// Defines all data operations for meal plans, grocery lists,
/// and AI-generated meal content.
abstract class MealPlanRepository {
  /// Retrieves the meal plan dashboard for a user on a specific date.
  Future<Either<Failure, MealPlanDashboard>> getDashboard({
    required String userId,
    required DateTime selectedDate,
  });

  /// Retrieves only planning data for a user on a specific date.
  Future<Either<Failure, MealPlanDashboard>> getPlanningDashboard({
    required String userId,
    required DateTime selectedDate,
  });

  /// Retrieves weather information for a specific date.
  Future<Either<Failure, MealPlanWeather>> getWeatherForDate(DateTime date);

  /// Retrieves meal preferences for a user.
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(String uid);

  /// Retrieves preference options for a specific category.
  Future<Either<Failure, List<MealPlanPreferenceOption>>>
  getInspirationPreferenceOptions(String categoryId);

  /// Retrieves default inspiration ingredients.
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  getDefaultInspirationIngredients();

  /// Searches for inspiration ingredients matching a query.
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  searchInspirationIngredients(String query);

  /// Retrieves the plan for creating a new grocery list.
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan(
    String userId,
  );

  /// Creates a new grocery list from a request.
  Future<Either<Failure, String>> createGroceryList(
    CreateGroceryListRequest request,
  );

  /// Retrieves the plan for adding AI-generated meals.
  Future<Either<Failure, AddMealAiPlan>> getAddMealAiPlan({
    required String userId,
    required String mealType,
  });

  /// Retrieves all meal categories.
  Future<Either<Failure, List<AddMealCategoryOption>>> getMealCategories();

  /// Generates AI meal ideas based on a request.
  Future<Either<Failure, List<AddMealAiRecipe>>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  );

  /// Saves AI-generated meal plans.
  Future<Either<Failure, void>> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  });

  /// Saves a recipe as a meal plan.
  Future<Either<Failure, void>> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
    required double servingCount,
  });

  /// Deletes a meal plan.
  Future<Either<Failure, void>> deleteMealPlan({
    required String userId,
    required String mealPlanId,
  });

  /// Retrieves detailed information about a grocery list.
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  );

  /// Adds an item to a grocery list.
  Future<Either<Failure, void>> addGroceryItem(AddGroceryItemRequest request);

  /// Deletes an item from a grocery list.
  Future<Either<Failure, void>> deleteGroceryItem({
    required String listId,
    required String itemId,
  });

  /// Deletes a grocery list.
  Future<Either<Failure, void>> deleteGroceryList(String listId);

  /// Updates the bought status of a grocery item.
  Future<Either<Failure, void>> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  });

  /// Updates a grocery list's details.
  Future<Either<Failure, void>> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Updates the user's week start day preference for weekly grocery lists.
  Future<Either<Failure, void>> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  });
}
