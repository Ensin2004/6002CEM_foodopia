part of 'meal_plan_remote_datasource.dart';

/// Shared query, build, resolution, date, and conversion helpers.
mixin _MealPlanRemoteDataSourceHelpers on _MealPlanRemoteDataSourceCore {
  // =========================================================================
  // PRIVATE QUERY HELPERS
  // =========================================================================

  /// Queries meal plans for a specific category on a given date.
  Future<QuerySnapshot<Map<String, dynamic>>> _plansForCategory({
    required String userId,
    required DateTime date,
    required String mealCategoryId,
  }) {
    // Calculate the end of the day.
    final dayEnd = date.add(const Duration(days: 1));

    // Query meal plans by user, category, and date range.
    return firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('mealCategoryId', isEqualTo: mealCategoryId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .get();
  }

  /// Retrieves meal plans between two dates for a user.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mealPlansBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Query meal plans by user and date range.
    final snapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.docs;
  }

  /// Retrieves multiple meal plan documents by their IDs.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getMealPlanDocs(
    List<String> ids,
  ) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    // Process IDs in chunks of 10 to avoid Firestore limitations.
    for (final chunk in _chunks(ids, 10)) {
      final snapshot = await firestore
          .collection('meal_plans')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      docs.addAll(snapshot.docs);
    }
    return docs;
  }

  // =========================================================================
  // PRIVATE BUILD HELPERS
  // =========================================================================

  /// Builds the sections for the meal plan dashboard.
  Future<List<MealPlanSection>> _buildSections(
    List<AddMealCategoryOption> categories,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) async {
    // Map each category to a section containing its meals.
    return Future.wait(
      categories.map((category) async {
        // Filter plans that match the category.
        final mealDocs = plans.where((doc) {
          final data = doc.data();
          final id = data['mealCategoryId']?.toString() ?? '';
          return id == category.id;
        }).toList();
        final meals = await Future.wait(mealDocs.map(_mealFromDoc));

        // Create a section for the category.
        return MealPlanSection(
          mealType: category.name,
          mealCategoryId: category.id,
          meals: meals,
        );
      }),
    );
  }

  /// Builds grocery meal sections for the grocery list plan screen.
  Future<List<GroceryMealSectionPlan>> _buildGroceryMealSections(
    List<AddMealCategoryOption> categories,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) async {
    // Map each category to a section with its meals.
    final sections = await Future.wait(
      categories.map((category) async {
        // Filter plans that match the category.
        final mealDocs = plans.where((doc) {
          final data = doc.data();
          final id = data['mealCategoryId']?.toString() ?? '';
          return id == category.id;
        }).toList();
        final meals = await Future.wait(
          mealDocs.map((doc) async {
            final display = await _mealDisplayFromPlan(doc);
            return GroceryMealPlanItem(
              id: doc.id,
              title: display.title,
              imagePath: display.imagePath,
            );
          }),
        );

        // Return the section if it has meals.
        return GroceryMealSectionPlan(title: category.name, meals: meals);
      }),
    );
    return sections.where((section) => section.meals.isNotEmpty).toList();
  }

  /// Builds the month days grid for the dashboard calendar.
  List<MealPlanDay> _buildMonthDays(
    DateTime selectedDate,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) {
    // Calculate the first day of the month.
    final firstDay = DateTime(selectedDate.year, selectedDate.month);

    // Calculate leading days (days from previous month).
    final leadingDays = firstDay.weekday - 1;

    // Calculate the start of the grid (Sunday).
    final gridStart = firstDay.subtract(Duration(days: leadingDays));

    // Extract planned dates from meal plans.
    final plannedDays = plans
        .map((doc) {
          final value = doc.data()['date'];
          if (value is! Timestamp) return null;
          final date = value.toDate();
          return DateTime(date.year, date.month, date.day);
        })
        .whereType<DateTime>()
        .toList();

    // Generate 42 days (6 weeks) for the grid.
    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      return MealPlanDay(
        date: date,
        isCurrentMonth: date.month == selectedDate.month,
        hasMeals: plannedDays.any((plannedDate) => _sameDay(plannedDate, date)),
      );
    });
  }

  // =========================================================================
  // PRIVATE GROCERY ITEM BUILDING
  // =========================================================================

  /// Builds grocery items from meal plan documents.
  /// Aggregates ingredients from recipes and AI contexts.
  Future<List<_GroceryItemDraft>> _buildGroceryItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mealDocs,
  ) async {
    // Map to deduplicate items by key.
    final itemsByKey = <String, _GroceryItemDraft>{};
    final categoryNameById = <String, String>{};

    // Process each meal plan.
    for (final mealDoc in mealDocs) {
      final meal = mealDoc.data();
      final recipeId = meal['recipeId']?.toString() ?? '';

      // Prefer saved recipe ingredients because Explore displays those records.
      final recipeIngredientSource = await _recipeIngredientSourceForMeal(
        mealDoc,
        meal,
        recipeId,
      );
      if (recipeIngredientSource != null) {
        final recipeServings =
            _intValue(recipeIngredientSource.recipeData?['servings']) ??
            _intValue(recipeIngredientSource.recipeData?['servingSize']);
        final servingScale = _mealServingScale(meal, recipeServings);
        await _resolveIngredientCategoryNamesFor(
          recipeIngredientSource.ingredientDocs.map((doc) => doc.data()),
          categoryNameById,
        );

        for (final ingredientDoc in recipeIngredientSource.ingredientDocs) {
          final ingredient = ingredientDoc.data();
          final unit = await _resolveIngredientUnitName(
            unitId: ingredient['unitId']?.toString() ?? '',
            customUnitId: ingredient['customUnitId']?.toString() ?? '',
          );

          _mergeGroceryItem(
            itemsByKey,
            _itemFromRecipeIngredient(
              mealDoc.id,
              recipeIngredientSource.recipeId,
              ingredient,
              unit,
              categoryNameById,
              servingScale,
            ),
          );
        }
        continue;
      }

      // Fall back to AI context only when no saved recipe ingredients exist.
      final aiContext = await mealDoc.reference
          .collection('ai_context')
          .doc('context')
          .get();
      if (!aiContext.exists) continue;

      final generated = aiContext.data()?['generatedRecipe'];
      final generatedIngredients = generated is Map<String, dynamic>
          ? generated['ingredients']
          : null;
      await _resolveIngredientCategoryNamesFor(
        generatedIngredients,
        categoryNameById,
      );
      _mergeGroceryItems(
        itemsByKey,
        _itemsFromAiIngredients(
          mealDoc.id,
          recipeId,
          generatedIngredients,
          categoryNameById,
          _mealServingScale(meal, null),
        ),
      );
    }

    // Return sorted items by name.
    return itemsByKey.values.toList()..sort(
      (first, second) => first.ingredientName.compareTo(second.ingredientName),
    );
  }

  /// Finds the saved recipe ingredient documents that match a meal plan.
  Future<_RecipeIngredientSource?> _recipeIngredientSourceForMeal(
    QueryDocumentSnapshot<Map<String, dynamic>> mealDoc,
    Map<String, dynamic> meal,
    String recipeId,
  ) async {
    if (recipeId.isNotEmpty) {
      final direct = await _recipeIngredientSource(recipeId);
      if (direct != null) return direct;
    }

    final generated = await _generatedRecipeFromPlan(mealDoc);
    final title = generated?['title']?.toString().trim() ?? '';
    final userId = meal['uid']?.toString().trim() ?? '';
    if (title.isEmpty || userId.isEmpty) return null;

    final matches = await firestore
        .collection('recipes')
        .where('creatorUid', isEqualTo: userId)
        .where('name', isEqualTo: title)
        .limit(5)
        .get();

    for (final doc in matches.docs) {
      final source = await _recipeIngredientSource(doc.id);
      if (source != null) return source;
    }
    return null;
  }

  /// Loads ingredient documents for a recipe when they are available.
  Future<_RecipeIngredientSource?> _recipeIngredientSource(
    String recipeId,
  ) async {
    final trimmedRecipeId = recipeId.trim();
    if (trimmedRecipeId.isEmpty) return null;

    final recipeRef = firestore.collection('recipes').doc(trimmedRecipeId);
    final recipeDoc = await recipeRef.get();
    if (!recipeDoc.exists) return null;

    final ingredients = await recipeRef.collection('ingredients').get();
    if (ingredients.docs.isEmpty) return null;

    return _RecipeIngredientSource(
      recipeId: recipeDoc.id,
      recipeData: recipeDoc.data(),
      ingredientDocs: ingredients.docs,
    );
  }

  /// Creates grocery item drafts from AI ingredient data.
  Iterable<_GroceryItemDraft> _itemsFromAiIngredients(
    String mealPlanId,
    String recipeId,
    Object? ingredients,
    Map<String, String> categoryNameById,
    double servingScale,
  ) {
    // Return empty if ingredients is not an iterable.
    if (ingredients is! Iterable) return const [];

    // Map each ingredient to a draft item.
    return ingredients.whereType<Map>().map((item) {
      final categoryId = _ingredientCategoryIdFrom(item) ?? '';
      final categoryName = _categoryNameFromIngredientData(
        item,
        categoryId,
        categoryNameById,
      );
      return _GroceryItemDraft(
        ingredientName: item['name']?.toString() ?? 'Ingredient',
        ingredientCategoryId: categoryId,
        categoryName: categoryName.isNotEmpty
            ? categoryName
            : _categoryNameForIngredient(item['name']?.toString() ?? ''),
        imagePath: '',
        amount: _doubleValue(item['amount']) * servingScale,
        unit: item['unit']?.toString() ?? '',
        relatedMealPlanIds: [mealPlanId],
        relatedRecipeIds: recipeId.isEmpty ? const [] : [recipeId],
        sortOrder: _intValue(item['sortOrder']) ?? 0,
      );
    });
  }

  /// Creates a grocery item draft from a recipe ingredient.
  _GroceryItemDraft _itemFromRecipeIngredient(
    String mealPlanId,
    String recipeId,
    Map<String, dynamic> ingredient,
    String unit,
    Map<String, String> categoryNameById,
    double servingScale,
  ) {
    final categoryId = _ingredientCategoryIdFrom(ingredient) ?? '';
    final categoryName = _categoryNameFromIngredientData(
      ingredient,
      categoryId,
      categoryNameById,
    );
    return _GroceryItemDraft(
      ingredientName: ingredient['name']?.toString() ?? 'Ingredient',
      ingredientCategoryId: categoryId,
      categoryName: categoryName.isNotEmpty
          ? categoryName
          : _categoryNameForIngredient(ingredient['name']?.toString() ?? ''),
      imagePath: ingredient['image']?.toString().trim() ?? '',
      amount: _doubleValue(ingredient['amount']) * servingScale,
      unit: unit,
      relatedMealPlanIds: [mealPlanId],
      relatedRecipeIds: recipeId.isEmpty ? const [] : [recipeId],
      sortOrder: _intValue(ingredient['sortOrder']) ?? 0,
    );
  }

  /// Calculates the serving scale between planned servings and recipe servings.
  double _mealServingScale(Map<String, dynamic> meal, int? recipeServings) {
    // Grocery quantities follow the planned serving count when recipe data has a base serving size.

    // Get planned servings or default to 1.
    final plannedServings = _intValue(meal['servings']) ?? 1;

    // Use recipe servings or planned servings as base.
    final baseServings = recipeServings == null || recipeServings <= 0
        ? plannedServings
        : recipeServings;
    if (baseServings <= 0) return 1;

    // Calculate scale factor.
    return plannedServings / baseServings;
  }

  // =========================================================================
  // PRIVATE GROCERY ITEM MERGING
  // =========================================================================

  /// Merges multiple grocery items into a target map.
  void _mergeGroceryItems(
    Map<String, _GroceryItemDraft> target,
    Iterable<_GroceryItemDraft> items,
  ) {
    for (final item in items) {
      _mergeGroceryItem(target, item);
    }
  }

  /// Merges a grocery item into the target map, combining duplicate items.
  void _mergeGroceryItem(
    Map<String, _GroceryItemDraft> target,
    _GroceryItemDraft item,
  ) {
    // Create a unique key for the item.
    final key = [
      item.ingredientName.trim().toLowerCase(),
      item.ingredientCategoryId,
      item.unit.trim().toLowerCase(),
    ].join('|');

    // Merge with existing item or add new one.
    final existing = target[key];
    if (existing == null) {
      target[key] = item;
      return;
    }
    target[key] = existing.merge(item);
  }

  // =========================================================================
  // PRIVATE CATEGORY BUILDING
  // =========================================================================

  /// Builds categorized items for the grocery list detail view.
  List<ManageGroceryCategory> _buildManageCategories(
    List<_GroceryItemRecord> items,
  ) {
    // Group items by category name.
    final grouped = <String, List<ManageGroceryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.categoryName, () => []).add(item.toEntity());
    }

    // Convert groups to category objects and sort by name.
    final categories =
        grouped.entries
            .map(
              (entry) =>
                  ManageGroceryCategory(title: entry.key, items: entry.value),
            )
            .toList()
          ..sort((first, second) => first.title.compareTo(second.title));
    return categories;
  }

  /// Builds the upcoming meals list for the grocery list detail.
  List<ManageUpcomingMeal> _buildUpcomingMeals(
    Map<String, _MealPlanSnapshot> meals,
  ) {
    return meals.values
        .map(
          (meal) => ManageUpcomingMeal(
            title: meal.recipeName,
            mealType: meal.mealType,
            date: meal.date,
            imagePath: meal.recipeImage,
          ),
        )
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
  }

  /// Builds the timeline days for the grocery list detail.
  List<ManageGroceryTimelineDay> _buildTimelineDays(
    List<_GroceryItemRecord> items,
    Map<String, _MealPlanSnapshot> meals,
  ) {
    // Group meals by date.
    final byDay = <DateTime, List<_MealPlanSnapshot>>{};
    for (final meal in meals.values) {
      byDay.putIfAbsent(_dateOnly(meal.date), () => []).add(meal);
    }

    // Sort dates.
    final dates = byDay.keys.toList()..sort();

    // Build timeline days with meals and their ingredients.
    return dates.asMap().entries.map((entry) {
      final date = entry.value;
      return ManageGroceryTimelineDay(
        date: date,
        dayNumber: entry.key + 1,
        meals: (byDay[date] ?? const <_MealPlanSnapshot>[]).map((meal) {
          // Get items related to this meal.
          final mealItems = items
              .where((item) => item.relatedMealPlanIds.contains(meal.id))
              .map((item) => item.toEntity())
              .toList();
          return ManageGroceryTimelineMeal(
            mealPlanId: meal.id,
            title: meal.recipeName,
            mealType: meal.mealType,
            imagePath: meal.recipeImage,
            ingredients: mealItems,
          );
        }).toList(),
      );
    }).toList();
  }

  // =========================================================================
  // PRIVATE RESOLUTION HELPERS
  // =========================================================================

  /// Builds meal snapshots from meal plan documents.
  /// Fetches recipe data for each meal.
  Future<Map<String, _MealPlanSnapshot>> _buildMealSnapshots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mealDocs,
  ) async {
    final snapshots = <String, _MealPlanSnapshot>{};

    // Process each meal plan.
    for (final doc in mealDocs) {
      final data = doc.data();
      final recipeId = data['recipeId']?.toString() ?? '';

      // Fetch recipe if ID exists.
      final recipeDoc = recipeId.isEmpty
          ? null
          : await firestore.collection('recipes').doc(recipeId).get();
      final recipeData = recipeDoc?.data();
      final aiGenerated = await _generatedRecipeFromPlan(doc);

      // Get image from recipe media or fallback.
      final media = _stringList(recipeData?['media']);
      final imageFromMedia = media.isEmpty ? '' : media.first;

      // Resolve meal category name.
      final mealType =
          await _resolveMealCategoryName(
            data['mealCategoryId']?.toString() ?? '',
          ) ??
          data['mealCategoryName']?.toString() ??
          'Meal';

      // Build the snapshot.
      snapshots[doc.id] = _MealPlanSnapshot(
        id: doc.id,
        date: _timestampDate(data['date']) ?? DateTime.now(),
        mealType: mealType,
        recipeId: recipeId,
        recipeName:
            recipeData?['name']?.toString() ??
            aiGenerated?['title']?.toString() ??
            data['recipeName']?.toString() ??
            'Untitled Meal',
        recipeImage: imageFromMedia.isNotEmpty
            ? imageFromMedia
            : aiGenerated?['imagePath']?.toString().trim().isNotEmpty == true
            ? aiGenerated!['imagePath'].toString()
            : data['recipeImage']?.toString() ?? 'assets/images/meal1.png',
      );
    }
    return snapshots;
  }

  /// Resolves a meal category name from its ID.
  Future<String?> _resolveMealCategoryName(String categoryId) async {
    if (categoryId.isEmpty) return null;

    // Fetch category from app configuration.
    final doc = await firestore
        .collection('app_config')
        .doc('meal_categories')
        .collection('items')
        .doc(categoryId)
        .get();

    final data = doc.data();
    final isActive = data?['isActive'] is bool
        ? data!['isActive'] as bool
        : true;
    if (!isActive) return null;

    final name = data?['name']?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }

  /// Resolves a unit name from unit ID or custom unit ID.
  Future<String> _resolveIngredientUnitName({
    required String unitId,
    required String customUnitId,
  }) async {
    // Try standard unit first.
    if (unitId.isNotEmpty) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_units')
          .collection('items')
          .doc(unitId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      return name.isEmpty ? unitId : name;
    }

    // Try custom unit.
    if (customUnitId.isNotEmpty) {
      final doc = await firestore
          .collection('custom')
          .doc('custom_units')
          .collection('items')
          .doc(customUnitId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      return name.isEmpty ? customUnitId : name;
    }

    return '';
  }

  // =========================================================================
  // PRIVATE DATE UTILITIES
  // =========================================================================

  /// Extracts a date (without time) from a Timestamp or returns null.
  DateTime? _timestampDate(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return DateTime(date.year, date.month, date.day);
    }
    return null;
  }

  /// Returns a date without time components.
  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Gets the user's preferred week start day from settings.
  Future<String> _getWeeklyStartDay(String userId) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('grocery')
        .get();
    return _normalizeWeekStartDay(doc.data()?['weekStartDay']?.toString());
  }

  /// Extracts an ingredient category ID from various possible field names.
  String? _ingredientCategoryIdFrom(Map<dynamic, dynamic> data) {
    final values = [
      data['ingredientCategoryId'],
      data['ingredient_categories_id'],
      data['ingredient_category_id'],
      data['ingredientCategoriesId'],
      data['ingredientCategory'],
      data['categoryId'],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// Resolves all ingredient category IDs in a collection of raw ingredient maps.
  Future<void> _resolveIngredientCategoryNamesFor(
    Object? ingredients,
    Map<String, String> target,
  ) async {
    if (ingredients is! Iterable) return;

    final ids = ingredients
        .whereType<Map>()
        .map(_ingredientCategoryIdFrom)
        .whereType<String>()
        .where((id) => id.isNotEmpty && !target.containsKey(id))
        .toSet();
    if (ids.isEmpty) return;

    final entries = await Future.wait(
      ids.map((id) async {
        final doc = await firestore
            .collection('app_config')
            .doc('ingredient_categories')
            .collection('items')
            .doc(id)
            .get();
        final data = doc.data();
        final name = data?['name']?.toString().trim() ?? '';
        return name.isEmpty ? null : MapEntry(id, name);
      }),
    );
    target.addEntries(entries.whereType<MapEntry<String, String>>());
  }

  /// Reads a persisted category name or resolves one from the category ID map.
  String _categoryNameFromIngredientData(
    Map<dynamic, dynamic> data,
    String categoryId,
    Map<String, String> categoryNameById,
  ) {
    final values = [
      data['categoryName'],
      data['ingredientCategoryName'],
      data['ingredient_category_name'],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return categoryNameById[categoryId] ?? '';
  }

  /// Generates a category name based on ingredient name keywords.
  String _categoryNameForIngredient(String ingredientName) {
    final value = ingredientName.toLowerCase();
    if (value.contains('milk') ||
        value.contains('cheese') ||
        value.contains('yogurt') ||
        value.contains('butter') ||
        value.contains('cream')) {
      return 'Dairy';
    }
    if (value.contains('chicken') ||
        value.contains('beef') ||
        value.contains('pork') ||
        value.contains('fish') ||
        value.contains('egg') ||
        value.contains('tofu')) {
      return 'Protein';
    }
    if (value.contains('rice') ||
        value.contains('bread') ||
        value.contains('pasta') ||
        value.contains('noodle') ||
        value.contains('flour')) {
      return 'Grains';
    }
    if (value.contains('apple') ||
        value.contains('banana') ||
        value.contains('orange') ||
        value.contains('berry') ||
        value.contains('fruit')) {
      return 'Fruits';
    }
    if (value.contains('tomato') ||
        value.contains('carrot') ||
        value.contains('onion') ||
        value.contains('lettuce') ||
        value.contains('vegetable')) {
      return 'Vegetables';
    }
    if (value.contains('oil') ||
        value.contains('salt') ||
        value.contains('pepper') ||
        value.contains('sauce') ||
        value.contains('spice')) {
      return 'Pantry';
    }
    return 'Uncategorized';
  }

  /// Normalizes week start day to 'sunday' or 'monday'.
  String _normalizeWeekStartDay(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'sunday' ? 'sunday' : 'monday';
  }

  /// Calculates the start of the week for a given date and week start day.
  DateTime _weekStartFor(DateTime date, String weekStartDay) {
    final normalizedDate = _dateOnly(date);
    final startWeekday = weekStartDay == 'sunday'
        ? DateTime.sunday
        : DateTime.monday;
    final offset = (normalizedDate.weekday - startWeekday) % 7;
    return normalizedDate.subtract(Duration(days: offset));
  }

  /// Stable weekly grocery list document ID for a user and week.
  String _weeklyGroceryListId(String userId, DateTime weekStart) {
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final dateKey =
        '${weekStart.year.toString().padLeft(4, '0')}'
        '${weekStart.month.toString().padLeft(2, '0')}'
        '${weekStart.day.toString().padLeft(2, '0')}';
    return 'weekly_${safeUserId}_$dateKey';
  }

  // =========================================================================
  // PRIVATE UTILITY FUNCTIONS
  // =========================================================================

  /// Generates a stable document ID for a grocery item based on its properties.
  String _groceryItemDocId(_GroceryItemDraft item) {
    final raw = [
      item.ingredientName,
      item.ingredientCategoryId,
      item.unit,
    ].join('_').toLowerCase();

    // Sanitize the string for Firestore document ID.
    final sanitized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (sanitized.isEmpty) return 'ingredient';
    return sanitized.length > 120 ? sanitized.substring(0, 120) : sanitized;
  }

  /// Removes stale generated grocery item state for a normalized grocery list.
  Future<void> _pruneGeneratedGroceryItemState(
    DocumentReference<Map<String, dynamic>> listRef,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mealDocs,
  ) async {
    final currentGeneratedIds = (await _buildGroceryItems(
      mealDocs,
    )).map(_groceryItemDocId).toSet();
    final existingItems = await listRef.collection('items').get();
    final batch = firestore.batch();
    var hasDeletes = false;

    for (final doc in existingItems.docs) {
      final data = doc.data();
      if (data['isManual'] == true) continue;
      if (currentGeneratedIds.contains(doc.id)) continue;
      batch.delete(doc.reference);
      hasDeletes = true;
    }

    if (hasDeletes) await batch.commit();
  }

  /// Splits a list into chunks of a given size.
  List<List<String>> _chunks(List<String> source, int size) {
    final chunks = <List<String>>[];
    for (var index = 0; index < source.length; index += size) {
      chunks.add(source.sublist(index, (index + size).clamp(0, source.length)));
    }
    return chunks;
  }

  /// Converts a query document snapshot to a meal plan meal entity.
  Future<MealPlanMeal> _mealFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final display = await _mealDisplayFromPlan(doc);
    final servings = data['servings'];
    final servingLabel = servings is num
        ? '${servings.toInt()} Serving Pax'
        : data['servingLabel']?.toString() ?? '1 Serving Pax';
    return MealPlanMeal(
      id: doc.id,
      recipeId: data['recipeId']?.toString() ?? '',
      source: data['source']?.toString() ?? '',
      title: display.title,
      servingLabel: servingLabel,
      durationLabel: display.durationLabel,
      imagePath: display.imagePath,
      calories: display.calories,
      aiDescription: display.aiDescription,
      aiIngredients: display.aiIngredients,
      aiInstructions: display.aiInstructions,
    );
  }

  /// Resolves meal display data from the referenced recipe or AI context.
  Future<_MealDisplayData> _mealDisplayFromPlan(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final recipeId = data['recipeId']?.toString() ?? '';
    final source = data['source']?.toString() ?? '';
    final isAiGenerated = source == 'method3_generate_with_ai';
    final aiGenerated = await _generatedRecipeFromPlan(doc);
    final recipeDoc = recipeId.isEmpty || isAiGenerated
        ? null
        : await firestore.collection('recipes').doc(recipeId).get();
    final recipeData = recipeDoc?.data();
    final media = _stringList(recipeData?['media']);

    final title =
        recipeData?['name']?.toString() ??
        aiGenerated?['title']?.toString() ??
        data['recipeName']?.toString() ??
        'Untitled Meal';
    final duration =
        _durationLabelFromRecipe(recipeData) ??
        aiGenerated?['durationLabel']?.toString() ??
        data['durationLabel']?.toString() ??
        'No time set';
    final imagePath = media.isNotEmpty
        ? media.first
        : aiGenerated?['imagePath']?.toString().trim().isNotEmpty == true
        ? aiGenerated!['imagePath'].toString()
        : data['recipeImage']?.toString() ?? 'assets/images/meal1.png';

    final calories = await _mealCaloriesForPlan(
      planData: data,
      recipeId: recipeId,
      recipeData: recipeData,
      aiGenerated: aiGenerated,
    );

    return _MealDisplayData(
      title: title,
      durationLabel: duration,
      imagePath: imagePath,
      calories: calories,
      aiDescription: aiGenerated?['description']?.toString() ?? '',
      aiIngredients: _aiIngredientLabels(aiGenerated?['ingredients']),
      aiInstructions: _stringList(aiGenerated?['instructions']),
    );
  }

  /// Converts AI ingredient maps into compact display labels.
  List<String> _aiIngredientLabels(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) {
          if (item is! Map) return item.toString().trim();
          final name = item['name']?.toString().trim() ?? '';
          final amount = item['amount']?.toString().trim() ?? '';
          final unit = item['unit']?.toString().trim() ?? '';
          final quantity = [
            amount,
            unit,
          ].where((part) => part.isNotEmpty && part != '0').join(' ');
          return [quantity, name].where((part) => part.isNotEmpty).join(' ');
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Resolves planned meal calories from normalized recipe/AI data.
  Future<int> _mealCaloriesForPlan({
    required Map<String, dynamic> planData,
    required String recipeId,
    required Map<String, dynamic>? recipeData,
    required Map<String, dynamic>? aiGenerated,
  }) async {
    final aiCalories = _caloriesFromGeneratedRecipe(aiGenerated);
    if (aiCalories > 0) return aiCalories.round();

    final recipeCalories = await _recipeCalories(recipeId, recipeData);
    if (recipeCalories > 0) {
      final recipeServings =
          _intValue(recipeData?['servings']) ??
          _intValue(recipeData?['servingSize']);
      final servingScale = _mealServingScale(planData, recipeServings);
      return (recipeCalories * servingScale).round();
    }

    final legacyCalories = _intValue(planData['calories']) ?? 0;
    if (legacyCalories <= 0) {
      debugPrint(
        '[MealCalories] Unable to resolve calories for mealPlan '
        'recipeId=$recipeId source=${planData['source']} '
        'hasRecipe=${recipeData != null} hasAi=${aiGenerated != null}',
      );
    }
    return legacyCalories;
  }

  /// Reads calories from several AI context shapes used by saved generations.
  double _caloriesFromGeneratedRecipe(Map<String, dynamic>? generated) {
    if (generated == null) return 0;

    final direct = _doubleValue(generated['calories']);
    if (direct > 0) return direct;

    final nutrition = generated['nutrition'];
    if (nutrition is Map) {
      final nutritionCalories = _nutrientValue(nutrition, const [
        'calories',
        'energy',
      ]);
      if (nutritionCalories > 0) return nutritionCalories;
    }

    final ingredients = generated['ingredients'];
    if (ingredients is! Iterable) return 0;

    var total = 0.0;
    for (final ingredient in ingredients) {
      if (ingredient is! Map) continue;
      final ingredientCalories = _doubleValue(ingredient['calories']);
      if (ingredientCalories > 0) {
        total += ingredientCalories;
        continue;
      }

      final nutrients = ingredient['nutrients'];
      if (nutrients is Map) {
        total += _nutrientValue(nutrients, const ['calories', 'energy']);
      }
    }
    return total;
  }

  /// Reads total recipe calories from totalNutrients or ingredient nutrients.
  Future<double> _recipeCalories(
    String recipeId,
    Map<String, dynamic>? recipeData,
  ) async {
    final totalNutrients = recipeData?['totalNutrients'];
    if (totalNutrients is Map) {
      final total = _nutrientValue(totalNutrients, const [
        'calories',
        'energy',
      ]);
      if (total > 0) return total;
    }

    if (recipeId.isEmpty) return 0;

    try {
      final ingredients = await firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ingredients')
          .get();

      var total = 0.0;
      for (final ingredient in ingredients.docs) {
        final nutrients = ingredient.data()['nutrients'];
        if (nutrients is Map) {
          total += _nutrientValue(nutrients, const ['calories', 'energy']);
        }
      }
      if (total > 0) return total;
    } on FirebaseException catch (error) {
      debugPrint(
        '[MealCalories] Unable to load recipe ingredients for $recipeId: '
        '${error.message ?? error.code}',
      );
    }

    return _doubleValue(recipeData?['calories']);
  }

  /// Loads the generated recipe context for AI-created meal plans.
  Future<Map<String, dynamic>?> _generatedRecipeFromPlan(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final context = await doc.reference
        .collection('ai_context')
        .doc('context')
        .get();
    final generated = context.data()?['generatedRecipe'];
    return generated is Map<String, dynamic> ? generated : null;
  }

  String? _durationLabelFromRecipe(Map<String, dynamic>? recipeData) {
    final minutes = _intValue(recipeData?['preparationTime']);
    if (minutes != null && minutes > 0) return '$minutes mins';
    return null;
  }

  /// Converts a recipe document to an AI recipe entity.
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
      servingLabel:
          '${_intValue(data['servings']) ?? _intValue(data['servingSize']) ?? 1} servings',
      imagePath: media.isEmpty ? 'assets/images/meal1.png' : media.first,
      description:
          data['description']?.toString() ?? 'Recipe from your database.',
      reasons: const [
        'Matched with the selected meal category',
        'Available in the recipe database',
      ],
      calories: _intValue(data['calories']) ?? 0,
      carbohydrates: _doubleValue(data['carbohydrates']),
      fat: _doubleValue(data['fat']),
      protein: _doubleValue(data['protein']),
      categoryName: categories.isEmpty ? 'Recipe' : categories.join(', '),
    );
  }

  /// Compares two dates without time components.
  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// Converts a value to a list of strings.
  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Converts a value to an integer, or returns null.
  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Converts a value to a double, or returns 0.
  double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Reads a nutrient value by trying common key variants case-insensitively.
  double _nutrientValue(Map<dynamic, dynamic> nutrients, List<String> keys) {
    for (final key in keys) {
      for (final entry in nutrients.entries) {
        if (entry.key.toString().toLowerCase() != key.toLowerCase()) continue;
        final parsed = _numberFromNutrient(entry.value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  double? _numberFromNutrient(Object? value) {
    if (value is num) return value.toDouble();
    if (value is Map) {
      for (final key in const ['value', 'amount', 'quantity']) {
        final parsed = _numberFromNutrient(value[key]);
        if (parsed != null) return parsed;
      }
    }
    return double.tryParse(value?.toString() ?? '');
  }

  /// Converts difficulty level to a readable label.
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

// =============================================================================
// PRIVATE DATA CLASSES
// =============================================================================

/// Resolved display data for a normalized meal plan.
class _MealDisplayData {
  final String title;
  final String durationLabel;
  final String imagePath;
  final int calories;
  final String aiDescription;
  final List<String> aiIngredients;
  final List<String> aiInstructions;

  const _MealDisplayData({
    required this.title,
    required this.durationLabel,
    required this.imagePath,
    required this.calories,
    this.aiDescription = '',
    this.aiIngredients = const [],
    this.aiInstructions = const [],
  });
}

/// Draft representation of a grocery item used during aggregation.
class _GroceryItemDraft {
  final String ingredientName;
  final String ingredientCategoryId;
  final String categoryName;
  final String imagePath;
  final double amount;
  final String unit;
  final List<String> relatedMealPlanIds;
  final List<String> relatedRecipeIds;
  final int sortOrder;

  const _GroceryItemDraft({
    required this.ingredientName,
    required this.ingredientCategoryId,
    required this.categoryName,
    this.imagePath = '',
    required this.amount,
    required this.unit,
    required this.relatedMealPlanIds,
    required this.relatedRecipeIds,
    required this.sortOrder,
  });

  /// Merges this draft with another, combining amounts and IDs.
  _GroceryItemDraft merge(_GroceryItemDraft other) {
    return _GroceryItemDraft(
      ingredientName: ingredientName,
      ingredientCategoryId: ingredientCategoryId,
      categoryName: categoryName.isNotEmpty ? categoryName : other.categoryName,
      imagePath: imagePath.isNotEmpty ? imagePath : other.imagePath,
      amount: amount + other.amount,
      unit: unit,
      relatedMealPlanIds: {
        ...relatedMealPlanIds,
        ...other.relatedMealPlanIds,
      }.toList(),
      relatedRecipeIds: {
        ...relatedRecipeIds,
        ...other.relatedRecipeIds,
      }.toList(),
      sortOrder: sortOrder,
    );
  }
}

/// Record representation of a grocery item for display.
class _GroceryItemRecord {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String imagePath;
  final double amount;
  final String unit;
  final List<String> relatedMealPlanIds;
  final bool bought;

  const _GroceryItemRecord({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.imagePath = '',
    required this.amount,
    required this.unit,
    required this.relatedMealPlanIds,
    required this.bought,
  });

  /// Creates a record from a Firestore document.
  factory _GroceryItemRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> categoryNames,
  ) {
    final data = doc.data();
    final categoryId =
        data['ingredientCategoryId']?.toString().trim().isNotEmpty == true
        ? data['ingredientCategoryId'].toString().trim()
        : data['ingredient_categories_id']?.toString().trim().isNotEmpty == true
        ? data['ingredient_categories_id'].toString().trim()
        : data['categoryId']?.toString().trim().isNotEmpty == true
        ? data['categoryId'].toString().trim()
        : '';
    final name =
        data['ingredientName']?.toString() ??
        data['name']?.toString() ??
        'Ingredient';
    return _GroceryItemRecord(
      id: doc.id,
      name: name,
      categoryId: categoryId,
      categoryName:
          categoryNames[categoryId] ??
          data['categoryName']?.toString() ??
          _fallbackCategoryName(name),
      imagePath: data['image']?.toString() ?? '',
      amount: data['amount'] is num ? (data['amount'] as num).toDouble() : 0,
      unit: data['unit']?.toString() ?? '',
      relatedMealPlanIds: _stringListFromValue(
        data['relatedMealPlanIds'] ?? data['mealPlanId'],
      ),
      bought: data['isBought'] == true || data['bought'] == true,
    );
  }

  /// Converts to a grocery item entity.
  ManageGroceryItem toEntity() {
    return ManageGroceryItem(
      id: id,
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      quantityLabel: _displayQuantity(amount, unit),
      emoji: _displayEmoji(name),
      imagePath: imagePath,
      bought: bought,
    );
  }

  static List<String> _stringListFromValue(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? const [] : [text];
  }

  static String _displayQuantity(double amount, String unit) {
    final value = amount == 0
        ? ''
        : amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1);
    return [value, unit].where((part) => part.trim().isNotEmpty).join(' ');
  }

  static String _displayEmoji(String name) {
    final value = name.toLowerCase();
    if (value.contains('milk')) return '\u{1F95B}';
    if (value.contains('cheese')) return '\u{1F9C0}';
    if (value.contains('egg')) return '\u{1F95A}';
    if (value.contains('chicken') ||
        value.contains('meat') ||
        value.contains('beef')) {
      return '\u{1F969}';
    }
    if (value.contains('fish')) return '\u{1F41F}';
    if (value.contains('rice') || value.contains('bread')) return '\u{1F35E}';
    if (value.contains('apple') || value.contains('fruit')) return '\u{1F34E}';
    if (value.contains('banana')) return '\u{1F34C}';
    if (value.contains('tomato')) return '\u{1F345}';
    if (value.contains('carrot')) return '\u{1F955}';
    return '\u{1F96C}';
  }

  static String _fallbackCategoryName(String name) {
    final value = name.toLowerCase();
    if (value.contains('milk') ||
        value.contains('cheese') ||
        value.contains('yogurt') ||
        value.contains('butter')) {
      return 'Dairy';
    }
    if (value.contains('chicken') ||
        value.contains('beef') ||
        value.contains('pork') ||
        value.contains('fish') ||
        value.contains('egg')) {
      return 'Protein';
    }
    if (value.contains('rice') ||
        value.contains('bread') ||
        value.contains('pasta') ||
        value.contains('flour')) {
      return 'Grains';
    }
    if (value.contains('tomato') ||
        value.contains('carrot') ||
        value.contains('onion') ||
        value.contains('lettuce')) {
      return 'Vegetables';
    }
    if (value.contains('apple') ||
        value.contains('banana') ||
        value.contains('orange')) {
      return 'Fruits';
    }
    if (value.contains('oil') ||
        value.contains('salt') ||
        value.contains('pepper') ||
        value.contains('sauce')) {
      return 'Pantry';
    }
    return 'Uncategorized';
  }
}

/// Saved recipe ingredients that should drive grocery category grouping.
class _RecipeIngredientSource {
  final String recipeId;
  final Map<String, dynamic>? recipeData;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> ingredientDocs;

  const _RecipeIngredientSource({
    required this.recipeId,
    required this.recipeData,
    required this.ingredientDocs,
  });
}

/// Snapshot of a meal plan with key details.
class _MealPlanSnapshot {
  final String id;
  final DateTime date;
  final String mealType;
  final String recipeId;
  final String recipeName;
  final String recipeImage;

  const _MealPlanSnapshot({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
    required this.recipeName,
    required this.recipeImage,
  });
}
