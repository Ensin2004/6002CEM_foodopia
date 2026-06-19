part of 'meal_plan_remote_datasource.dart';

/// Grocery-list remote operations for meal planning.
mixin _MealPlanRemoteGroceryDataSource
    on
        _MealPlanRemoteDataSourceCore,
        _MealPlanRemoteDataSourceHelpers,
        _MealPlanRemoteOperationsDataSource {
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
    final days = await Future.wait(
      plansByDate.entries.map((entry) async {
        return GroceryMealDayPlan(
          date: entry.key,
          sections: await _buildGroceryMealSections(categories, entry.value),
        );
      }),
    );
    days.sort((first, second) => first.date.compareTo(second.date));

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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

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
    final stableListId = _weeklyGroceryListId(userId, weekStart);

    // Query for existing weekly grocery lists.
    final existing = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: 'weekly')
        .get()
        .timeout(const Duration(seconds: 8));

    // Keep exactly one active weekly list for the current week.
    final currentWeekDocs = existing.docs.where((doc) {
      final existingStart = _timestampDate(doc.data()['weekStartDate']);
      return existingStart != null && _sameDay(existingStart, weekStart);
    }).toList();

    if (currentWeekDocs.isNotEmpty) {
      final preferredDoc = currentWeekDocs.firstWhere(
        (doc) => doc.id == stableListId,
        orElse: () => currentWeekDocs.first,
      );
      await _retireDuplicateWeeklyLists(
        keepListId: preferredDoc.id,
        weeklyDocs: currentWeekDocs,
      );

      // Sync the chosen list with current meal plans.
      await _syncWeeklyGroceryList(
        listRef: preferredDoc.reference,
        userId: userId,
        weekStartDay: weekStartDay,
        weekStart: weekStart,
        weekEnd: weekEnd,
        isNewList: false,
      );
      return;
    }

    // Create a new weekly grocery list if none exists.
    await _syncWeeklyGroceryList(
      listRef: firestore.collection('grocery_lists').doc(stableListId),
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
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Set createdAt only for new lists.
    if (isNewList) {
      metadata['createdAt'] = FieldValue.serverTimestamp();
    }

    // Set the list metadata.
    batch.set(listRef, metadata, SetOptions(merge: true));

    // Commit the batch write.
    await batch.commit();

    await _pruneGeneratedGroceryItemState(listRef, mealDocs);
  }

  /// Marks duplicate current-week weekly grocery lists as past.
  Future<void> _retireDuplicateWeeklyLists({
    required String keepListId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> weeklyDocs,
  }) async {
    final batch = firestore.batch();
    var hasUpdates = false;

    for (final doc in weeklyDocs) {
      if (doc.id == keepListId) continue;
      if (doc.data()['status'] == 'past') continue;
      batch.update(doc.reference, {
        'status': 'past',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasUpdates = true;
    }

    if (hasUpdates) await batch.commit();
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
        await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              final computed = await _computedGroceryListItems(
                doc.reference,
                data,
              );

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
                itemCount: computed.length,
                startDate: startDate,
                endDate: endDate,
                status: status == 'past' || endDate.isBefore(today)
                    ? GroceryListStatus.past
                    : GroceryListStatus.active,
                type: type,
                weekStartDay: data['weekStartDay']?.toString() ?? 'monday',
                isDefault: type == GroceryListType.weekly,
                categories: const [],
                extraCategoryCount: computed
                    .map((item) => item.categoryName)
                    .toSet()
                    .length,
              );
            }),
          )
          ..sort(
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

    // Build item records dynamically from meal references and saved item state.
    final items = await _computedGroceryListItems(doc.reference, data);

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
      mealCount: upcomingMeals.length,
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
        .set({
          'isBought': bought,
          'boughtAt': bought ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Commit the batch write.
    await batch.commit();

    await _pruneGeneratedGroceryItemState(listRef, mealDocs);
  }

  // =========================================================================
  // GROCERY LIST NORMALIZED ITEM RESOLUTION
  // =========================================================================

  /// Computes generated grocery items from meal references and merges item state.
  Future<List<_GroceryItemRecord>> _computedGroceryListItems(
    DocumentReference<Map<String, dynamic>> listRef,
    Map<String, dynamic> listData,
  ) async {
    final mealPlanIds = _stringList(
      listData['selectedMealPlanIds'] ?? listData['mealPlanIds'],
    );
    final mealDocs = await _getMealPlanDocs(mealPlanIds);
    final generated = await _buildGroceryItems(mealDocs);
    final itemStateSnapshot = await listRef.collection('items').get();
    final stateById = {
      for (final doc in itemStateSnapshot.docs) doc.id: doc.data(),
    };

    final generatedRecords = await Future.wait(
      generated.map((item) async {
        final id = _groceryItemDocId(item);
        final state = stateById[id] ?? const <String, dynamic>{};
        return _groceryRecordFromDraft(
          id: id,
          draft: item,
          bought: state['isBought'] == true || state['bought'] == true,
        );
      }),
    );

    final manualRecords = itemStateSnapshot.docs
        .where((doc) => doc.data()['isManual'] == true)
        .map((doc) => _GroceryItemRecord.fromDoc(doc, const <String, String>{}))
        .toList();

    return [...generatedRecords, ...manualRecords]
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  /// Converts an in-memory generated grocery draft into a display record.
  Future<_GroceryItemRecord> _groceryRecordFromDraft({
    required String id,
    required _GroceryItemDraft draft,
    required bool bought,
  }) async {
    final categoryName = draft.categoryName.trim().isNotEmpty
        ? draft.categoryName
        : await _ingredientCategoryNameById(draft.ingredientCategoryId) ??
              'Uncategorized';
    return _GroceryItemRecord(
      id: id,
      name: draft.ingredientName,
      categoryId: draft.ingredientCategoryId,
      categoryName: categoryName,
      amount: draft.amount,
      unit: draft.unit,
      relatedMealPlanIds: draft.relatedMealPlanIds,
      bought: bought,
    );
  }

  Future<String?> _ingredientCategoryNameById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await firestore
        .collection('app_config')
        .doc('ingredient_categories')
        .collection('items')
        .doc(id)
        .get();
    final data = doc.data();
    final isActive = data?['isActive'] is bool
        ? data!['isActive'] as bool
        : true;
    if (!isActive) return null;

    final name = data?['name']?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }
}
