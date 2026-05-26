import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
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

    if (userId.trim().isNotEmpty) {
      await ensureCurrentWeeklyGroceryList(userId);
    }
    final groceryLists = await getGroceryListSummaries(userId);
    final groceryGroups = await getGroceryGroups(userId);

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

  Future<AddGroceryListPlan> getAddGroceryListPlan(String userId) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
    final end = start.add(const Duration(days: 395));
    final categories = await getMealCategories();
    final plans = await _mealPlansBetween(
      userId: userId,
      start: start,
      end: end,
    );
    final plansByDate =
        <DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in plans) {
      final value = doc.data()['date'];
      if (value is! Timestamp) continue;
      final date = value.toDate();
      final day = DateTime(date.year, date.month, date.day);
      plansByDate.putIfAbsent(day, () => []).add(doc);
    }

    final days = plansByDate.entries.map((entry) {
      return GroceryMealDayPlan(
        date: entry.key,
        sections: _buildGroceryMealSections(categories, entry.value),
      );
    }).toList()..sort((first, second) => first.date.compareTo(second.date));

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

  Future<String> createGroceryList(CreateGroceryListRequest request) async {
    if (request.mealPlanIds.isEmpty) {
      throw StateError('Select at least one planned meal.');
    }

    final mealDocs = await _getMealPlanDocs(request.mealPlanIds);
    final listRef = firestore.collection('grocery_lists').doc();
    final items = await _buildGroceryItems(mealDocs);
    if (items.isEmpty) {
      throw StateError('Selected meals do not have saved ingredients yet.');
    }
    final categories = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();
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

    for (final item in items) {
      final itemRef = listRef.collection('items').doc();
      batch.set(itemRef, item.toFirestore());
    }

    await batch.commit();
    return listRef.id;
  }

  Future<void> ensureCurrentWeeklyGroceryList(String userId) async {
    final weekStartDay = await _getWeeklyStartDay(userId);
    final now = DateTime.now();
    final weekStart = _weekStartFor(now, weekStartDay);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final existing = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: 'weekly')
        .get()
        .timeout(const Duration(seconds: 8));
    for (final doc in existing.docs) {
      final existingStart = _timestampDate(doc.data()['weekStartDate']);
      if (existingStart != null && _sameDay(existingStart, weekStart)) {
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

    await _syncWeeklyGroceryList(
      listRef: firestore.collection('grocery_lists').doc(),
      userId: userId,
      weekStartDay: weekStartDay,
      weekStart: weekStart,
      weekEnd: weekEnd,
      isNewList: true,
    );
  }

  Future<void> _syncWeeklyGroceryList({
    required DocumentReference<Map<String, dynamic>> listRef,
    required String userId,
    required String weekStartDay,
    required DateTime weekStart,
    required DateTime weekEnd,
    required bool isNewList,
  }) async {
    final mealDocs = await _mealPlansBetween(
      userId: userId,
      start: weekStart,
      end: weekEnd.add(const Duration(days: 1)),
    );
    final items = await _buildGroceryItems(mealDocs);
    final categoryIds = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final batch = firestore.batch();

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
    if (isNewList) {
      metadata['createdAt'] = FieldValue.serverTimestamp();
    }
    batch.set(listRef, metadata, SetOptions(merge: true));

    final itemIds = items.map(_groceryItemDocId).toSet();
    if (!isNewList) {
      final existingItems = await listRef.collection('items').get();
      for (final doc in existingItems.docs) {
        if (!itemIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }
    }

    for (final item in items) {
      batch.set(
        listRef.collection('items').doc(_groceryItemDocId(item)),
        isNewList ? item.toFirestore() : item.toFirestoreForSync(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> updateWeeklyGroceryWeekStartDay({
    required String userId,
    required String weekStartDay,
  }) async {
    final normalized = _normalizeWeekStartDay(weekStartDay);
    await firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('grocery')
        .set({
          'weekStartDay': normalized,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _moveOtherActiveWeeklyListsToPast(userId, normalized);
    await ensureCurrentWeeklyGroceryList(userId);
  }

  Future<void> _moveOtherActiveWeeklyListsToPast(
    String userId,
    String weekStartDay,
  ) async {
    final currentStart = _weekStartFor(DateTime.now(), weekStartDay);
    final snapshot = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: 'weekly')
        .where('status', isEqualTo: 'active')
        .get();
    final batch = firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      final startDate = _timestampDate(doc.data()['weekStartDate']);
      if (startDate == null || _sameDay(startDate, currentStart)) continue;
      batch.update(doc.reference, {
        'status': 'past',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasUpdates = true;
    }
    if (hasUpdates) await batch.commit();
  }

  Future<List<GroceryListSummary>> getGroceryListSummaries(
    String userId,
  ) async {
    final snapshot = await firestore
        .collection('grocery_lists')
        .where('uid', isEqualTo: userId)
        .get()
        .timeout(const Duration(seconds: 8));
    final today = _dateOnly(DateTime.now());
    final lists =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final startDate = _timestampDate(data['startDate']) ?? today;
          final endDate = _timestampDate(data['endDate']) ?? startDate;
          final status = data['status']?.toString();
          final type = data['type']?.toString() == 'weekly'
              ? GroceryListType.weekly
              : GroceryListType.custom;
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

  Future<List<GroceryListGroup>> getGroceryGroups(String userId) async {
    final lists = await getGroceryListSummaries(userId);
    final categoryNames = <String>{};
    for (final list in lists) {
      categoryNames.addAll(list.categories);
    }
    if (categoryNames.isEmpty) return const [];
    return [
      GroceryListGroup(
        title: 'Categories',
        items: categoryNames.toList()..sort(),
      ),
    ];
  }

  Future<ManageGroceryListDetail> getManageGroceryListDetail(
    String listId,
  ) async {
    final doc = await firestore.collection('grocery_lists').doc(listId).get();
    if (!doc.exists) throw StateError('Grocery list not found.');

    final data = doc.data() ?? <String, dynamic>{};
    final mealPlanIds = _stringList(
      data['selectedMealPlanIds'] ?? data['mealPlanIds'],
    );
    final mealDocs = await _getMealPlanDocs(mealPlanIds);
    final mealSnapshots = await _buildMealSnapshots(mealDocs);
    final itemsSnapshot = await doc.reference.collection('items').get();
    final categoryNames = await _resolveIngredientCategoryNames(itemsSnapshot);
    final items =
        itemsSnapshot.docs
            .map(
              (itemDoc) => _GroceryItemRecord.fromDoc(itemDoc, categoryNames),
            )
            .toList()
          ..sort((first, second) => first.name.compareTo(second.name));
    final categories = _buildManageCategories(items);
    final timelineDays = _buildTimelineDays(items, mealSnapshots);
    final upcomingMeals = _buildUpcomingMeals(mealSnapshots);
    final startDate = _timestampDate(data['startDate']) ?? DateTime.now();
    final endDate = _timestampDate(data['endDate']) ?? startDate;

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

  Future<void> updateGroceryItemBought({
    required String listId,
    required String itemId,
    required bool bought,
  }) async {
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

  Future<void> addGroceryItem(AddGroceryItemRequest request) async {
    final trimmedName = request.name.trim();
    if (trimmedName.isEmpty) throw StateError('Ingredient name is required.');

    final listRef = firestore.collection('grocery_lists').doc(request.listId);
    final listDoc = await listRef.get();
    if (!listDoc.exists) throw StateError('Grocery list not found.');

    final itemRef = listRef.collection('items').doc();
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
    await _refreshGroceryListTotals(listRef);
  }

  Future<void> deleteGroceryItem({
    required String listId,
    required String itemId,
  }) async {
    final listRef = firestore.collection('grocery_lists').doc(listId);
    final itemRef = listRef.collection('items').doc(itemId);
    final itemDoc = await itemRef.get();
    if (!itemDoc.exists) throw StateError('Grocery item not found.');

    await itemRef.delete();
    await _refreshGroceryListTotals(listRef);
  }

  Future<void> updateGroceryList({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final listRef = firestore.collection('grocery_lists').doc(listId);
    final listDoc = await listRef.get();
    if (!listDoc.exists) throw StateError('Grocery list not found.');

    final data = listDoc.data() ?? <String, dynamic>{};
    final userId = data['uid']?.toString() ?? '';
    if (userId.isEmpty) throw StateError('Grocery list owner is missing.');

    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);
    final rangeEnd = normalizedEnd.add(const Duration(days: 1));
    final mealDocs = await _mealPlansBetween(
      userId: userId,
      start: normalizedStart,
      end: rangeEnd,
    );
    final items = await _buildGroceryItems(mealDocs);
    final categoryIds = items
        .map((item) => item.ingredientCategoryId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final batch = firestore.batch();

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

    final itemIds = items.map(_groceryItemDocId).toSet();
    final existingItems = await listRef.collection('items').get();
    for (final doc in existingItems.docs) {
      if (!itemIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    for (final item in items) {
      batch.set(
        listRef.collection('items').doc(_groceryItemDocId(item)),
        item.toFirestoreForSync(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> _refreshGroceryListTotals(
    DocumentReference<Map<String, dynamic>> listRef,
  ) async {
    // Summary counters stay aligned with the items subcollection.
    final items = await listRef.collection('items').get();
    final categories = items.docs
        .map((doc) {
          final data = doc.data();
          final id = data['ingredientCategoryId']?.toString() ?? '';
          if (id.isNotEmpty) return id;
          return data['categoryName']?.toString().trim() ?? 'Uncategorized';
        })
        .where((value) => value.isNotEmpty)
        .toSet();

    await listRef.set({
      'totalItems': items.docs.length,
      'totalCategories': categories.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      'carbohydrates': recipe.carbohydrates,
      'fat': recipe.fat,
      'protein': recipe.protein,
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

  List<GroceryMealSectionPlan> _buildGroceryMealSections(
    List<AddMealCategoryOption> categories,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  ) {
    return categories
        .map((category) {
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
          return GroceryMealSectionPlan(title: category.name, meals: meals);
        })
        .where((section) => section.meals.isNotEmpty)
        .toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getMealPlanDocs(
    List<String> ids,
  ) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final chunk in _chunks(ids, 10)) {
      final snapshot = await firestore
          .collection('meal_plans')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      docs.addAll(snapshot.docs);
    }
    return docs;
  }

  Future<List<_GroceryItemDraft>> _buildGroceryItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mealDocs,
  ) async {
    final itemsByKey = <String, _GroceryItemDraft>{};
    for (final mealDoc in mealDocs) {
      final meal = mealDoc.data();
      final recipeId = meal['recipeId']?.toString() ?? '';
      final aiContext = await mealDoc.reference
          .collection('ai_context')
          .doc('context')
          .get();
      if (aiContext.exists) {
        final generated = aiContext.data()?['generatedRecipe'];
        final generatedIngredients = generated is Map<String, dynamic>
            ? generated['ingredients']
            : null;
        _mergeGroceryItems(
          itemsByKey,
          _itemsFromAiIngredients(mealDoc.id, recipeId, generatedIngredients),
        );
        continue;
      }
      if (recipeId.isEmpty) continue;
      final ingredients = await firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('ingredients')
          .get();
      for (final ingredientDoc in ingredients.docs) {
        final ingredient = ingredientDoc.data();
        final unit = await _resolveIngredientUnitName(
          unitId: ingredient['unitId']?.toString() ?? '',
          customUnitId: ingredient['customUnitId']?.toString() ?? '',
        );
        _mergeGroceryItem(
          itemsByKey,
          _itemFromRecipeIngredient(mealDoc.id, recipeId, ingredient, unit),
        );
      }
    }
    return itemsByKey.values.toList()..sort(
      (first, second) => first.ingredientName.compareTo(second.ingredientName),
    );
  }

  Iterable<_GroceryItemDraft> _itemsFromAiIngredients(
    String mealPlanId,
    String recipeId,
    Object? ingredients,
  ) {
    if (ingredients is! Iterable) return const [];
    return ingredients.whereType<Map>().map((item) {
      return _GroceryItemDraft(
        ingredientName: item['name']?.toString() ?? 'Ingredient',
        ingredientCategoryId: item['categoryId']?.toString() ?? '',
        amount: _doubleValue(item['amount']),
        unit: item['unit']?.toString() ?? '',
        relatedMealPlanIds: [mealPlanId],
        relatedRecipeIds: recipeId.isEmpty ? const [] : [recipeId],
        sortOrder: _intValue(item['sortOrder']) ?? 0,
      );
    });
  }

  _GroceryItemDraft _itemFromRecipeIngredient(
    String mealPlanId,
    String recipeId,
    Map<String, dynamic> ingredient,
    String unit,
  ) {
    return _GroceryItemDraft(
      ingredientName: ingredient['name']?.toString() ?? 'Ingredient',
      ingredientCategoryId: ingredient['categoryId']?.toString() ?? '',
      amount: _doubleValue(ingredient['amount']),
      unit: unit,
      relatedMealPlanIds: [mealPlanId],
      relatedRecipeIds: recipeId.isEmpty ? const [] : [recipeId],
      sortOrder: _intValue(ingredient['sortOrder']) ?? 0,
    );
  }

  void _mergeGroceryItems(
    Map<String, _GroceryItemDraft> target,
    Iterable<_GroceryItemDraft> items,
  ) {
    for (final item in items) {
      _mergeGroceryItem(target, item);
    }
  }

  void _mergeGroceryItem(
    Map<String, _GroceryItemDraft> target,
    _GroceryItemDraft item,
  ) {
    final key = [
      item.ingredientName.trim().toLowerCase(),
      item.ingredientCategoryId,
      item.unit.trim().toLowerCase(),
    ].join('|');
    final existing = target[key];
    if (existing == null) {
      target[key] = item;
      return;
    }
    target[key] = existing.merge(item);
  }

  List<ManageGroceryCategory> _buildManageCategories(
    List<_GroceryItemRecord> items,
  ) {
    final grouped = <String, List<ManageGroceryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.categoryName, () => []).add(item.toEntity());
    }
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

  List<ManageGroceryTimelineDay> _buildTimelineDays(
    List<_GroceryItemRecord> items,
    Map<String, _MealPlanSnapshot> meals,
  ) {
    final byDay = <DateTime, List<_MealPlanSnapshot>>{};
    for (final meal in meals.values) {
      byDay.putIfAbsent(_dateOnly(meal.date), () => []).add(meal);
    }
    final dates = byDay.keys.toList()..sort();
    return dates.asMap().entries.map((entry) {
      final date = entry.value;
      return ManageGroceryTimelineDay(
        date: date,
        dayNumber: entry.key + 1,
        meals: (byDay[date] ?? const <_MealPlanSnapshot>[]).map((meal) {
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

  Future<Map<String, _MealPlanSnapshot>> _buildMealSnapshots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mealDocs,
  ) async {
    final snapshots = <String, _MealPlanSnapshot>{};
    for (final doc in mealDocs) {
      final data = doc.data();
      final recipeId = data['recipeId']?.toString() ?? '';
      final recipeDoc = recipeId.isEmpty
          ? null
          : await firestore.collection('recipes').doc(recipeId).get();
      final recipeData = recipeDoc?.data();
      final media = _stringList(recipeData?['media']);
      final imageFromMedia = media.isEmpty ? '' : media.first;
      snapshots[doc.id] = _MealPlanSnapshot(
        id: doc.id,
        date: _timestampDate(data['date']) ?? DateTime.now(),
        mealType:
            await _resolveMealCategoryName(
              data['mealCategoryId']?.toString() ?? '',
            ) ??
            data['mealCategoryName']?.toString() ??
            'Meal',
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

  Future<String?> _resolveMealCategoryName(String categoryId) async {
    if (categoryId.isEmpty) return null;
    final doc = await firestore
        .collection('app_config')
        .doc('meal_categories')
        .collection('items')
        .doc(categoryId)
        .get();
    final name = doc.data()?['name']?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }

  Future<Map<String, String>> _resolveIngredientCategoryNames(
    QuerySnapshot<Map<String, dynamic>> itemsSnapshot,
  ) async {
    final ids = itemsSnapshot.docs
        .map((doc) => doc.data()['ingredientCategoryId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
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

  Future<String> _resolveIngredientUnitName({
    required String unitId,
    required String customUnitId,
  }) async {
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

  DateTime? _timestampDate(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return DateTime(date.year, date.month, date.day);
    }
    return null;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<String> _getWeeklyStartDay(String userId) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('grocery')
        .get();
    return _normalizeWeekStartDay(doc.data()?['weekStartDay']?.toString());
  }

  String _normalizeWeekStartDay(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'sunday' ? 'sunday' : 'monday';
  }

  DateTime _weekStartFor(DateTime date, String weekStartDay) {
    final normalizedDate = _dateOnly(date);
    final startWeekday = weekStartDay == 'sunday'
        ? DateTime.sunday
        : DateTime.monday;
    final offset = (normalizedDate.weekday - startWeekday) % 7;
    return normalizedDate.subtract(Duration(days: offset));
  }

  String _groceryItemDocId(_GroceryItemDraft item) {
    final raw = [
      item.ingredientName,
      item.ingredientCategoryId,
      item.unit,
    ].join('_').toLowerCase();
    final sanitized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) return 'ingredient';
    return sanitized.length > 120 ? sanitized.substring(0, 120) : sanitized;
  }

  List<List<String>> _chunks(List<String> source, int size) {
    final chunks = <List<String>>[];
    for (var index = 0; index < source.length; index += size) {
      chunks.add(source.sublist(index, (index + size).clamp(0, source.length)));
    }
    return chunks;
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
      carbohydrates: _doubleValue(data['carbohydrates']),
      fat: _doubleValue(data['fat']),
      protein: _doubleValue(data['protein']),
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

  double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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

class _GroceryItemDraft {
  final String ingredientName;
  final String ingredientCategoryId;
  final double amount;
  final String unit;
  final List<String> relatedMealPlanIds;
  final List<String> relatedRecipeIds;
  final int sortOrder;

  const _GroceryItemDraft({
    required this.ingredientName,
    required this.ingredientCategoryId,
    required this.amount,
    required this.unit,
    required this.relatedMealPlanIds,
    required this.relatedRecipeIds,
    required this.sortOrder,
  });

  _GroceryItemDraft merge(_GroceryItemDraft other) {
    return _GroceryItemDraft(
      ingredientName: ingredientName,
      ingredientCategoryId: ingredientCategoryId,
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

  Map<String, dynamic> toFirestore() {
    return {
      'ingredientName': ingredientName,
      'ingredientCategoryId': ingredientCategoryId,
      'amount': amount,
      'unit': unit,
      'relatedMealPlanIds': relatedMealPlanIds,
      'relatedRecipeIds': relatedRecipeIds,
      'isBought': false,
      'boughtAt': null,
      'sortOrder': sortOrder,
    };
  }

  Map<String, dynamic> toFirestoreForSync() {
    return {
      'ingredientName': ingredientName,
      'ingredientCategoryId': ingredientCategoryId,
      'amount': amount,
      'unit': unit,
      'relatedMealPlanIds': relatedMealPlanIds,
      'relatedRecipeIds': relatedRecipeIds,
      'sortOrder': sortOrder,
    };
  }
}

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

  factory _GroceryItemRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> categoryNames,
  ) {
    final data = doc.data();
    final categoryId = data['ingredientCategoryId']?.toString() ?? '';
    return _GroceryItemRecord(
      id: doc.id,
      name:
          data['ingredientName']?.toString() ??
          data['name']?.toString() ??
          'Ingredient',
      categoryId: categoryId,
      categoryName:
          categoryNames[categoryId] ??
          data['categoryName']?.toString() ??
          'Uncategorized',
      amount: data['amount'] is num ? (data['amount'] as num).toDouble() : 0,
      unit: data['unit']?.toString() ?? '',
      relatedMealPlanIds: _stringListFromValue(
        data['relatedMealPlanIds'] ?? data['mealPlanId'],
      ),
      bought: data['isBought'] == true || data['bought'] == true,
    );
  }

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
}

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
