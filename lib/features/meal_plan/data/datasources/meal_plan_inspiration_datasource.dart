import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/food_search_service.dart';
import '../../../../core/services/openai_meal_idea_service.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';

/// Data source for meal plan inspiration features.
/// Handles preference loading, ingredient search, AI recipe generation, and plan persistence.
class MealPlanInspirationDataSource {
  final FirebaseFirestore firestore;
  final FoodSearchService foodSearchService;
  final OpenAiMealIdeaService openAiMealIdeaService;

  const MealPlanInspirationDataSource({
    required this.firestore,
    required this.foodSearchService,
    required this.openAiMealIdeaService,
  });

  // ---------------------------------------------------------------------------
  // Preference Options
  // ---------------------------------------------------------------------------

  /// Fetches preference options for a given category from Firestore.
  /// Sorts by [sortOrder] and filters out inactive or empty entries.
  Future<List<MealPlanPreferenceOption>> getPreferenceOptions(
    String categoryId,
  ) async {
    // Retrieve all items under the category document.
    final snapshot = await firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    // Sort by sortOrder field, falling back to 0 if missing or invalid.
    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final firstOrder = first.data()['sortOrder'];
        final secondOrder = second.data()['sortOrder'];
        final left = firstOrder is int ? firstOrder : 0;
        final right = secondOrder is int ? secondOrder : 0;
        return left.compareTo(right);
      });

    // Map documents to option objects, excluding inactive or nameless entries.
    return docs
        .map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : true;
          final name = data['name']?.toString().trim() ?? '';
          if (!isActive || name.isEmpty) return null;

          return MealPlanPreferenceOption(id: doc.id, name: name);
        })
        .whereType<MealPlanPreferenceOption>()
        .toList();
  }

  /// Loads default ingredients from the 'ingredients' category.
  Future<List<MealPlanInspirationIngredient>> getDefaultIngredients() async {
    final options = await getPreferenceOptions('ingredients');
    return options
        .map(
          (item) => MealPlanInspirationIngredient(id: item.id, name: item.name),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Ingredient Search
  // ---------------------------------------------------------------------------

  /// Searches for ingredients by query using the USDA food service.
  /// Wraps results in local entities with a custom flag.
  Future<List<MealPlanInspirationIngredient>> searchIngredients(
    String query,
  ) async {
    final foods = await foodSearchService.searchUsdaFoods(query);
    return foods
        .map(
          (food) => MealPlanInspirationIngredient(
            id: 'usda_${food.fdcId}',
            name: food.name,
            usdaId: food.fdcId,
            isCustom: true,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // AI Meal Generation
  // ---------------------------------------------------------------------------

  /// Delegates AI meal idea generation to the OpenAI service.
  Future<List<AddMealAiRecipe>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  ) {
    return openAiMealIdeaService.generateMealIdeas(request);
  }

  // ---------------------------------------------------------------------------
  // Meal Categories
  // ---------------------------------------------------------------------------

  /// Fetches meal category options from Firestore.
  /// Returns a default fallback list if no categories are configured.
  Future<List<AddMealCategoryOption>> getMealCategories() async {
    final options = await getPreferenceOptions('meal_categories');
    if (options.isEmpty) {
      return const [
        AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
        AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
        AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
        AddMealCategoryOption(id: 'snack', name: 'Snack'),
      ];
    }
    return options
        .map((item) => AddMealCategoryOption(id: item.id, name: item.name))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Save AI Meal Plans
  // ---------------------------------------------------------------------------

  /// Saves AI-generated meal plans to Firestore with batch writes.
  /// Validates daily limit, duplicate recipes, and atomicity.
  Future<void> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) async {
    if (recipes.isEmpty) return;

    // Compute the date boundary for the day.
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Query existing meal plans for the user, category, and date.
    final existing = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('mealCategoryId', isEqualTo: mealCategory.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    // Enforce maximum 5 recipes per category per day.
    if (existing.docs.length + recipes.length > 5) {
      throw StateError(
        'You can add maximum 5 ${mealCategory.name} recipes for this date.',
      );
    }

    // Detect duplicates by recipe ID.
    final existingRecipeIds = existing.docs
        .map((doc) => doc.data()['recipeId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    String? duplicatedRecipe;
    for (final recipe in recipes) {
      if (existingRecipeIds.contains(recipe.id)) {
        duplicatedRecipe = recipe.title;
        break;
      }
    }
    if (duplicatedRecipe != null) {
      throw StateError(
        '$duplicatedRecipe is already added to ${mealCategory.name} for this date.',
      );
    }

    // Prepare batch write for all new recipes and AI context sub-collections.
    final batch = firestore.batch();
    final collection = firestore.collection('meal_plans');
    for (final recipe in recipes) {
      final doc = collection.doc();

      // Set main meal plan document.
      batch.set(doc, {
        'uid': userId,
        'date': Timestamp.fromDate(dayStart),
        'mealCategoryId': mealCategory.id,
        'mealCategoryName': mealCategory.name,
        'recipeId': recipe.id,
        'recipeName': recipe.title,
        'recipeImage': recipe.imagePath,
        'source': 'method3_generate_with_ai',
        'creationMethod': 'method3_generate_with_ai',
        'servings': _servingsFromLabel(recipe.servingLabel),
        'calories': recipe.calories,
        'carbohydrates': recipe.carbohydrates,
        'fat': recipe.fat,
        'protein': recipe.protein,
        'nutritionSource': 'ai',
        'weatherSnapshot': {
          'condition': request.weather.condition,
          'temperature': request.weather.temperature,
          'summary': request.weather.summary,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Set rich AI context sub-document for traceability and future use.
      batch.set(doc.collection('ai_context').doc('context'), {
        'weather': {
          'condition': request.weather.condition,
          'temperature': request.weather.temperature,
          'summary': request.weather.summary,
        },
        'includedIngredients': request.ingredientsToInclude,
        'dietaryPreference': request.preferences.diet,
        'ingredientsToAvoid': request.ingredientsToAvoid,
        'dishPreference': request.dishIncludes.join(', '),
        'dishAvoidance': request.dishAvoids,
        'cookingTime': request.cookingTime,
        'preparationTime': request.cookingTime,
        'difficultyLevel': request.difficultyLevel,
        'difficulty': request.difficulty,
        'servings': request.servingCount,
        'aiPromptSummary': recipe.description,
        'generatedRecipe': {
          'title': recipe.title,
          'description': recipe.description,
          'durationLabel': recipe.durationLabel,
          'difficultyLabel': recipe.difficultyLabel,
          'servingLabel': recipe.servingLabel,
          'calories': recipe.calories,
          'carbohydrates': recipe.carbohydrates,
          'fat': recipe.fat,
          'protein': recipe.protein,
          'nutrition': {
            'calories': recipe.calories,
            'carbohydrates': recipe.carbohydrates,
            'fat': recipe.fat,
            'protein': recipe.protein,
            'source': 'ai',
          },
          'reasons': recipe.reasons,
          'ingredients': recipe.ingredients
              .map(
                (item) => {
                  'name': item.name,
                  'amount': item.amount,
                  'unit': item.unit,
                  'nutrients': {
                    'calories': item.calories,
                    'carbohydrates': item.carbohydrates,
                    'fat': item.fat,
                    'protein': item.protein,
                    'source': 'ai',
                  },
                  'alternatives': item.alternatives,
                },
              )
              .toList(),
          'instructions': recipe.instructions,
          'imagePrompt': recipe.imagePrompt,
        },
      });
    }

    // Commit all writes atomically.
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extracts an integer serving count from a label string.
  /// Defaults to 1 if no digit is found.
  int _servingsFromLabel(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }
}
