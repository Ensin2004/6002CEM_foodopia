import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/openai_meal_idea_service.dart';
import '../../../../core/services/food_search_service.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';

class MealPlanInspirationDataSource {
  final FirebaseFirestore firestore;
  final FoodSearchService foodSearchService;
  final OpenAiMealIdeaService openAiMealIdeaService;

  const MealPlanInspirationDataSource({
    required this.firestore,
    required this.foodSearchService,
    required this.openAiMealIdeaService,
  });

  Future<List<MealPlanPreferenceOption>> getPreferenceOptions(
    String categoryId,
  ) async {
    final snapshot = await firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final firstOrder = first.data()['sortOrder'];
        final secondOrder = second.data()['sortOrder'];
        final left = firstOrder is int ? firstOrder : 0;
        final right = secondOrder is int ? secondOrder : 0;
        return left.compareTo(right);
      });

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

  Future<List<MealPlanInspirationIngredient>> getDefaultIngredients() async {
    try {
      final options = await getPreferenceOptions('ingredients');
      if (options.isNotEmpty) {
        return options
            .map(
              (item) =>
                  MealPlanInspirationIngredient(id: item.id, name: item.name),
            )
            .toList();
      }
    } catch (_) {
      // Fallback keeps the inspiration tab usable while admin defaults are empty.
    }

    return const [
      MealPlanInspirationIngredient(id: 'eggs', name: 'Eggs'),
      MealPlanInspirationIngredient(id: 'chicken', name: 'Chicken'),
      MealPlanInspirationIngredient(id: 'oats', name: 'Oats'),
      MealPlanInspirationIngredient(id: 'spinach', name: 'Spinach'),
      MealPlanInspirationIngredient(id: 'rice', name: 'Rice'),
      MealPlanInspirationIngredient(id: 'tomato', name: 'Tomato'),
    ];
  }

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

  Future<List<AddMealAiRecipe>> generateAiMealIdeas(
    AddMealAiGenerationRequest request,
  ) {
    return openAiMealIdeaService.generateMealIdeas(request);
  }

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

  Future<void> saveAiMealPlans({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) async {
    if (recipes.isEmpty) return;

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final existing = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('mealCategoryId', isEqualTo: mealCategory.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    if (existing.docs.length + recipes.length > 5) {
      throw StateError(
        'You can add maximum 5 ${mealCategory.name} recipes for this date.',
      );
    }

    final batch = firestore.batch();
    final collection = firestore.collection('meal_plans');
    for (final recipe in recipes) {
      final doc = collection.doc();
      batch.set(doc, {
        'uid': userId,
        'date': Timestamp.fromDate(dayStart),
        'mealCategoryId': mealCategory.id,
        'mealCategoryName': mealCategory.name,
        'recipeId': recipe.id,
        'recipeName': recipe.title,
        'recipeImage': recipe.imagePath,
        'source': 'ai_generated',
        'servings': _servingsFromLabel(recipe.servingLabel),
        'calories': recipe.calories,
        'weatherSnapshot': {
          'condition': request.weather.condition,
          'temperature': request.weather.temperature,
          'summary': request.weather.summary,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
        'difficulty': request.difficulty,
        'aiPromptSummary': recipe.description,
        'generatedRecipe': {
          'title': recipe.title,
          'description': recipe.description,
          'durationLabel': recipe.durationLabel,
          'difficultyLabel': recipe.difficultyLabel,
          'servingLabel': recipe.servingLabel,
          'reasons': recipe.reasons,
          'ingredients': recipe.ingredients
              .map(
                (item) => {
                  'name': item.name,
                  'amount': item.amount,
                  'unit': item.unit,
                },
              )
              .toList(),
          'instructions': recipe.instructions,
          'imagePrompt': recipe.imagePrompt,
        },
      });
    }
    await batch.commit();
  }

  int _servingsFromLabel(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }
}
