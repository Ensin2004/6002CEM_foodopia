import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../features/meal_plan/domain/entities/meal_serving_amount.dart';
import '../../features/statistics/domain/entities/ai_lifestyle_insight.dart';

/// Service that analyzes meal planning patterns and generates lifestyle insights
/// based on user preferences, meal history, and sustainability metrics.
///
/// This service aggregates meal plan data, calculates nutritional scores,
/// and provides recommendations aligned with user dietary preferences.
class AiLifestyleInsightService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const AiLifestyleInsightService({
    required this.auth,
    required this.firestore,
  });

  /// Retrieves lifestyle insight for a specified time period.
  ///
  /// Fetches user preferences, meal plans within the date range,
  /// and generates a comprehensive insight including scores,
  /// nutritional analysis, and actionable recommendations.
  Future<AiLifestyleInsight> getInsight(AiLifestylePeriod period) async {
    final uid = auth.currentUser?.uid ?? ''; // Extract authenticated user identifier
    final range = _rangeFor(period); // Calculate date boundaries for the requested period

    // Return empty insight when no authenticated user exists
    if (uid.isEmpty) {
      return _emptyInsight(period, range, 'No meal preference set');
    }

    final preference = await _loadPreference(uid); // Load dietary preferences from Firestore
    final plans = await _loadMealPlans(uid, range); // Fetch meal plans within date range
    final meals = <AiLifestyleMealSnapshot>[];

    // Build meal snapshots from each plan document
    for (final plan in plans) {
      final meal = await _mealSnapshot(plan);
      if (meal != null) meals.add(meal); // Include only successfully processed meals
    }

    return _buildInsight(
      period: period,
      range: range,
      preference: preference,
      meals: meals,
    );
  }

  /// Loads user dietary preferences from the food_profile document.
  ///
  /// Combines modern 'diets' array with legacy 'diet' field for backward compatibility.
  /// Extracts target calories and calorie unit for nutritional calculations.
  Future<_LifestylePreference> _loadPreference(String uid) async {
    // Retrieve food profile document from user's preferences subcollection
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('food_profile')
        .get();
    final data = doc.data() ?? const <String, dynamic>{};
    final diets = _stringList(data['diets']); // Extract modern dietary preferences array
    final legacyDiet = _stringValue(data['diet']); // Extract legacy single diet value
    // Merge legacy diet into modern array to ensure backward compatibility
    final preferences = [
      ...diets,
      if (legacyDiet.isNotEmpty && !diets.contains(legacyDiet)) legacyDiet,
    ];

    return _LifestylePreference(
      diets: preferences,
      targetCalories: _doubleValue(data['targetCalories']),
      calorieUnit: _stringValue(data['calorieUnit'], fallback: 'kcal'),
    );
  }

  /// Loads meal plan documents for a specific user within the date range.
  ///
  /// Queries Firestore with uid and date range constraints to retrieve
  /// relevant meal plans efficiently.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMealPlans(
      String uid,
      _InsightRange range,
      ) async {
    final snapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: uid) // Filter by user identifier
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start)) // Start date boundary
        .where('date', isLessThan: Timestamp.fromDate(range.endExclusive)) // End date boundary
        .get();
    return snapshot.docs;
  }

  /// Creates a meal snapshot from a meal plan document.
  ///
  /// Merges data from the plan with recipe details, calculates nutritional values
  /// scaled by serving size, and determines sustainability indicators.
  Future<AiLifestyleMealSnapshot?> _mealSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> plan,
      ) async {
    final data = plan.data();
    final recipeId = _stringValue(data['recipeId']);
    final servings = MealServingAmount.normalize(
      _doubleValue(data['servings']),
    );
    final date = _dateValue(data['date']);
    final recipeData = await _recipeData(recipeId); // Attempt to fetch full recipe
    final aiRecipeData = recipeData == null
        ? await _aiRecipeData(plan.reference) // Fallback to AI-generated recipe data
        : null;
    final sourceData = recipeData ?? aiRecipeData; // Prefer authoritative recipe source
    final title = _recipeTitle(
      sourceData,
      fallback: _stringValue(data['name']),
    );
    final baseServings = _doubleValue(
      sourceData?['servings'],
      fallback: 1,
    ).clamp(1, 999).toDouble(); // Clamp serving count to reasonable bounds
    final nutrients = _nutrients(sourceData, data);
    final scale = servings / baseServings; // Calculate serving scale factor

    // Scale nutritional values proportionally to actual serving size
    final calories = _doubleValue(nutrients['calories']) * scale;
    final protein = _doubleValue(nutrients['protein']) * scale;
    final carbs = _doubleValue(nutrients['carbohydrates']) * scale;
    final fat = _doubleValue(nutrients['fat']) * scale;

    // Build text corpus for sustainability keyword analysis
    final text = [
      title,
      _stringValue(sourceData?['description']),
      ..._stringList(sourceData?['tags']),
      ..._stringList(sourceData?['ingredientNames']),
    ].join(' ').toLowerCase();

    return AiLifestyleMealSnapshot(
      title: title.isEmpty ? 'Planned meal' : title,
      date: date,
      servings: servings,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      plantForward: _isPlantForward(text), // Determine plant-forward status via keyword matching
      higherImpact: _isHigherImpact(text), // Determine environmental impact via keyword matching
    );
  }

  /// Fetches recipe data from the main recipes collection.
  ///
  /// Returns null if recipe ID is empty or document doesn't exist.
  Future<Map<String, dynamic>?> _recipeData(String recipeId) async {
    if (recipeId.isEmpty) return null;
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    return doc.data();
  }

  /// Retrieves AI-generated recipe data from the plan's context subcollection.
  ///
  /// This serves as a fallback when no authoritative recipe exists.
  Future<Map<String, dynamic>?> _aiRecipeData(
      DocumentReference<Map<String, dynamic>> planRef,
      ) async {
    final doc = await planRef.collection('ai_context').doc('context').get();
    final data = doc.data();
    final generated = data?['generatedRecipe'];
    if (generated is! Map) return null;
    return {
      ...generated.cast<String, dynamic>(),
      'servings': data?['servings'] ?? generated['servings'],
    };
  }

  /// Builds the complete lifestyle insight from aggregated data.
  ///
  /// Calculates all metrics including scores, nutritional totals,
  /// sustainability indicators, and generates appropriate recommendations.
  AiLifestyleInsight _buildInsight({
    required AiLifestylePeriod period,
    required _InsightRange range,
    required _LifestylePreference preference,
    required List<AiLifestyleMealSnapshot> meals,
  }) {
    // Extract unique planned days from meal dates
    final plannedDays = meals
        .map((meal) => DateTime(meal.date.year, meal.date.month, meal.date.day))
        .toSet()
        .length;
    // Sum nutritional values across all meals
    final totalCalories = meals.fold<double>(
      0,
          (total, meal) => total + meal.calories,
    );
    final targetCalories = preference.targetCalories > 0
        ? preference.targetCalories
        : 2000.0; // Use default target if not specified
    final expectedDays = range.expectedDays;
    final averageCalories = expectedDays <= 0
        ? 0.0
        : totalCalories / expectedDays; // Calculate average daily intake
    final protein = meals.fold<double>(
      0,
          (total, meal) => total + meal.proteinGrams,
    );
    final carbs = meals.fold<double>(
      0,
          (total, meal) => total + meal.carbsGrams,
    );
    final fat = meals.fold<double>(0, (total, meal) => total + meal.fatGrams);
    // Estimate fiber from carbohydrates (assuming 8% fiber ratio)
    final fiber = meals.fold<double>(0, (total, meal) {
      final estimatedFiber = meal.carbsGrams <= 0
          ? 0.0
          : meal.carbsGrams * 0.08;
      return total + estimatedFiber;
    });
    final plantMeals = meals.where((meal) => meal.plantForward).length;
    final higherImpactMeals = meals.where((meal) => meal.higherImpact).length;
    final score = _score(
      mealCount: meals.length,
      plannedDays: plannedDays,
      expectedDays: expectedDays,
      averageCalories: averageCalories,
      targetCalories: targetCalories,
      plantMeals: plantMeals,
      higherImpactMeals: higherImpactMeals,
    );

    return AiLifestyleInsight(
      period: period,
      dateRangeLabel: range.label,
      mealPreferenceLabel: preference.label,
      score: score,
      mealCount: meals.length,
      plannedDays: plannedDays,
      expectedDays: expectedDays,
      totalCalories: totalCalories,
      averageDailyCalories: averageCalories,
      targetCalories: targetCalories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      fiberGrams: fiber,
      plantForwardMeals: plantMeals,
      higherImpactMeals: higherImpactMeals,
      summary: _summary(score, meals.length, preference.label),
      calorieStatus: _calorieStatus(averageCalories, targetCalories),
      nutritionStatus: _nutritionStatus(protein, carbs, fat, meals.length),
      sustainabilityStatus: _sustainabilityStatus(
        plantMeals,
        higherImpactMeals,
        meals.length,
      ),
      recommendations: _recommendations(
        mealCount: meals.length,
        plannedDays: plannedDays,
        expectedDays: expectedDays,
        averageCalories: averageCalories,
        targetCalories: targetCalories,
        protein: protein,
        plantMeals: plantMeals,
        higherImpactMeals: higherImpactMeals,
        preference: preference,
      ),
      meals: meals..sort((left, right) => right.date.compareTo(left.date)), // Sort descending by date
    );
  }

  /// Generates an empty insight when no user or meal data exists.
  ///
  /// Provides default values and guidance for first-time users.
  AiLifestyleInsight _emptyInsight(
      AiLifestylePeriod period,
      _InsightRange range,
      String preferenceLabel,
      ) {
    return AiLifestyleInsight(
      period: period,
      dateRangeLabel: range.label,
      mealPreferenceLabel: preferenceLabel,
      score: 0,
      mealCount: 0,
      plannedDays: 0,
      expectedDays: range.expectedDays,
      totalCalories: 0,
      averageDailyCalories: 0,
      targetCalories: 2000,
      proteinGrams: 0,
      carbsGrams: 0,
      fatGrams: 0,
      fiberGrams: 0,
      plantForwardMeals: 0,
      higherImpactMeals: 0,
      summary:
      'Plan a few meals first so AI can compare your choices with your preferences.',
      calorieStatus: 'No calorie pattern yet',
      nutritionStatus: 'No nutrition pattern yet',
      sustainabilityStatus: 'No sustainability pattern yet',
      recommendations: const [
        'Start with at least three planned meals so the insight can detect calorie, nutrition, and sustainability patterns.',
        'Set meal preferences in Settings to make the recommendations more personal.',
      ],
      meals: const [],
    );
  }

  /// Extracts nutrient data from recipe or meal sources.
  ///
  /// Tries multiple data sources in priority order:
  /// recipe nutrients, generated nutrition, meal nutrients, then fallback fields.
  Map<dynamic, dynamic> _nutrients(
      Map<String, dynamic>? recipeData,
      Map<String, dynamic> mealData,
      ) {
    final recipeNutrients = recipeData?['totalNutrients'];
    if (recipeNutrients is Map) return recipeNutrients; // Prefer structured nutrient data
    final generatedNutrition = recipeData?['nutrition'];
    if (generatedNutrition is Map) return generatedNutrition; // Use AI-generated nutrition
    final mealNutrients = mealData['totalNutrients'];
    if (mealNutrients is Map) return mealNutrients; // Use meal-specific nutrients
    // Fallback to individual nutrient fields
    return {
      'calories': mealData['calories'],
      'protein': mealData['protein'],
      'carbohydrates': mealData['carbohydrates'] ?? mealData['carbs'],
      'fat': mealData['fat'],
      'fiber': mealData['fiber'],
    };
  }

  /// Calculates the date range for the requested period.
  ///
  /// Returns appropriate start/end dates, label, and expected days
  /// for daily, weekly, or monthly periods.
  _InsightRange _rangeFor(AiLifestylePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case AiLifestylePeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        return _InsightRange(
          start: start,
          endExclusive: start.add(const Duration(days: 1)),
          label: DateFormat('d MMM yyyy').format(start),
          expectedDays: 1,
        );
      case AiLifestylePeriod.weekly:
      // Calculate 7-day range ending today
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        final end = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        return _InsightRange(
          start: start,
          endExclusive: end,
          label:
          '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end.subtract(const Duration(days: 1)))}',
          expectedDays: 7,
        );
      case AiLifestylePeriod.monthly:
      // Calculate full month range
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1);
        return _InsightRange(
          start: start,
          endExclusive: end,
          label: DateFormat('MMMM yyyy').format(start),
          expectedDays: end.difference(start).inDays,
        );
    }
  }

  /// Calculates the overall lifestyle score (0-100).
  ///
  /// Weighs three factors: consistency (35%), calorie alignment (35%),
  /// and sustainability (30%) to produce a comprehensive metric.
  int _score({
    required int mealCount,
    required int plannedDays,
    required int expectedDays,
    required double averageCalories,
    required double targetCalories,
    required int plantMeals,
    required int higherImpactMeals,
  }) {
    if (mealCount == 0) return 0; // No score without meal data
    final consistency = expectedDays <= 0 ? 0.0 : plannedDays / expectedDays;
    final calorieRatio = targetCalories <= 0
        ? 0.0
        : averageCalories / targetCalories;
    final calorieScore = 1 - (calorieRatio - 1).abs().clamp(0.0, 1.0); // Penalize deviation from target
    final sustainability = mealCount <= 0
        ? 0.0
        : ((plantMeals + mealCount - higherImpactMeals) / (mealCount * 2))
        .clamp(0.0, 1.0); // Reward plant-forward choices
    return ((consistency * 35) + (calorieScore * 35) + (sustainability * 30))
        .round()
        .clamp(0, 100)
        .toInt();
  }

  /// Generates a human-readable summary based on score and meal count.
  String _summary(int score, int mealCount, String preferenceLabel) {
    if (mealCount == 0) {
      return 'AI needs more planned meals to compare your food pattern with $preferenceLabel.';
    }
    if (score >= 80) {
      return 'Strong alignment with $preferenceLabel. Keep the current planning rhythm and portion choices.';
    }
    if (score >= 55) {
      return 'Good progress, with a few clear chances to improve calorie balance and meal variety.';
    }
    return 'Your plan needs more structure before it fully supports $preferenceLabel.';
  }

  /// Evaluates calorie status relative to target.
  String _calorieStatus(double averageCalories, double targetCalories) {
    if (averageCalories <= 0) return 'No calorie pattern yet';
    final diff = averageCalories - targetCalories;
    if (diff.abs() <= targetCalories * 0.1) {
      return 'Calories are close to target';
    }
    if (diff > 0) return 'Average calories are above target';
    return 'Average calories are below target';
  }

  /// Evaluates nutrition status based on protein distribution.
  String _nutritionStatus(double protein, double carbs, double fat, int meals) {
    if (meals == 0) return 'No nutrition pattern yet';
    final proteinPerMeal = protein / meals;
    if (proteinPerMeal < 15) return 'Protein looks low for planned meals';
    final totalMacros = protein + carbs + fat;
    if (totalMacros <= 0) return 'Nutrition data is incomplete';
    return 'Macros are available for AI review';
  }

  /// Evaluates sustainability status comparing plant-forward and high-impact meals.
  String _sustainabilityStatus(int plantMeals, int highImpactMeals, int meals) {
    if (meals == 0) return 'No sustainability pattern yet';
    if (plantMeals >= highImpactMeals) {
      return 'Plant-forward choices are leading';
    }
    return 'Try more plant-forward swaps this period';
  }

  /// Generates personalized recommendations based on meal patterns.
  ///
  /// Analyzes consistency, calorie alignment, protein intake,
  /// sustainability balance, and preference adherence.
  List<String> _recommendations({
    required int mealCount,
    required int plannedDays,
    required int expectedDays,
    required double averageCalories,
    required double targetCalories,
    required double protein,
    required int plantMeals,
    required int higherImpactMeals,
    required _LifestylePreference preference,
  }) {
    if (mealCount == 0) {
      return const [
        'Plan at least three meals for the selected period so AI can identify your calorie and nutrition pattern.',
        'Add serving sizes carefully for shared plates because small portions can change the calorie result a lot.',
        'Use the grocery list for planned meals to reduce duplicate buying and support lower food waste.',
      ];
    }

    final items = <String>[];

    // Add recommendation if planning consistency is low
    if (plannedDays < expectedDays * 0.6) {
      items.add(
        'Plan meals for more days in advance to make healthy choices easier during busy periods.',
      );
    }
    // Add calorie adjustment recommendation if significantly off target
    if (averageCalories > targetCalories * 1.1) {
      items.add(
        'Reduce one high-calorie meal portion or pair it with a lighter plant-based side.',
      );
    } else if (averageCalories < targetCalories * 0.75) {
      items.add(
        'Your planned calories are quite low; add a balanced snack or fuller serving for energy.',
      );
    }
    // Add protein recommendation if intake is insufficient
    if (protein / mealCount < 15) {
      items.add(
        'Add a reliable protein source such as tofu, eggs, fish, beans, or lean meat to more meals.',
      );
    }
    // Add sustainability swap recommendation if high-impact meals dominate
    if (higherImpactMeals > plantMeals) {
      items.add(
        'Swap one red-meat meal for legumes, tofu, vegetables, or fish to support climate-friendly eating.',
      );
    }
    // Add preference alignment reminder
    if (preference.diets.isNotEmpty) {
      items.add(
        'Keep recipes aligned with ${preference.label} so suggestions stay personal and realistic.',
      );
    }
    // Always include general planning advice
    items.add(
      'Review the next week before shopping; this helps avoid overbuying and supports SDG 12.',
    );
    return items.take(5).toList(growable: false); // Limit to top 5 recommendations
  }

  /// Determines if a meal is plant-forward based on keyword matching.
  bool _isPlantForward(String text) {
    const keywords = [
      'vegetable',
      'vegan',
      'vegetarian',
      'tofu',
      'tempeh',
      'bean',
      'lentil',
      'chickpea',
      'mushroom',
      'salad',
      'plant',
    ];
    return keywords.any(text.contains);
  }

  /// Determines if a meal has higher environmental impact based on keyword matching.
  bool _isHigherImpact(String text) {
    const keywords = ['beef', 'lamb', 'mutton', 'pork', 'bacon', 'steak'];
    return keywords.any(text.contains);
  }

  /// Extracts recipe title from data with fallback.
  String _recipeTitle(Map<String, dynamic>? data, {required String fallback}) {
    return _stringValue(data?['name'], fallback: fallback);
  }

  /// Converts dynamic value to DateTime with fallback.
  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts dynamic value to double with fallback.
  double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Converts dynamic value to trimmed string with fallback.
  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  /// Converts dynamic iterable to list of non-empty strings.
  List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

/// Internal class representing a date range for insights.
///
/// Contains start and end dates, a display label, and the number of days.
class _InsightRange {
  final DateTime start;
  final DateTime endExclusive;
  final String label;
  final int expectedDays;

  const _InsightRange({
    required this.start,
    required this.endExclusive,
    required this.label,
    required this.expectedDays,
  });
}

/// Internal class representing user dietary preferences.
///
/// Stores diet types, target calories, and preferred calorie unit.
class _LifestylePreference {
  final List<String> diets;
  final double targetCalories;
  final String calorieUnit;

  const _LifestylePreference({
    required this.diets,
    required this.targetCalories,
    required this.calorieUnit,
  });

  /// Generates a human-readable label from diet preferences.
  String get label =>
      diets.isEmpty ? 'General healthy eating' : diets.join(', ');
}