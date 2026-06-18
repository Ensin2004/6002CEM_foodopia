import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

/// Remote data source implementation for meal planning operations.
/// Handles all Firestore interactions for meal plans, grocery lists,
/// and related recipe data.
class MealPlanRemoteDataSource {
  /// Firestore instance used for all database operations.
  final FirebaseFirestore firestore;

  /// Creates a new instance with the required Firestore reference.
  const MealPlanRemoteDataSource({required this.firestore});

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Retrieves the meal plan dashboard for a specific user and date.
  /// Fetches meal plans, grocery lists, and generates calendar data.
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

    // Start of the month for range queries.
    final monthStart = DateTime(selectedDate.year, selectedDate.month);

    // Start of the next month for range end.
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    // Fetch all available meal categories from app configuration.
    final categories = await getMealCategories();

    // Fetch all meal plans for the current month.
    final monthPlans = await _mealPlansBetween(
      userId: userId,
      start: monthStart,
      end: nextMonth,
    );

    // Filter plans that fall on the selected date.
    final selectedPlans = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), dayStart);
    }).toList();

    // Get today's date without time component for comparison.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Count meal plans from past dates.
    final pastCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isBefore(today);
    }).length;

    // Count meal plans for today.
    final todayCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), today);
    }).length;

    // Count meal plans for future dates.
    final futureCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isAfter(today);
    }).length;

    // Ensure weekly grocery list exists for the user.
    if (userId.trim().isNotEmpty) {
      await ensureCurrentWeeklyGroceryList(userId);
    }

    // Fetch grocery list summaries.
    final groceryLists = await getGroceryListSummaries(userId);

    // Fetch grocery list groups.
    final groceryGroups = await getGroceryGroups(userId);

    // Build and return the complete dashboard object.
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
      groceryLists: groceryLists,
      groceryGroups: groceryGroups,
    );
  }

  // =========================================================================
  // ADD GROCERY LIST PLAN
  // =========================================================================

  /// Retrieves the plan data needed to create a new grocery list.
  /// Fetches meal plans from the last 30 days to the next year.
  Future<AddGroceryListPlan> getAddGroceryListPlan(String userId) async {
    // Get current date without time.
    final now = DateTime.now();

    // Start date: 30 days ago.
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));

    // End date: approximately one year from start.
    final end = start.add(const Duration(days: 395));

    // Fetch meal categories.
    final categories = await getMealCategories();

    // Fetch all meal plans within the date range.
    final plans = await _mealPlansBetween(
      userId: userId,
      start: start,
      end: end,
    );

    // Group plans by date.
    final plansByDate =
    <DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in plans) {
      final value = doc.data()['date'];
      if (value is! Timestamp) continue;
      final date = value.toDate();
      final day = DateTime(date.year, date.month, date.day);
      plansByDate.putIfAbsent(day, () => []).add(doc);
    }

    // Convert grouped plans to grocery meal day plans.
    final days = plansByDate.entries.map((entry) {
      return GroceryMealDayPlan(
        date: entry.key,
        sections: _buildGroceryMealSections(categories, entry.value),
      );
    }).toList()..sort((first, second) => first.date.compareTo(second.date));

    // Return the plan with icon options and meal days.
    return AddGroceryListPlan(
      iconOptions: const [
        GroceryIconOption(id: 'basket', icon: Icons.shopping_basket_outlined),
        GroceryIconOption(id: 'bag', icon: Icons.shopping_bag_outlined),
        GroceryIconOption(id: 'cart', icon: Icons.shopping_cart_outlined),
        GroceryIconOption(id: 'produce', icon: Icons.eco_outlined),
        GroceryIconOption(id: 'drink', icon: Icons.local_drink_outlined),
        GroceryIconOption(id: 'protein', icon: Icons.set_meal_outlined),
        GroceryIconOption(id: 'bakery', icon: Icons.bakery_dining_outlined),
      ],
      mealDays: days,
    );
  }

  // =========================================================================
  // CREATE GROCERY LIST
  // =========================================================================

  /// Creates a new custom grocery list from selected meal plan IDs.
  /// Returns the newly created document ID.
  Future<String> createGroceryList(CreateGroceryListRequest request) async {
    // Validate that at least one meal plan is selected.
    if (request.mealPlanIds.isEmpty) {
      throw StateError('Select at least one planned meal.');
    }

    // Fetch the meal plan documents.
    final mealDocs = await _getMealPlanDocs(request.mealPlanIds);

    // Create a reference for the new grocery list.
    final listRef = firestore.collection('grocery_lists').doc();

    // Build grocery items from the meal plans.
    final items = await _buildGroceryItems(mealDocs);

    // Validate that items were generated.
    if (items.isEmpty) {
      throw StateError('Selected meals do not have saved ingredients yet.');
    }

    // Extract unique category IDs from items.
    final categories = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Start a batch write for atomic operation.
    final batch = firestore.batch();

    // Grocery metadata keeps reference IDs only so display data stays fresh.
    batch.set(listRef, {
      'uid': request.userId,
      'type': 'custom',
      'name': request.title.trim(),
      'iconKey': request.iconId,
      'startDate': Timestamp.fromDate(_dateOnly(request.startDate)),
      'endDate': Timestamp.fromDate(_dateOnly(request.endDate)),
      'excludedDates': request.excludedDays
          .map((date) => Timestamp.fromDate(_dateOnly(date)))
          .toList(),
      'selectedMealPlanIds': request.mealPlanIds,
      'status': _dateOnly(request.endDate).isBefore(_dateOnly(DateTime.now()))
          ? 'past'
          : 'active',
      'totalItems': items.length,
      'totalCategories': categories.length,
      'totalMeals': mealDocs.length,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add all grocery items as subcollections.
    for (final item in items) {
      final itemRef = listRef.collection('items').doc();
      batch.set(itemRef, item.toFirestore());
    }

    // Commit the batch write.
    await batch.commit();
    return listRef.id;
  }

  // =========================================================================
  // WEEKLY GROCERY LIST MANAGEMENT
  // =========================================================================

  /// Ensures the current weekly grocery list exists for the user.
  /// Creates or syncs the list based on the user's week start day setting.
  Future<void> ensureCurrentWeeklyGroceryList(String userId) async {
    // Get the user's preferred week start day.
    final weekStartDay = await _getWeeklyStartDay(userId);

    // Get current date without time.
    final now = DateTime.now();

    // Calculate the start and end of the current week.
    final weekStart = _weekStartFor(now, weekStartDay);
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Query for existing weekly grocery lists.
    final existing = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: 'weekly')
        .get()
        .timeout(const Duration(seconds: 8));

    // Check if a list already exists for the current week.
    for (final doc in existing.docs) {
      final existingStart = _timestampDate(doc.data()['weekStartDate']);
      if (existingStart != null && _sameDay(existingStart, weekStart)) {
        // Sync the existing list with current meal plans.
        await _syncWeeklyGroceryList(
          listRef: doc.reference,
          userId: userId,
          weekStartDay: weekStartDay,
          weekStart: weekStart,
          weekEnd: weekEnd,
          isNewList: false,
        );
        return;
      }
    }

    // Create a new weekly grocery list if none exists.
    await _syncWeeklyGroceryList(
      listRef: firestore.collection('grocery_lists').doc(),
      userId: userId,
      weekStartDay: weekStartDay,
      weekStart: weekStart,
      weekEnd: weekEnd,
      isNewList: true,
    );
  }

  /// Syncs a weekly grocery list with the current week's meal plans.
  /// Adds new items and removes items from meals that are no longer planned.
  Future<void> _syncWeeklyGroceryList({
    required DocumentReference<Map<String, dynamic>> listRef,
    required String userId,
    required String weekStartDay,
    required DateTime weekStart,
    required DateTime weekEnd,
    required bool isNewList,
  }) async {
    // Fetch all meal plans for the week.
    final mealDocs = await _mealPlansBetween(
      userId: userId,
      start: weekStart,
      end: weekEnd.add(const Duration(days: 1)),
    );

    // Build grocery items from the meal plans.
    final items = await _buildGroceryItems(mealDocs);

    // Extract unique category IDs.
    final categoryIds = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Start a batch write.
    final batch = firestore.batch();

    // Prepare metadata for the grocery list.
    final metadata = <String, dynamic>{
      'uid': userId,
      'type': 'weekly',
      'parentListKey': 'weekly_groceries',
      'name': 'Weekly Groceries',
      'iconKey': 'basket',
      'startDate': Timestamp.fromDate(weekStart),
      'endDate': Timestamp.fromDate(weekEnd),
      'weekStartDate': Timestamp.fromDate(weekStart),
      'weekEndDate': Timestamp.fromDate(weekEnd),
      'weekStartDay': weekStartDay,
      'excludedDates': const <Timestamp>[],
      'selectedMealPlanIds': mealDocs.map((doc) => doc.id).toList(),
      'status': weekEnd.isBefore(_dateOnly(DateTime.now())) ? 'past' : 'active',
      'totalItems': items.length,
      'totalCategories': categoryIds.length,
      'totalMeals': mealDocs.length,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Set createdAt only for new lists.
    if (isNewList) {
      metadata['createdAt'] = FieldValue.serverTimestamp();
    }

    // Set the list metadata.
    batch.set(listRef, metadata, SetOptions(merge: true));

    // Get current item IDs for comparison.
    final itemIds = items.map(_groceryItemDocId).toSet();

    // If updating an existing list, remove items no longer needed.
    if (!isNewList) {
      final existingItems = await listRef.collection('items').get();
      for (final doc in existingItems.docs) {
        if (!itemIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }
    }

    // Add or update all grocery items.
    for (final item in items) {
      batch.set(
        listRef.collection('items').doc(_groceryItemDocId(item)),
        isNewList ? item.toFirestore() : item.toFirestoreForSync(),
        SetOptions(merge: true),
      );
    }

    // Commit the batch write.
    await batch.commit();
  }

  /// Updates the user's week start day preference.
  /// Moves existing active weekly lists to past status if they don't match.
  Future<void> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  }) async {
    // Normalize the week start day value.
    final normalized = _normalizeWeekStartDay(weekStartDay);

    // Save the preference in user settings.
    await firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('grocery')
        .set({
      'weekStartDay': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Move any conflicting weekly lists to past status.
    await _moveOtherActiveWeeklyListsToPast(userId, normalized);

    // Ensure the current weekly list exists with the new start day.
    await ensureCurrentWeeklyGroceryList(userId);
  }

  /// Moves active weekly lists that don't match the current week to past status.
  Future<void> _moveOtherActiveWeeklyListsToPast(
      String userId,
      String weekStartDay,
      ) async {
    // Calculate the current week's start date.
    final currentStart = _weekStartFor(DateTime.now(), weekStartDay);

    // Query all active weekly lists for the user.
    final snapshot = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: 'weekly')
        .where('status', isEqualTo: 'active')
        .get();

    // Prepare batch update.
    final batch = firestore.batch();
    var hasUpdates = false;

    // Update any lists that don't match the current week.
    for (final doc in snapshot.docs) {
      final startDate = _timestampDate(doc.data()['weekStartDate']);
      if (startDate == null || _sameDay(startDate, currentStart)) continue;
      batch.update(doc.reference, {
        'status': 'past',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasUpdates = true;
    }

    // Commit updates if any were made.
    if (hasUpdates) await batch.commit();
  }

  // =========================================================================
  // GROCERY LIST QUERIES
  // =========================================================================

  /// Retrieves summaries of all grocery lists for a user.
  /// Returns a sorted list with the most recent first.
  Future<List<GroceryListSummary>> getGroceryListSummaries(
      String userId,
      ) async {
    // Query all grocery lists for the user.
    final snapshot = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .get()
        .timeout(const Duration(seconds: 8));

    // Get today's date without time.
    final today = _dateOnly(DateTime.now());

    // Map each document to a summary object.
    final lists =
    snapshot.docs.map((doc) {
      final data = doc.data();

      // Parse start and end dates.
      final startDate = _timestampDate(data['startDate']) ?? today;
      final endDate = _timestampDate(data['endDate']) ?? startDate;

      // Determine list type.
      final status = data['status']?.toString();
      final type = data['type']?.toString() == 'weekly'
          ? GroceryListType.weekly
          : GroceryListType.custom;

      // Build the summary object.
      return GroceryListSummary(
        id: doc.id,
        title:
        data['name']?.toString() ??
            data['title']?.toString() ??
            'Grocery List',
        itemCount:
        _intValue(data['totalItems']) ??
            _intValue(data['itemCount']) ??
            0,
        startDate: startDate,
        endDate: endDate,
        status: status == 'past' || endDate.isBefore(today)
            ? GroceryListStatus.past
            : GroceryListStatus.active,
        type: type,
        weekStartDay: data['weekStartDay']?.toString() ?? 'monday',
        isDefault: type == GroceryListType.weekly,
        categories: const [],
        extraCategoryCount: _intValue(data['totalCategories']) ?? 0,
      );
    }).toList()..sort(
          (first, second) => second.startDate.compareTo(first.startDate),
    );

    return lists;
  }

  /// Retrieves grocery list groups categorized by their categories.
  Future<List<GroceryListGroup>> getGroceryGroups(String userId) async {
    // Get all grocery lists for the user.
    final lists = await getGroceryListSummaries(userId);

    // Collect all category names from all lists.
    final categoryNames = <String>{};
    for (final list in lists) {
      categoryNames.addAll(list.categories);
    }

    // Return empty if no categories exist.
    if (categoryNames.isEmpty) return const [];

    // Build a group containing all categories.
    return [
      GroceryListGroup(
        title: 'Categories',
        items: categoryNames.toList()..sort(),
      ),
    ];
  }

  // =========================================================================
  // GROCERY LIST DETAIL MANAGEMENT
  // =========================================================================

  /// Retrieves detailed information about a specific grocery list.
  /// Includes items, categories, timeline, and upcoming meals.
  Future<ManageGroceryListDetail> getManageGroceryListDetail(
      String listId,
      ) async {
    // Fetch the grocery list document.
    final doc = await firestore.collection('grocery_lists').doc(listId).get();
    if (!doc.exists) throw StateError('Grocery list not found.');

    // Get the document data.
    final data = doc.data() ?? <String, dynamic>{};

    // Extract meal plan IDs from the list.
    final mealPlanIds = _stringList(
      data['selectedMealPlanIds'] ?? data['mealPlanIds'],
    );

    // Fetch the associated meal plan documents.
    final mealDocs = await _getMealPlanDocs(mealPlanIds);

    // Build meal snapshots from the documents.
    final mealSnapshots = await _buildMealSnapshots(mealDocs);

    // Fetch all items in the grocery list.
    final itemsSnapshot = await doc.reference.collection('items').get();

    // Resolve missing category information for items.
    final categoryOverrides = await _resolveMissingGroceryItemCategories(
      itemsSnapshot,
    );

    // Resolve category names from app configuration.
    final categoryNames = await _resolveIngredientCategoryNames(
      itemsSnapshot,
      categoryOverrides,
    );

    // Build item records from the snapshot data.
    final items =
    itemsSnapshot.docs
        .map(
          (itemDoc) => _GroceryItemRecord.fromDoc(
        itemDoc,
        categoryNames,
        categoryOverrides[itemDoc.id],
      ),
    )
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));

    // Build categorized view of items.
    final categories = _buildManageCategories(items);

    // Build timeline days from items and meals.
    final timelineDays = _buildTimelineDays(items, mealSnapshots);

    // Build upcoming meals list.
    final upcomingMeals = _buildUpcomingMeals(mealSnapshots);

    // Parse start and end dates.
    final startDate = _timestampDate(data['startDate']) ?? DateTime.now();
    final endDate = _timestampDate(data['endDate']) ?? startDate;

    // Return the complete detail object.
    return ManageGroceryListDetail(
      id: doc.id,
      title:
      data['name']?.toString() ??
          data['title']?.toString() ??
          'Grocery List',
      itemCount: items.length,
      mealCount:
      _intValue(data['totalMeals']) ??
          _intValue(data['mealCount']) ??
          upcomingMeals.length,
      categoryCount: categories.length,
      startDate: startDate,
      endDate: endDate,
      upcomingMeals: upcomingMeals,
      categories: categories,
      timelineDays: timelineDays,
    );
  }

  /// Updates the bought status of a grocery list item.
  Future<void> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  }) async {
    // Update the item's bought status and timestamp.
    await firestore
        .collection('grocery_lists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .update({
      'isBought': bought,
      'boughtAt': bought ? FieldValue.serverTimestamp() : null,
    });
  }

  /// Adds a new manual item to a grocery list.
  Future<void> addGroceryItem(AddGroceryItemRequest request) async {
    // Validate the item name.
    final trimmedName = request.name.trim();
    if (trimmedName.isEmpty) throw StateError('Ingredient name is required.');

    // Get reference to the grocery list.
    final listRef = firestore.collection('grocery_lists').doc(request.listId);

    // Verify the list exists.
    final listDoc = await listRef.get();
    if (!listDoc.exists) throw StateError('Grocery list not found.');

    // Create a reference for the new item.
    final itemRef = listRef.collection('items').doc();

    // Use provided category or default to 'Uncategorized'.
    final category = request.categoryName.trim().isEmpty
        ? 'Uncategorized'
        : request.categoryName.trim();

    // Manual items keep category names so no app config entry is required.
    await itemRef.set({
      'ingredientName': trimmedName,
      'ingredientCategoryId': '',
      'categoryName': category,
      'amount': request.amount < 0 ? 0 : request.amount,
      'unit': request.unit.trim(),
      'relatedMealPlanIds': request.relatedMealPlanIds,
      'relatedRecipeIds': const <String>[],
      'isBought': false,
      'boughtAt': null,
      'isManual': true,
      'sortOrder': 9999,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Refresh the list's summary counts.
    await _refreshGroceryListTotals(listRef);
  }

  /// Deletes an item from a grocery list.
  Future<void> deleteGroceryItem({
    required String listId,
    required String itemId,
  }) async {
    // Get references to the list and item.
    final listRef = firestore.collection('grocery_lists').doc(listId);
    final itemRef = listRef.collection('items').doc(itemId);

    // Verify the item exists.
    final itemDoc = await itemRef.get();
    if (!itemDoc.exists) throw StateError('Grocery item not found.');

    // Delete the item.
    await itemRef.delete();

    // Refresh the list's summary counts.
    await _refreshGroceryListTotals(listRef);
  }

  /// Updates the details of a grocery list.
  /// Synchronizes items with the current meal plans for the date range.
  Future<void> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get reference to the list.
    final listRef = firestore.collection('grocery_lists').doc(listId);

    // Verify the list exists.
    final listDoc = await listRef.get();
    if (!listDoc.exists) throw StateError('Grocery list not found.');

    // Get the user ID from the list data.
    final data = listDoc.data() ?? <String, dynamic>{};
    final userId = data['uid']?.toString() ?? '';
    if (userId.isEmpty) throw StateError('Grocery list owner is missing.');

    // Normalize dates to start of day.
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);
    final rangeEnd = normalizedEnd.add(const Duration(days: 1));

    // Fetch meal plans for the date range.
    final mealDocs = await _mealPlansBetween(
      userId: userId,
      start: normalizedStart,
      end: rangeEnd,
    );

    // Build grocery items from the meal plans.
    final items = await _buildGroceryItems(mealDocs);

    // Extract unique category IDs.
    final categoryIds = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Start a batch write.
    final batch = firestore.batch();

    // Update the list metadata.
    batch.set(listRef, {
      'name': name.trim(),
      'startDate': Timestamp.fromDate(normalizedStart),
      'endDate': Timestamp.fromDate(normalizedEnd),
      'selectedMealPlanIds': mealDocs.map((doc) => doc.id).toList(),
      'status': normalizedEnd.isBefore(_dateOnly(DateTime.now()))
          ? 'past'
          : 'active',
      'totalItems': items.length,
      'totalCategories': categoryIds.length,
      'totalMeals': mealDocs.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Remove items that are no longer needed.
    final itemIds = items.map(_groceryItemDocId).toSet();
    final existingItems = await listRef.collection('items').get();
    for (final doc in existingItems.docs) {
      if (!itemIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    // Add or update all items.
    for (final item in items) {
      batch.set(
        listRef.collection('items').doc(_groceryItemDocId(item)),
        item.toFirestoreForSync(),
        SetOptions(merge: true),
      );
    }

    // Commit the batch write.
    await batch.commit();
  }

  // =========================================================================
  // GROCERY LIST UTILITY
  // =========================================================================

  /// Refreshes the summary counters for a grocery list.
  /// Updates total items and categories based on the current items subcollection.
  Future<void> _refreshGroceryListTotals(
      DocumentReference<Map<String, dynamic>> listRef,
      ) async {
    // Summary counters stay aligned with the items subcollection.

    // Fetch all items in the list.
    final items = await listRef.collection('items').get();

    // Count unique categories from items.
    final categories = items.docs
        .map((doc) {
      final data = doc.data();
      final id = data['ingredientCategoryId']?.toString() ?? '';
      if (id.isNotEmpty) return id;
      return data['categoryName']?.toString().trim() ?? 'Uncategorized';
    })
        .where((value) => value.isNotEmpty)
        .toSet();

    // Update the list with new counts.
    await listRef.set({
      'totalItems': items.docs.length,
      'totalCategories': categories.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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
      'mealCategoryName': mealCategory.name,
      'recipeId': recipe.id,
      'recipeName': recipe.title,
      'recipeImage': recipe.imagePath,
      'source': source,
      'creationMethod': source,
      'servings': servingCount.clamp(1, 99),
      'durationLabel': recipe.durationLabel,
      'difficultyLabel': recipe.difficultyLabel,
      'calories': recipe.calories,
      'carbohydrates': recipe.carbohydrates,
      'fat': recipe.fat,
      'protein': recipe.protein,
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
  List<MealPlanSection> _buildSections(
      List<AddMealCategoryOption> categories,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
      ) {
    // Map each category to a section containing its meals.
    return categories.map((category) {
      // Filter plans that match the category.
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

      // Create a section for the category.
      return MealPlanSection(
        mealType: category.name,
        mealCategoryId: category.id,
        meals: meals,
      );
    }).toList();
  }

  /// Builds grocery meal sections for the grocery list plan screen.
  List<GroceryMealSectionPlan> _buildGroceryMealSections(
      List<AddMealCategoryOption> categories,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
      ) {
    // Map each category to a section with its meals.
    return categories
        .map((category) {
      // Filter plans that match the category.
      final meals = plans
          .where((doc) {
        final data = doc.data();
        final id = data['mealCategoryId']?.toString() ?? '';
        final name = data['mealCategoryName']?.toString() ?? '';
        return id == category.id ||
            name.toLowerCase() == category.name.toLowerCase();
      })
          .map((doc) {
        final data = doc.data();
        return GroceryMealPlanItem(
          id: doc.id,
          title: data['recipeName']?.toString() ?? 'Untitled Meal',
          imagePath:
          data['recipeImage']?.toString() ??
              'assets/images/meal1.png',
        );
      })
          .toList();

      // Return the section if it has meals.
      return GroceryMealSectionPlan(title: category.name, meals: meals);
    })
        .where((section) => section.meals.isNotEmpty)
        .toList();
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

    // Process each meal plan.
    for (final mealDoc in mealDocs) {
      final meal = mealDoc.data();
      final recipeId = meal['recipeId']?.toString() ?? '';

      // Try to get AI-generated recipe context.
      final aiContext = await mealDoc.reference
          .collection('ai_context')
          .doc('context')
          .get();

      if (aiContext.exists) {
        // Extract ingredients from AI context.
        final generated = aiContext.data()?['generatedRecipe'];
        final generatedIngredients = generated is Map<String, dynamic>
            ? generated['ingredients']
            : null;
        _mergeGroceryItems(
          itemsByKey,
          _itemsFromAiIngredients(
            mealDoc.id,
            recipeId,
            generatedIngredients,
            _mealServingScale(meal, null),
          ),
        );
        continue;
      }

      // Skip if no recipe ID.
      if (recipeId.isEmpty) continue;

      // Fetch recipe document.
      final recipeDoc = await firestore
          .collection('recipes')
          .doc(recipeId)
          .get();
      final recipeData = recipeDoc.data();

      // Calculate serving scale.
      final recipeServings =
          _intValue(recipeData?['servings']) ??
              _intValue(recipeData?['servingSize']);
      final servingScale = _mealServingScale(meal, recipeServings);

      // Fetch ingredients from recipe.
      final ingredients = await firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ingredients')
          .get();

      // Process each ingredient.
      for (final ingredientDoc in ingredients.docs) {
        final ingredient = ingredientDoc.data();

        // Resolve unit name.
        final unit = await _resolveIngredientUnitName(
          unitId: ingredient['unitId']?.toString() ?? '',
          customUnitId: ingredient['customUnitId']?.toString() ?? '',
        );

        // Add item to the map.
        _mergeGroceryItem(
          itemsByKey,
          _itemFromRecipeIngredient(
            mealDoc.id,
            recipeId,
            ingredient,
            unit,
            servingScale,
          ),
        );
      }
    }

    // Return sorted items by name.
    return itemsByKey.values.toList()..sort(
          (first, second) => first.ingredientName.compareTo(second.ingredientName),
    );
  }

  /// Creates grocery item drafts from AI ingredient data.
  Iterable<_GroceryItemDraft> _itemsFromAiIngredients(
      String mealPlanId,
      String recipeId,
      Object? ingredients,
      double servingScale,
      ) {
    // Return empty if ingredients is not an iterable.
    if (ingredients is! Iterable) return const [];

    // Map each ingredient to a draft item.
    return ingredients.whereType<Map>().map((item) {
      final categoryId = _ingredientCategoryIdFrom(item) ?? '';
      return _GroceryItemDraft(
        ingredientName: item['name']?.toString() ?? 'Ingredient',
        ingredientCategoryId: categoryId,
        categoryName:
        item['categoryName']?.toString().trim() ??
            _categoryNameForIngredient(item['name']?.toString() ?? ''),
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
      double servingScale,
      ) {
    final categoryId = _ingredientCategoryIdFrom(ingredient) ?? '';
    return _GroceryItemDraft(
      ingredientName: ingredient['name']?.toString() ?? 'Ingredient',
      ingredientCategoryId: categoryId,
      categoryName:
      ingredient['categoryName']?.toString().trim() ??
          _categoryNameForIngredient(ingredient['name']?.toString() ?? ''),
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

      // Get image from recipe media or fallback.
      final media = _stringList(recipeData?['media']);
      final imageFromMedia = media.isEmpty ? '' : media.first;

      // Resolve meal category name.
      final mealType = await _resolveMealCategoryName(
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
            data['recipeName']?.toString() ??
            'Untitled Meal',
        recipeImage: imageFromMedia.isNotEmpty
            ? imageFromMedia
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

    final name = doc.data()?['name']?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }

  /// Resolves ingredient category names for a list of items.
  Future<Map<String, String>> _resolveIngredientCategoryNames(
      QuerySnapshot<Map<String, dynamic>> itemsSnapshot,
      Map<String, _ResolvedGroceryCategory> categoryOverrides,
      ) async {
    // Collect all unique category IDs.
    final ids = <String>{};
    for (final doc in itemsSnapshot.docs) {
      final categoryId =
          _ingredientCategoryIdFrom(doc.data()) ??
              categoryOverrides[doc.id]?.id ??
              '';
      if (categoryId.isNotEmpty) ids.add(categoryId);
    }

    // Fetch category names from app configuration.
    final names = <String, String>{};
    for (final id in ids) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_categories')
          .collection('items')
          .doc(id)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      names[id] = name.isEmpty ? 'Uncategorized' : name;
    }
    return names;
  }

  /// Resolves missing grocery item categories by looking at related recipes.
  Future<Map<String, _ResolvedGroceryCategory>>
  _resolveMissingGroceryItemCategories(
      QuerySnapshot<Map<String, dynamic>> itemsSnapshot,
      ) async {
    final overrides = <String, _ResolvedGroceryCategory>{};

    // Process each item.
    for (final itemDoc in itemsSnapshot.docs) {
      final data = itemDoc.data();

      // Skip if category already exists.
      final existingId = _ingredientCategoryIdFrom(data) ?? '';
      final existingName = data['categoryName']?.toString().trim() ?? '';
      if (existingId.isNotEmpty || existingName.isNotEmpty) continue;

      // Get ingredient name and related recipe IDs.
      final ingredientName =
          data['ingredientName']?.toString() ?? data['name']?.toString() ?? '';
      final recipeIds = _stringList(
        data['relatedRecipeIds'] ?? data['recipeIds'] ?? data['recipeId'],
      );

      // Try to resolve category from related recipes.
      final resolved = await _resolveCategoryFromRelatedRecipes(
        ingredientName,
        recipeIds,
      );

      // Use resolved category or fallback to generated category.
      overrides[itemDoc.id] =
          resolved ??
              _ResolvedGroceryCategory(
                id: '',
                name: _categoryNameForIngredient(ingredientName),
              );
    }
    return overrides;
  }

  /// Resolves a category from related recipes by matching ingredient name.
  Future<_ResolvedGroceryCategory?> _resolveCategoryFromRelatedRecipes(
      String ingredientName,
      List<String> recipeIds,
      ) async {
    final normalizedName = ingredientName.trim().toLowerCase();
    if (normalizedName.isEmpty) return null;

    // Check each related recipe.
    for (final recipeId in recipeIds) {
      // Get ingredients from the recipe.
      final snapshot = await firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ingredients')
          .get();

      // Find matching ingredient.
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString().trim().toLowerCase() ?? '';
        if (name != normalizedName) continue;

        // Return the category if found.
        final categoryId = _ingredientCategoryIdFrom(data) ?? '';
        if (categoryId.isNotEmpty) {
          return _ResolvedGroceryCategory(id: categoryId, name: '');
        }
      }
    }
    return null;
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
      data['categoryId'],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
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

  /// Splits a list into chunks of a given size.
  List<List<String>> _chunks(List<String> source, int size) {
    final chunks = <List<String>>[];
    for (var index = 0; index < source.length; index += size) {
      chunks.add(source.sublist(index, (index + size).clamp(0, source.length)));
    }
    return chunks;
  }

  /// Converts a query document snapshot to a meal plan meal entity.
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

/// Draft representation of a grocery item used during aggregation.
class _GroceryItemDraft {
  final String ingredientName;
  final String ingredientCategoryId;
  final String categoryName;
  final double amount;
  final String unit;
  final List<String> relatedMealPlanIds;
  final List<String> relatedRecipeIds;
  final int sortOrder;

  const _GroceryItemDraft({
    required this.ingredientName,
    required this.ingredientCategoryId,
    required this.categoryName,
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

  /// Converts to Firestore document data.
  Map<String, dynamic> toFirestore() {
    return {
      'ingredientName': ingredientName,
      'ingredientCategoryId': ingredientCategoryId,
      'categoryName': categoryName,
      'amount': amount,
      'unit': unit,
      'relatedMealPlanIds': relatedMealPlanIds,
      'relatedRecipeIds': relatedRecipeIds,
      'isBought': false,
      'boughtAt': null,
      'sortOrder': sortOrder,
    };
  }

  /// Converts to Firestore data for sync operations.
  Map<String, dynamic> toFirestoreForSync() {
    return {
      'ingredientName': ingredientName,
      'ingredientCategoryId': ingredientCategoryId,
      'categoryName': categoryName,
      'amount': amount,
      'unit': unit,
      'relatedMealPlanIds': relatedMealPlanIds,
      'relatedRecipeIds': relatedRecipeIds,
      'sortOrder': sortOrder,
    };
  }
}

/// Record representation of a grocery item for display.
class _GroceryItemRecord {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double amount;
  final String unit;
  final List<String> relatedMealPlanIds;
  final bool bought;

  const _GroceryItemRecord({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.unit,
    required this.relatedMealPlanIds,
    required this.bought,
  });

  /// Creates a record from a Firestore document.
  factory _GroceryItemRecord.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, String> categoryNames,
      _ResolvedGroceryCategory? categoryOverride,
      ) {
    final data = doc.data();
    final categoryId =
    data['ingredientCategoryId']?.toString().trim().isNotEmpty == true
        ? data['ingredientCategoryId'].toString().trim()
        : data['ingredient_categories_id']?.toString().trim().isNotEmpty == true
        ? data['ingredient_categories_id'].toString().trim()
        : data['categoryId']?.toString().trim().isNotEmpty == true
        ? data['categoryId'].toString().trim()
        : categoryOverride?.id ?? '';
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
          categoryOverride?.name ??
          data['categoryName']?.toString() ??
          _fallbackCategoryName(name),
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

/// Resolved grocery category with ID and name.
class _ResolvedGroceryCategory {
  final String id;
  final String name;

  const _ResolvedGroceryCategory({required this.id, required this.name});
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