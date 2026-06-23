import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../features/meal_plan/domain/entities/meal_serving_amount.dart';
import '../../features/statistics/domain/entities/ai_lifestyle_insight.dart';

class AiLifestyleInsightService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const AiLifestyleInsightService({
    required this.auth,
    required this.firestore,
  });

  Future<AiLifestyleInsight> getInsight(AiLifestylePeriod period) async {
    final uid = auth.currentUser?.uid ?? '';
    final range = _rangeFor(period);
    if (uid.isEmpty) {
      return _emptyInsight(period, range, 'No meal preference set');
    }

    final preference = await _loadPreference(uid);
    final plans = await _loadMealPlans(uid, range);
    final meals = <AiLifestyleMealSnapshot>[];

    for (final plan in plans) {
      final meal = await _mealSnapshot(plan);
      if (meal != null) meals.add(meal);
    }

    return _buildInsight(
      period: period,
      range: range,
      preference: preference,
      meals: meals,
    );
  }

  Future<_LifestylePreference> _loadPreference(String uid) async {
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('food_profile')
        .get();
    final data = doc.data() ?? const <String, dynamic>{};
    final diets = _stringList(data['diets']);
    final legacyDiet = _stringValue(data['diet']);
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMealPlans(
    String uid,
    _InsightRange range,
  ) async {
    final snapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThan: Timestamp.fromDate(range.endExclusive))
        .get();
    return snapshot.docs;
  }

  Future<AiLifestyleMealSnapshot?> _mealSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> plan,
  ) async {
    final data = plan.data();
    final recipeId = _stringValue(data['recipeId']);
    final servings = MealServingAmount.normalize(
      _doubleValue(data['servings']),
    );
    final date = _dateValue(data['date']);
    final recipeData = await _recipeData(recipeId);
    final aiRecipeData = recipeData == null
        ? await _aiRecipeData(plan.reference)
        : null;
    final sourceData = recipeData ?? aiRecipeData;
    final title = _recipeTitle(
      sourceData,
      fallback: _stringValue(data['name']),
    );
    final baseServings = _doubleValue(
      sourceData?['servings'],
      fallback: 1,
    ).clamp(1, 999).toDouble();
    final nutrients = _nutrients(sourceData, data);
    final scale = servings / baseServings;

    final calories = _doubleValue(nutrients['calories']) * scale;
    final protein = _doubleValue(nutrients['protein']) * scale;
    final carbs = _doubleValue(nutrients['carbohydrates']) * scale;
    final fat = _doubleValue(nutrients['fat']) * scale;
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
      plantForward: _isPlantForward(text),
      higherImpact: _isHigherImpact(text),
    );
  }

  Future<Map<String, dynamic>?> _recipeData(String recipeId) async {
    if (recipeId.isEmpty) return null;
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    return doc.data();
  }

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

  AiLifestyleInsight _buildInsight({
    required AiLifestylePeriod period,
    required _InsightRange range,
    required _LifestylePreference preference,
    required List<AiLifestyleMealSnapshot> meals,
  }) {
    final plannedDays = meals
        .map((meal) => DateTime(meal.date.year, meal.date.month, meal.date.day))
        .toSet()
        .length;
    final totalCalories = meals.fold<double>(
      0,
      (total, meal) => total + meal.calories,
    );
    final targetCalories = preference.targetCalories > 0
        ? preference.targetCalories
        : 2000.0;
    final expectedDays = range.expectedDays;
    final averageCalories = expectedDays <= 0
        ? 0.0
        : totalCalories / expectedDays;
    final protein = meals.fold<double>(
      0,
      (total, meal) => total + meal.proteinGrams,
    );
    final carbs = meals.fold<double>(
      0,
      (total, meal) => total + meal.carbsGrams,
    );
    final fat = meals.fold<double>(0, (total, meal) => total + meal.fatGrams);
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
      meals: meals..sort((left, right) => right.date.compareTo(left.date)),
    );
  }

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

  Map<dynamic, dynamic> _nutrients(
    Map<String, dynamic>? recipeData,
    Map<String, dynamic> mealData,
  ) {
    final recipeNutrients = recipeData?['totalNutrients'];
    if (recipeNutrients is Map) return recipeNutrients;
    final generatedNutrition = recipeData?['nutrition'];
    if (generatedNutrition is Map) return generatedNutrition;
    final mealNutrients = mealData['totalNutrients'];
    if (mealNutrients is Map) return mealNutrients;
    return {
      'calories': mealData['calories'],
      'protein': mealData['protein'],
      'carbohydrates': mealData['carbohydrates'] ?? mealData['carbs'],
      'fat': mealData['fat'],
      'fiber': mealData['fiber'],
    };
  }

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

  int _score({
    required int mealCount,
    required int plannedDays,
    required int expectedDays,
    required double averageCalories,
    required double targetCalories,
    required int plantMeals,
    required int higherImpactMeals,
  }) {
    if (mealCount == 0) return 0;
    final consistency = expectedDays <= 0 ? 0.0 : plannedDays / expectedDays;
    final calorieRatio = targetCalories <= 0
        ? 0.0
        : averageCalories / targetCalories;
    final calorieScore = 1 - (calorieRatio - 1).abs().clamp(0.0, 1.0);
    final sustainability = mealCount <= 0
        ? 0.0
        : ((plantMeals + mealCount - higherImpactMeals) / (mealCount * 2))
              .clamp(0.0, 1.0);
    return ((consistency * 35) + (calorieScore * 35) + (sustainability * 30))
        .round()
        .clamp(0, 100)
        .toInt();
  }

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

  String _calorieStatus(double averageCalories, double targetCalories) {
    if (averageCalories <= 0) return 'No calorie pattern yet';
    final diff = averageCalories - targetCalories;
    if (diff.abs() <= targetCalories * 0.1) {
      return 'Calories are close to target';
    }
    if (diff > 0) return 'Average calories are above target';
    return 'Average calories are below target';
  }

  String _nutritionStatus(double protein, double carbs, double fat, int meals) {
    if (meals == 0) return 'No nutrition pattern yet';
    final proteinPerMeal = protein / meals;
    if (proteinPerMeal < 15) return 'Protein looks low for planned meals';
    final totalMacros = protein + carbs + fat;
    if (totalMacros <= 0) return 'Nutrition data is incomplete';
    return 'Macros are available for AI review';
  }

  String _sustainabilityStatus(int plantMeals, int highImpactMeals, int meals) {
    if (meals == 0) return 'No sustainability pattern yet';
    if (plantMeals >= highImpactMeals) {
      return 'Plant-forward choices are leading';
    }
    return 'Try more plant-forward swaps this period';
  }

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
    if (plannedDays < expectedDays * 0.6) {
      items.add(
        'Plan meals for more days in advance to make healthy choices easier during busy periods.',
      );
    }
    if (averageCalories > targetCalories * 1.1) {
      items.add(
        'Reduce one high-calorie meal portion or pair it with a lighter plant-based side.',
      );
    } else if (averageCalories < targetCalories * 0.75) {
      items.add(
        'Your planned calories are quite low; add a balanced snack or fuller serving for energy.',
      );
    }
    if (protein / mealCount < 15) {
      items.add(
        'Add a reliable protein source such as tofu, eggs, fish, beans, or lean meat to more meals.',
      );
    }
    if (higherImpactMeals > plantMeals) {
      items.add(
        'Swap one red-meat meal for legumes, tofu, vegetables, or fish to support climate-friendly eating.',
      );
    }
    if (preference.diets.isNotEmpty) {
      items.add(
        'Keep recipes aligned with ${preference.label} so suggestions stay personal and realistic.',
      );
    }
    items.add(
      'Review the next week before shopping; this helps avoid overbuying and supports SDG 12.',
    );
    return items.take(5).toList(growable: false);
  }

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

  bool _isHigherImpact(String text) {
    const keywords = ['beef', 'lamb', 'mutton', 'pork', 'bacon', 'steak'];
    return keywords.any(text.contains);
  }

  String _recipeTitle(Map<String, dynamic>? data, {required String fallback}) {
    return _stringValue(data?['name'], fallback: fallback);
  }

  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

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

class _LifestylePreference {
  final List<String> diets;
  final double targetCalories;
  final String calorieUnit;

  const _LifestylePreference({
    required this.diets,
    required this.targetCalories,
    required this.calorieUnit,
  });

  String get label =>
      diets.isEmpty ? 'General healthy eating' : diets.join(', ');
}
