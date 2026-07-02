import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../datasources/meal_plan_inspiration_datasource.dart';
import '../datasources/meal_plan_preferences_datasource.dart';
import '../datasources/meal_plan_remote_datasource.dart';
import '../datasources/meal_plan_weather_datasource.dart';

/// Implementation of the meal plan repository.
/// Coordinates data from multiple data sources and handles error mapping.
class MealPlanRepositoryImpl implements MealPlanRepository {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Remote data source for meal plan and grocery list operations.
  final MealPlanRemoteDataSource remoteDataSource;

  /// Data source for weather information.
  final MealPlanWeatherDataSource weatherDataSource;

  /// Data source for user meal preferences.
  final MealPlanPreferencesDataSource preferencesDataSource;

  /// Data source for AI-generated meal inspiration.
  final MealPlanInspirationDataSource inspirationDataSource;

  /// Creates a new repository instance with required dependencies.
  const MealPlanRepositoryImpl({
    required this.remoteDataSource,
    required this.weatherDataSource,
    required this.preferencesDataSource,
    required this.inspirationDataSource,
  });

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Retrieves the meal plan dashboard for a user on a specific date.
  @override
  Future<Either<Failure, MealPlanDashboard>> getDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    try {
      // Delegate to remote data source.
      final dashboard = await remoteDataSource.getDashboard(
        userId: userId,
        selectedDate: selectedDate,
      );
      return Right(dashboard);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Retrieves only the planning dashboard data for a user on a specific date.
  @override
  Future<Either<Failure, MealPlanDashboard>> getPlanningDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    try {
      final dashboard = await remoteDataSource.getPlanningDashboard(
        userId: userId,
        selectedDate: selectedDate,
      );
      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // WEATHER
  // =========================================================================

  /// Retrieves weather information for a specific date.
  @override
  Future<Either<Failure, MealPlanWeather>> getWeatherForDate(
    DateTime date,
  ) async {
    try {
      // Delegate to weather data source.
      final weather = await weatherDataSource.getWeatherForDate(date);
      return Right(weather);
    } on RangeError catch (e) {
      // Map range errors to network failures.
      return Left(NetworkFailure(message: e.message.toString()));
    } catch (e) {
      // Map all other exceptions to network failures.
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // PREFERENCES
  // =========================================================================

  /// Retrieves meal preferences for a user.
  @override
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(
    String uid,
  ) async {
    try {
      // Delegate to preferences data source.
      final preferences = await preferencesDataSource.getPreferences(uid);
      return Right(preferences);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Retrieves preference options for a specific category.
  @override
  Future<Either<Failure, List<MealPlanPreferenceOption>>>
  getInspirationPreferenceOptions(String categoryId) async {
    try {
      // Delegate to inspiration data source.
      final options = await inspirationDataSource.getPreferenceOptions(
        categoryId,
      );
      return Right(options);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // INGREDIENTS
  // =========================================================================

  /// Retrieves default inspiration ingredients.
  @override
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  getDefaultInspirationIngredients() async {
    try {
      // Delegate to inspiration data source.
      final ingredients = await inspirationDataSource.getDefaultIngredients();
      return Right(ingredients);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Searches for inspiration ingredients matching a query.
  @override
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  searchInspirationIngredients(String query) async {
    try {
      // Delegate to inspiration data source.
      final ingredients = await inspirationDataSource.searchIngredients(query);
      return Right(ingredients);
    } catch (e) {
      // Map any exception to a network failure.
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // GROCERY LIST - CREATE
  // =========================================================================

  /// Retrieves the plan for creating a new grocery list.
  @override
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan(
    String userId,
  ) async {
    try {
      // Delegate to remote data source.
      final plan = await remoteDataSource.getAddGroceryListPlan(userId);
      return Right(plan);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Creates a new grocery list from a request.
  @override
  Future<Either<Failure, String>> createGroceryList(
    CreateGroceryListRequest request,
  ) async {
    try {
      // Delegate to remote data source.
      final listId = await remoteDataSource.createGroceryList(request);
      return Right(listId);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // AI MEAL PLAN
  // =========================================================================

  /// Retrieves the plan for adding AI-generated meals.
  @override
  Future<Either<Failure, AddMealAiPlan>> getAddMealAiPlan({
    required String userId,
    required String mealType,
  }) async {
    try {
      // Fetch user preferences.
      final preferences = await preferencesDataSource.getPreferences(userId);

      // Get today's date without time.
      final today = DateTime.now();
      final planningDate = DateTime(today.year, today.month, today.day);

      // Fetch default ingredients.
      final ingredients = await inspirationDataSource.getDefaultIngredients();

      // Fetch meal categories.
      final categories = await remoteDataSource.getMealCategories();

      // Fetch weather snapshot.
      final weather = await _weatherSnapshotFor(planningDate);

      // Build preference snapshot.
      final preferenceSnapshot = AddMealPreferenceSnapshot(
        diet: preferences.diet,
        allergies: preferences.allergies,
        dislikes: preferences.dislikes,
      );

      // Return the complete meal plan.
      return Right(
        AddMealAiPlan(
          planningDate: planningDate,
          mealType: mealType,
          weather: weather,
          preferences: preferenceSnapshot,
          ingredientsToInclude: ingredients.map((item) => item.name).toList(),
          ingredientsToAvoid: [
            ...preferences.allergies,
            ...preferences.dislikes,
          ],
          dishPreferences: categories.map((item) => item.name).toList(),
          topMatches: const [],
          aiIdeas: const [],
        ),
      );
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // MEAL CATEGORIES
  // =========================================================================

  /// Retrieves all meal categories.
  @override
  Future<Either<Failure, List<AddMealCategoryOption>>>
  getMealCategories() async {
    try {
      // Delegate to remote data source.
      final categories = await remoteDataSource.getMealCategories();
      return Right(categories);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // AI GENERATION
  // =========================================================================

  /// Generates AI meal ideas based on a request.
  @override
  Future<Either<Failure, List<AddMealAiRecipe>>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  ) async {
    try {
      // Delegate to inspiration data source.
      final ideas = await inspirationDataSource.generateAiMealIdeas(request);
      return Right(ideas);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Saves AI-generated meal plans.
  @override
  Future<Either<Failure, void>> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) async {
    try {
      // Delegate to inspiration data source.
      await inspirationDataSource.saveAiMealPlans(
        userId: userId,
        date: date,
        mealCategory: mealCategory,
        recipes: recipes,
        request: request,
      );
      await _syncCurrentWeeklyGroceryList(userId);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // MEAL PLAN CRUD
  // =========================================================================

  /// Saves a recipe as a meal plan.
  @override
  Future<Either<Failure, void>> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
    required double servingCount,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.saveRecipeMealPlan(
        userId: userId,
        date: date,
        mealCategory: mealCategory,
        recipe: recipe,
        source: source,
        servingCount: servingCount,
      );
      await _syncCurrentWeeklyGroceryList(userId);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Deletes a meal plan.
  @override
  Future<Either<Failure, void>> deleteMealPlan({
    required String userId,
    required String mealPlanId,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.deleteMealPlan(
        userId: userId,
        mealPlanId: mealPlanId,
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // GROCERY LIST - MANAGE
  // =========================================================================

  /// Retrieves detailed information about a grocery list.
  @override
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  ) async {
    try {
      // Delegate to remote data source.
      final detail = await remoteDataSource.getManageGroceryListDetail(listId);
      return Right(detail);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Adds an item to a grocery list.
  @override
  Future<Either<Failure, void>> addGroceryItem(
    AddGroceryItemRequest request,
  ) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.addGroceryItem(request);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Deletes an item from a grocery list.
  @override
  Future<Either<Failure, void>> deleteGroceryItem({
    required String listId,
    required String itemId,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.deleteGroceryItem(listId: listId, itemId: itemId);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Deletes a grocery list.
  @override
  Future<Either<Failure, void>> deleteGroceryList(String listId) async {
    try {
      await remoteDataSource.deleteGroceryList(listId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Updates the bought status of a grocery item.
  @override
  Future<Either<Failure, void>> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.updateGroceryItemBought(
        listId: listId,
        itemId: itemId,
        bought: bought,
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Updates a grocery list's details.
  @override
  Future<Either<Failure, void>> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.updateGroceryList(
        listId: listId,
        name: name,
        startDate: startDate,
        endDate: endDate,
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // WEEKLY GROCERY LIST
  // =========================================================================

  /// Updates the user's week start day preference for weekly grocery lists.
  @override
  Future<Either<Failure, void>> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  }) async {
    try {
      // Delegate to remote data source.
      await remoteDataSource.updateWeeklyGroceryWeekStartDay(
        userId: userId,
        weekStartDay: weekStartDay,
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Fetches weather snapshot for a date, with fallback on failure.
  Future<AddMealWeather> _weatherSnapshotFor(DateTime date) async {
    try {
      // Attempt to fetch weather data.
      final weather = await weatherDataSource.getWeatherForDate(date);
      return AddMealWeather(
        temperature: weather.currentTemp,
        condition: weather.condition,
        summary: weather.summary,
      );
    } catch (_) {
      // Return a default weather object on failure.
      return const AddMealWeather(
        temperature: 0,
        condition: 'Unavailable',
        summary: 'Weather data is unavailable for this request.',
      );
    }
  }

  /// Refreshes the default weekly grocery list after meal-plan changes.
  ///
  /// Meal plans should stay saved even if the derived grocery list cannot be
  /// refreshed because the dashboard also performs this sync best-effort.
  Future<void> _syncCurrentWeeklyGroceryList(String userId) async {
    if (userId.trim().isEmpty) return;

    try {
      await remoteDataSource.ensureCurrentWeeklyGroceryList(userId);
    } catch (_) {
      // Keep the meal-plan save result intact; grocery sync can retry later.
    }
  }
}
