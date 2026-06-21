part of 'meal_plan_remote_datasource.dart';

/// Meal-category, meal-plan, and recipe-search remote operations.
mixin _MealPlanRemoteOperationsDataSource
    on _MealPlanRemoteDataSourceCore, _MealPlanRemoteDataSourceHelpers {
  // =========================================================================
  // MEAL CATEGORIES
  // =========================================================================

  /// Retrieves all meal categories from app configuration.
  /// Returns a list of category options sorted by sort order.
  Future<List<AddMealCategoryOption>> getMealCategories() async {
    // Fetch categories from app configuration.
    final snapshot = await firestore
        .collection('app_config')
        .doc('meal_categories')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    // Sort by sort order.
    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final left = first.data()['sortOrder'];
        final right = second.data()['sortOrder'];
        return (left is int ? left : 0).compareTo(right is int ? right : 0);
      });

    // Map to category options, filtering inactive or unnamed categories.
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

    // Return categories or fallback defaults.
    if (categories.isNotEmpty) return categories;
    return const [
      AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
      AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
      AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
    ];
  }

  // =========================================================================
  // MEAL PLAN CRUD
  // =========================================================================

  /// Saves a recipe as a meal plan for a specific date and category.
  /// Throws if the recipe is already planned or category has 5+ recipes.
  Future<void> saveRecipeMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
    required int servingCount,
  }) async {
    // Normalize the date to start of day.
    final dayStart = DateTime(date.year, date.month, date.day);

    // Check for existing plans in the same category on this date.
    final existing = await _plansForCategory(
      userId: userId,
      date: dayStart,
      mealCategoryId: mealCategory.id,
    );

    // Prevent duplicate recipe in the same category on the same date.
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

    // Save the meal plan document.
    await firestore.collection('meal_plans').add({
      'uid': userId,
      'date': Timestamp.fromDate(dayStart),
      'mealCategoryId': mealCategory.id,
      'recipeId': recipe.id,
      'source': source,
      'creationMethod': source,
      'servings': servingCount.clamp(1, 99),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a meal plan and removes it from any grocery lists.
  /// Verifies ownership before deletion.
  Future<void> deleteMealPlan({
    required String userId,
    required String mealPlanId,
  }) async {
    // Ownership validation prevents deleting another user's planned meal.

    // Fetch the meal plan document.
    final mealRef = firestore.collection('meal_plans').doc(mealPlanId);
    final mealDoc = await mealRef.get();

    // Verify the meal plan exists.
    if (!mealDoc.exists) throw StateError('Meal plan not found.');

    // Verify the user owns the meal plan.
    final ownerId = mealDoc.data()?['uid']?.toString() ?? '';
    if (ownerId != userId) throw StateError('Meal plan access denied.');

    // Find grocery lists that contain this meal plan.
    final listsSnapshot = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('selectedMealPlanIds', arrayContains: mealPlanId)
        .get();

    // Start a batch write.
    final batch = firestore.batch();

    // Delete the meal plan.
    batch.delete(mealRef);

    // Remove the meal plan ID from all grocery lists.
    for (final listDoc in listsSnapshot.docs) {
      batch.update(listDoc.reference, {
        'selectedMealPlanIds': FieldValue.arrayRemove([mealPlanId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit the batch write.
    await batch.commit();

    // Remove stale generated grocery item state from affected lists.
    for (final listDoc in listsSnapshot.docs) {
      final remainingIds = _stringList(
        listDoc.data()['selectedMealPlanIds'],
      ).where((id) => id != mealPlanId).toList();
      final remainingMealDocs = await _getMealPlanDocs(remainingIds);
      await _pruneGeneratedGroceryItemState(
        listDoc.reference,
        remainingMealDocs,
      );
    }
  }

  // =========================================================================
  // RECIPE SEARCH
  // =========================================================================

  /// Searches for recipes matching a meal type and keywords.
  /// Returns up to 8 matching recipes from the database.
  Future<List<AddMealAiRecipe>> getRecipeDatabaseMatches({
    required String userId,
    required String mealType,
    List<String> keywords = const [],
  }) async {
    // Fetch up to 50 recipes from the database.
    final snapshot = await firestore
        .collection('recipes')
        .limit(50)
        .get()
        .timeout(const Duration(seconds: 8));

    // Build search terms from meal type and keywords.
    final terms = {
      mealType.toLowerCase(),
      ...keywords.map((item) => item.toLowerCase()),
    }.where((item) => item.trim().isNotEmpty).toList();

    // Filter recipes by search terms.
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

    // Return up to 8 matches.
    return matches.take(8).toList();
  }
}
