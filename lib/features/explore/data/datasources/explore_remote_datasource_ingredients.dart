part of 'explore_remote_datasource.dart';

/// Extension handling ingredient and instruction-related data retrieval.
///
/// Contains methods for fetching and processing ingredient data including
/// nutrient information, unit resolution, category mapping, and instruction
/// section assembly. All data is retrieved from Firestore subcollections
/// and transformed into domain entities.
extension ExploreRemoteDataSourceIngredients on ExploreRemoteDataSource {
  /// Retrieves and constructs the complete ingredient list for a recipe.
  ///
  /// Fetches all ingredients from the recipe's ingredients subcollection,
  /// resolves ingredient category names and unit names, calculates nutritional
  /// percentages relative to total calories, and builds [ExploreIngredient]
  /// objects for each ingredient.
  Future<List<ExploreIngredient>> _getIngredients(
      DocumentReference<Map<String, dynamic>> recipe, {
        required int totalCalories,
      }) async {
    // Fetch all ingredient documents for the recipe.
    final snapshot = await recipe.collection('ingredients').get();
    // Extract unique ingredient category IDs from the ingredients.
    final categoryIds = snapshot.docs
        .map((doc) => _stringValue(doc.data()['ingredient_categories_id']))
        .where((id) => id.isNotEmpty)
        .toSet();
    // Resolve category IDs to their display names.
    final categoryNames = await _resolveIngredientCategoryNames(categoryIds);

    // Process each ingredient document concurrently.
    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final amount = _doubleValue(data['amount']);
        final categoryId = _stringValue(data['ingredient_categories_id']);
        // Extract nutrient information from the ingredient data.
        final nutrients = _nutritionFromData(data['nutrients']);
        final calories = nutrients.calories.toDouble();
        // Resolve the unit name from either custom unit or standard unit.
        final unit = await _resolveIngredientUnitName(
          customUnitId: _stringValue(data['customUnitId']),
          unitId: _stringValue(data['unitId']),
        );

        // Build the ingredient object with all nutritional and display information.
        return ExploreIngredient(
          name: _stringValue(data['name'], fallback: 'Ingredient'),
          // Format the amount with appropriate decimal precision and unit.
          amount: '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} $unit'
              .trim(),
          calories: _caloriesLabel(calories),
          imagePath: _stringValue(data['image'], fallback: ''),
          // Calculate the percentage of total calories this ingredient represents.
          nutritionPercent: totalCalories <= 0
              ? 0
              : (calories / totalCalories).clamp(0.0, 1.0),
          caloriesValue: calories,
          carbsGrams: nutrients.carbsGrams.toDouble(),
          proteinGrams: nutrients.proteinGrams.toDouble(),
          fatGrams: nutrients.fatGrams.toDouble(),
          fiberGrams: nutrients.fiberGrams.toDouble(),
          waterGrams: nutrients.waterGrams.toDouble(),
          vitamins: nutrients.vitamins,
          minerals: nutrients.minerals,
          ingredientCategoryId: categoryId,
          // Use the resolved category name or empty string if not found.
          ingredientCategoryName: categoryNames[categoryId] ?? '',
        );
      }).toList(),
    );
  }

  /// Resolves ingredient category IDs to their display names.
  ///
  /// Takes a set of category IDs and fetches the corresponding category
  /// documents from the app configuration collection. Returns a map
  /// where each ID maps to its display name.
  Future<Map<String, String>> _resolveIngredientCategoryNames(
      Set<String> categoryIds,
      ) async {
    if (categoryIds.isEmpty) return const {};

    // Fetch all category documents concurrently.
    final entries = await Future.wait(
      categoryIds.map((id) async {
        final doc = await firestore
            .collection('app_config')
            .doc('ingredient_categories')
            .collection('items')
            .doc(id)
            .get();
        // Use the category ID as fallback if the name is not found.
        return MapEntry(id, _stringValue(doc.data()?['name'], fallback: id));
      }),
    );

    return Map.fromEntries(entries);
  }

  /// Formats a calorie value into a display string with "kcal" suffix.
  ///
  /// Returns "0 kcal" for zero or negative values, otherwise formats the
  /// number appropriately and appends " kcal".
  String _caloriesLabel(double calories) {
    if (calories <= 0) return '0 kcal';
    return '${_formatNumber(calories)} kcal';
  }

  /// Extracts a numeric value from various possible data structures.
  ///
  /// Handles direct numeric values, maps containing 'value' or 'amount' keys,
  /// and string representations that can be parsed as doubles.
  double? _numericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _numericValue(value['value'] ?? value['amount']);
    return double.tryParse(value?.toString() ?? '');
  }

  /// Formats a double value for display with appropriate precision.
  ///
  /// Rounds to whole numbers if within 0.05 of a whole number, otherwise
  /// displays with one decimal place.
  String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
    return value.toStringAsFixed(1);
  }

  /// Resolves an ingredient unit ID to its display name.
  ///
  /// Checks for custom units first, then falls back to standard units
  /// from app configuration. Returns an empty string if neither unit ID
  /// resolves to a valid name.
  Future<String> _resolveIngredientUnitName({
    required String customUnitId,
    required String unitId,
  }) async {
    // Prioritize custom unit resolution.
    if (customUnitId.isNotEmpty) {
      final doc = await firestore
          .collection('custom')
          .doc('custom_units')
          .collection('items')
          .doc(customUnitId)
          .get();
      return _stringValue(doc.data()?['name'], fallback: customUnitId);
    }

    // Fall back to standard unit resolution.
    if (unitId.isNotEmpty) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_units')
          .collection('items')
          .doc(unitId)
          .get();
      return _stringValue(doc.data()?['name'], fallback: unitId);
    }

    // Return empty string if no unit ID is provided.
    return '';
  }

  /// Retrieves and constructs instruction sections for a recipe.
  ///
  /// Fetches all instruction steps from the recipe's instructions subcollection,
  /// sorts them by section index and step index, groups them into sections
  /// by section title, and builds [ExploreInstructionSection] objects.
  Future<List<ExploreInstructionSection>> _getInstructionSections(
      DocumentReference<Map<String, dynamic>> recipe,
      ) async {
    // Fetch all instruction documents for the recipe.
    final snapshot = await recipe.collection('instructions').get();
    final steps = snapshot.docs.map((doc) => doc.data()).toList()
    // Sort by section index first, then by step index within each section.
      ..sort((first, second) {
        final sectionCompare = _intValue(
          first['sectionIndex'],
        ).compareTo(_intValue(second['sectionIndex']));
        if (sectionCompare != 0) return sectionCompare;
        return _intValue(
          first['stepIndex'],
        ).compareTo(_intValue(second['stepIndex']));
      });

    // Return empty list if no instruction steps exist.
    if (steps.isEmpty) return const [];

    // Group steps by section title.
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final step in steps) {
      final title = _stringValue(
        step['sectionTitle'],
        fallback: 'Instructions',
      );
      sections.putIfAbsent(title, () => []).add(step);
    }

    // Convert each section group into an ExploreInstructionSection object.
    return sections.entries.map((entry) {
      return ExploreInstructionSection(
        title: entry.key,
        steps: entry.value.map((step) {
          return ExploreInstructionStep(
            title: 'Step ${_intValue(step['stepIndex'])}',
            description: _stringValue(step['description']),
            imagePath: _stringValue(step['stepImage'], fallback: ''),
          );
        }).toList(),
      );
    }).toList();
  }
}