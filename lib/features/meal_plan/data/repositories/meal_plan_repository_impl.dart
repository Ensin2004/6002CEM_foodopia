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

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanRemoteDataSource remoteDataSource;
  final MealPlanWeatherDataSource weatherDataSource;
  final MealPlanPreferencesDataSource preferencesDataSource;
  final MealPlanInspirationDataSource inspirationDataSource;

  const MealPlanRepositoryImpl({
    required this.remoteDataSource,
    required this.weatherDataSource,
    required this.preferencesDataSource,
    required this.inspirationDataSource,
  });

  @override
  Future<Either<Failure, MealPlanDashboard>> getDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    try {
      final dashboard = await remoteDataSource.getDashboard(
        userId: userId,
        selectedDate: selectedDate,
      );
      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MealPlanWeather>> getWeatherForDate(
    DateTime date,
  ) async {
    try {
      final weather = await weatherDataSource.getWeatherForDate(date);
      return Right(weather);
    } on RangeError catch (e) {
      return Left(NetworkFailure(message: e.message.toString()));
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(
    String uid,
  ) async {
    try {
      final preferences = await preferencesDataSource.getPreferences(uid);
      return Right(preferences);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MealPlanPreferenceOption>>>
  getInspirationPreferenceOptions(String categoryId) async {
    try {
      final options = await inspirationDataSource.getPreferenceOptions(
        categoryId,
      );
      return Right(options);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  getDefaultInspirationIngredients() async {
    try {
      final ingredients = await inspirationDataSource.getDefaultIngredients();
      return Right(ingredients);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MealPlanInspirationIngredient>>>
  searchInspirationIngredients(String query) async {
    try {
      final ingredients = await inspirationDataSource.searchIngredients(query);
      return Right(ingredients);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan(
    String userId,
  ) async {
    try {
      final plan = await remoteDataSource.getAddGroceryListPlan(userId);
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createGroceryList(
    CreateGroceryListRequest request,
  ) async {
    try {
      final listId = await remoteDataSource.createGroceryList(request);
      return Right(listId);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AddMealAiPlan>> getAddMealAiPlan({
    required String userId,
    required String mealType,
  }) async {
    try {
      final preferences = await preferencesDataSource.getPreferences(userId);
      final today = DateTime.now();
      final planningDate = DateTime(today.year, today.month, today.day);
      final ingredients = await inspirationDataSource.getDefaultIngredients();
      final categories = await remoteDataSource.getMealCategories();
      final weather = await _weatherSnapshotFor(planningDate);
      final preferenceSnapshot = AddMealPreferenceSnapshot(
        diet: preferences.diet,
        allergies: preferences.allergies,
        dislikes: preferences.dislikes,
      );
      final topMatches = await remoteDataSource.getRecipeDatabaseMatches(
        userId: userId,
        mealType: mealType,
        keywords: [
          preferences.diet,
          ...preferences.allergies,
          ...preferences.dislikes,
        ],
      );
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
          topMatches: topMatches,
          aiIdeas: const [],
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AddMealCategoryOption>>>
  getMealCategories() async {
    try {
      final categories = await remoteDataSource.getMealCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AddMealAiRecipe>>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  ) async {
    try {
      final ideas = await inspirationDataSource.generateAiMealIdeas(request);
      return Right(ideas);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) async {
    try {
      await inspirationDataSource.saveAiMealPlans(
        userId: userId,
        date: date,
        mealCategory: mealCategory,
        recipes: recipes,
        request: request,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
  }) async {
    try {
      await remoteDataSource.saveRecipeMealPlan(
        userId: userId,
        date: date,
        mealCategory: mealCategory,
        recipe: recipe,
        source: source,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  ) async {
    try {
      final detail = await remoteDataSource.getManageGroceryListDetail(listId);
      return Right(detail);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addGroceryItem(
    AddGroceryItemRequest request,
  ) async {
    try {
      await remoteDataSource.addGroceryItem(request);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroceryItem({
    required String listId,
    required String itemId,
  }) async {
    try {
      await remoteDataSource.deleteGroceryItem(listId: listId, itemId: itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  }) async {
    try {
      await remoteDataSource.updateGroceryItemBought(
        listId: listId,
        itemId: itemId,
        bought: bought,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await remoteDataSource.updateGroceryList(
        listId: listId,
        name: name,
        startDate: startDate,
        endDate: endDate,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  }) async {
    try {
      await remoteDataSource.updateWeeklyGroceryWeekStartDay(
        userId: userId,
        weekStartDay: weekStartDay,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<AddMealWeather> _weatherSnapshotFor(DateTime date) async {
    try {
      final weather = await weatherDataSource.getWeatherForDate(date);
      return AddMealWeather(
        temperature: weather.currentTemp,
        condition: weather.condition,
        summary: weather.summary,
      );
    } catch (_) {
      return const AddMealWeather(
        temperature: 0,
        condition: 'Unavailable',
        summary: 'Weather data is unavailable for this request.',
      );
    }
  }
}
