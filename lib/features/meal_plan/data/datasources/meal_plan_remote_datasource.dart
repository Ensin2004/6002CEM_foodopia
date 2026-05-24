import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

class MealPlanRemoteDataSource {
  final FirebaseFirestore firestore;

  const MealPlanRemoteDataSource({required this.firestore});

  Future<MealPlanDashboard> getDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    // Month-level query feeds both the selected date sections and calendar dots.
    final dayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
    final categories = await getMealCategories();
    final monthPlans = await _mealPlansBetween(
      userId: userId,
      start: monthStart,
      end: nextMonth,
    );
    final selectedPlans = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), dayStart);
    }).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isBefore(today);
    }).length;
    final todayCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), today);
    }).length;
    final futureCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isAfter(today);
    }).length;

    return MealPlanDashboard(
      selectedDate: dayStart,
      weather: null,
      summary: MealPlanSummary(
        pastCount: pastCount,
        todayCount: todayCount,
        futureCount: futureCount,
      ),
      monthDays: _buildMonthDays(dayStart, monthPlans),
      sections: _buildSections(categories, selectedPlans),
      inspirations: const [],
      quickInspirations: const [],
      groceryLists: const [],
      groceryGroups: const [],
    );
  }

  Future<List<AddMealCategoryOption>> getMealCategories() async {
    final snapshot = await firestore
        .collection('app_config')
        .doc('meal_categories')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));
    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final left = first.data()['sortOrder'];
        final right = second.data()['sortOrder'];
        return (left is int ? left : 0).compareTo(right is int ? right : 0);
      });
    final categories = docs
        .map((doc) {
          final data = doc.data();
          final name = data['name']?.toString().trim() ?? '';
          final active = data['isActive'] is bool
              ? data['isActive'] as bool
              : true;
          if (!active || name.isEmpty) return null;
          return AddMealCategoryOption(id: doc.id, name: name);
        })
        .whereType<AddMealCategoryOption>()
        .toList();

    if (categories.isNotEmpty) return categories;
    return const [
      AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
      AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
      AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
    ];
  }

  Future<void> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final existing = await _plansForCategory(
      userId: userId,
      date: dayStart,
      mealCategoryId: mealCategory.id,
    );
    final alreadyPlanned = existing.docs.any((doc) {
      return doc.data()['recipeId']?.toString() == recipe.id;
    });
    if (alreadyPlanned) {
      throw StateError(
        '${recipe.title} is already added to ${mealCategory.name} for this date.',
      );
    }
    // Each meal category allows up to five recipes for the same planning date.
    if (existing.docs.length >= 5) {
      throw StateError(
        'You can add maximum 5 ${mealCategory.name} recipes for this date.',
      );
    }

    await firestore.collection('meal_plans').add({
      'uid': userId,
      'date': Timestamp.fromDate(dayStart),
      'mealCategoryId': mealCategory.id,
      'mealCategoryName': mealCategory.name,
      'recipeId': recipe.id,
      'recipeName': recipe.title,
      'recipeImage': recipe.imagePath,
      'source': source,
      'creationMethod': source,
      'servings': _servingsFromLabel(recipe.servingLabel),
      'durationLabel': recipe.durationLabel,
      'difficultyLabel': recipe.difficultyLabel,
      'calories': recipe.calories,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AddMealAiRecipe>> getRecipeDatabaseMatches({
    required String userId,
    required String mealType,
    List<String> keywords = const [],
  }) async {
    final snapshot = await firestore
        .collection('recipes')
        .limit(50)
        .get()
        .timeout(const Duration(seconds: 8));
    final terms = {
      mealType.toLowerCase(),
      ...keywords.map((item) => item.toLowerCase()),
    }.where((item) => item.trim().isNotEmpty).toList();
    final matches = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final haystack = [
            data['name'],
            data['recipeName'],
            data['description'],
            ..._stringList(data['categories']),
            ..._stringList(data['categoryIds']),
          ].join(' ').toLowerCase();
          if (terms.isEmpty) return true;
          return terms.any(haystack.contains);
        })
        .map(_aiRecipeFromRecipeDoc)
        .toList();

    return matches.take(8).toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _plansForCategory({
    required String userId,
    required DateTime date,
    required String mealCategoryId,
  }) {
    final dayEnd = date.add(const Duration(days: 1));
    return firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('mealCategoryId', isEqualTo: mealCategoryId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .get();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mealPlansBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.docs;
  }

  List<MealPlanSection> _buildSections(
    List<AddMealCategoryOption> categories,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) {
    return categories.map((category) {
      final meals = plans
          .where((doc) {
            final data = doc.data();
            final id = data['mealCategoryId']?.toString() ?? '';
            final name = data['mealCategoryName']?.toString() ?? '';
            return id == category.id ||
                name.toLowerCase() == category.name.toLowerCase();
          })
          .map(_mealFromDoc)
          .toList();
      return MealPlanSection(
        mealType: category.name,
        mealCategoryId: category.id,
        meals: meals,
      );
    }).toList();
  }

  MealPlanMeal _mealFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final servings = data['servings'];
    final servingLabel = servings is num
        ? '${servings.toInt()} Serving Pax'
        : data['servingLabel']?.toString() ?? '1 Serving Pax';
    return MealPlanMeal(
      id: doc.id,
      recipeId: data['recipeId']?.toString() ?? '',
      source: data['source']?.toString() ?? '',
      title: data['recipeName']?.toString() ?? 'Untitled Meal',
      servingLabel: servingLabel,
      durationLabel: data['durationLabel']?.toString() ?? 'No time set',
      imagePath: data['recipeImage']?.toString() ?? 'assets/images/meal1.png',
    );
  }

  AddMealAiRecipe _aiRecipeFromRecipeDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final media = _stringList(data['media']);
    final categories = _stringList(data['categories']).isNotEmpty
        ? _stringList(data['categories'])
        : _stringList(data['categoryIds']);
    return AddMealAiRecipe(
      id: doc.id,
      title:
          data['name']?.toString() ??
          data['recipeName']?.toString() ??
          'Untitled Recipe',
      durationLabel: '${_intValue(data['preparationTime']) ?? 0} mins',
      difficultyLabel: _difficultyLabel(_intValue(data['difficultyLevel'])),
      servingLabel: '${_intValue(data['servingSize']) ?? 1} servings',
      imagePath: media.isEmpty ? 'assets/images/meal1.png' : media.first,
      description:
          data['description']?.toString() ?? 'Recipe from your database.',
      reasons: const [
        'Matched with the selected meal category',
        'Available in the recipe database',
      ],
      calories: _intValue(data['calories']) ?? 0,
      categoryName: categories.isEmpty ? 'Recipe' : categories.join(', '),
    );
  }

  List<MealPlanDay> _buildMonthDays(
    DateTime selectedDate,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final leadingDays = firstDay.weekday - 1;
    final gridStart = firstDay.subtract(Duration(days: leadingDays));
    final plannedDays = plans
        .map((doc) {
          final value = doc.data()['date'];
          if (value is! Timestamp) return null;
          final date = value.toDate();
          return DateTime(date.year, date.month, date.day);
        })
        .whereType<DateTime>()
        .toList();

    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      return MealPlanDay(
        date: date,
        isCurrentMonth: date.month == selectedDate.month,
        hasMeals: plannedDays.any((plannedDate) => _sameDay(plannedDate, date)),
      );
    });
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  int _servingsFromLabel(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _difficultyLabel(int? level) {
    switch (level) {
      case 1:
        return 'Novice';
      case 2:
        return 'Beginner';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Master';
      default:
        return 'Easy';
    }
  }
}
