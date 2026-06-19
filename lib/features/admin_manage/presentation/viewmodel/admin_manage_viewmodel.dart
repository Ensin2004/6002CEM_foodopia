import 'package:flutter/material.dart';

import '../../domain/entities/admin_manage_item.dart';
import '../../domain/usecases/delete_admin_manage_item_usecase.dart';
import '../../domain/usecases/get_admin_manage_items_usecase.dart';
import '../../domain/usecases/reorder_admin_manage_items_usecase.dart';
import '../../domain/usecases/save_admin_manage_item_usecase.dart';

/// Category metadata for admin-managed selectable values.
class AdminManageCategory {
  /// Unique identifier for the category.
  final String id;

  /// Display title of the category.
  final String title;

  /// Label for items in this category.
  final String itemLabel;

  /// Description of the category.
  final String description;

  /// Tip text for users.
  final String tip;

  /// Message shown when the category is empty.
  final String emptyMessage;

  /// Icon for the category.
  final IconData icon;

  /// Creates a new admin manage category instance.
  const AdminManageCategory({
    required this.id,
    required this.title,
    required this.itemLabel,
    required this.description,
    required this.tip,
    required this.emptyMessage,
    required this.icon,
  });
}

/// Admin state for managing recipe categories and user preference defaults.
class AdminManageViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Use case for getting items.
  final GetAdminManageItemsUseCase _getItemsUseCase;

  /// Use case for saving items.
  final SaveAdminManageItemUseCase _saveItemUseCase;

  /// Use case for deleting items.
  final DeleteAdminManageItemUseCase _deleteItemUseCase;

  /// Use case for reordering items.
  final ReorderAdminManageItemsUseCase _reorderItemsUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Error message.
  String? _errorMessage;

  /// Map of category ID to list of items.
  final Map<String, List<AdminManageItem>> _itemsByCategory = {};

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new admin manage view model instance.
  AdminManageViewModel({
    required GetAdminManageItemsUseCase getItemsUseCase,
    required SaveAdminManageItemUseCase saveItemUseCase,
    required DeleteAdminManageItemUseCase deleteItemUseCase,
    required ReorderAdminManageItemsUseCase reorderItemsUseCase,
  }) : _getItemsUseCase = getItemsUseCase,
        _saveItemUseCase = saveItemUseCase,
        _deleteItemUseCase = deleteItemUseCase,
        _reorderItemsUseCase = reorderItemsUseCase {
    // Load all items on initialization.
    loadAll();
  }

  // =========================================================================
  // CATEGORY DEFINITIONS
  // =========================================================================

  /// Recipe setup categories for admin management.
  static const recipeSetupCategories = [
    AdminManageCategory(
      id: 'meal_categories',
      title: 'Meal Categories',
      itemLabel: 'Meal Category',
      description:
      'Manage meal categories like Breakfast, Lunch, Dinner and more.',
      tip:
      'Manage meal categories shown to user. You can activate or deactivate categories.',
      emptyMessage: 'No meal categories yet',
      icon: Icons.restaurant_menu,
    ),
    AdminManageCategory(
      id: 'ingredient_categories',
      title: 'Ingredient Categories',
      itemLabel: 'Ingredient Category',
      description:
      'Manage ingredient categories such as Vegetables, Fruits, Meat, Dairy and more.',
      tip:
      'Manage ingredient categories used when recipes are created and filtered.',
      emptyMessage: 'No ingredient categories yet',
      icon: Icons.kitchen,
    ),
    AdminManageCategory(
      id: 'recipe_categories',
      title: 'Recipe Categories',
      itemLabel: 'Recipe Category',
      description:
      'Manage cuisine and recipe styles such as Italian, Chinese, Japanese and more.',
      tip:
      'Manage recipe categories used when recipes are created, filtered and explored.',
      emptyMessage: 'No recipe categories yet',
      icon: Icons.public,
    ),
  ];

  /// Preference categories for admin management.
  static const preferenceCategories = [
    AdminManageCategory(
      id: 'meal_preferences',
      title: 'Dietary Preferences',
      itemLabel: 'Dietary Preference',
      description: 'Manage dietary preferences shown to users during sign up.',
      tip:
      'These items are used as default options in the app. Users can still search and add more custom items.',
      emptyMessage: 'No meal preferences yet',
      icon: Icons.favorite,
    ),
    AdminManageCategory(
      id: 'allergies',
      title: 'Allergies',
      itemLabel: 'Allergy',
      description: 'Manage common allergies shown during sign up.',
      tip: 'These allergy defaults help users set profile preferences faster.',
      emptyMessage: 'No allergies yet',
      icon: Icons.health_and_safety,
    ),
    AdminManageCategory(
      id: 'dislikes',
      title: 'Food Dislikes',
      itemLabel: 'Food Dislike',
      description: 'Manage common food dislikes shown during sign up.',
      tip: 'These dislike defaults help users personalize meal suggestions.',
      emptyMessage: 'No dislikes yet',
      icon: Icons.thumb_down,
    ),
  ];

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Error message.
  String? get errorMessage => _errorMessage;

  /// Returns items for a category.
  List<AdminManageItem> itemsFor(String categoryId) =>
      _itemsByCategory[categoryId] ?? [];

  // =========================================================================
  // LOAD ALL
  // =========================================================================

  /// Loads all items for all categories.
  Future<void> loadAll() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load items for each category.
      for (final category in [
        ...recipeSetupCategories,
        ...preferenceCategories,
      ]) {
        final result = await _getItemsUseCase.execute(category.id);

        // Handle result.
        await result.fold((failure) async => _errorMessage = failure.message, (
            items,
            ) async {
          // Check for duplicate names.
          final duplicateIds = _duplicateIds(items);

          // If no duplicates, store items.
          if (duplicateIds.isEmpty) {
            _itemsByCategory[category.id] = items;
            return;
          }

          // Delete duplicate items and reload.
          await _deleteDuplicateItems(
            categoryId: category.id,
            duplicateIds: duplicateIds,
          );
          await _reloadCategory(category.id);
        });
      }
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
    }

    // Reset loading state.
    _isLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // SAVE ITEM
  // =========================================================================

  /// Saves an item (creates or updates).
  Future<bool> saveItem({
    required String categoryId,
    String? id,
    required String name,
    required String description,
    String iconKey = '',
    required int sortOrder,
    required bool isActive,
  }) async {
    // Trim the name.
    final trimmedName = name.trim();

    // Validate the name.
    if (trimmedName.isEmpty) {
      _errorMessage = 'Name cannot be empty';
      notifyListeners();
      return false;
    }

    // Check for duplicate name.
    if (_hasDuplicateName(categoryId: categoryId, id: id, name: trimmedName)) {
      _errorMessage = 'This name already exists in this list';
      notifyListeners();
      return false;
    }

    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Execute the use case.
      final result = await _saveItemUseCase.execute(
        categoryId: categoryId,
        item: AdminManageItem(
          id: id ?? '',
          name: trimmedName,
          description: description.trim(),
          iconKey: iconKey,
          sortOrder: sortOrder,
          isActive: isActive,
        ),
      );

      // Handle the result.
      final success = result.fold((failure) {
        _errorMessage = failure.message;
        return false;
      }, (_) => true);

      // Return false on failure.
      if (!success) {
        _isSaving = false;
        notifyListeners();
        return false;
      }

      // Reload the category.
      await _reloadCategory(categoryId);

      // Reset saving state.
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // DELETE ITEM
  // =========================================================================

  /// Deletes an item.
  Future<bool> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Execute the use case.
      final result = await _deleteItemUseCase.execute(
        categoryId: categoryId,
        id: id,
      );

      // Handle the result.
      final success = result.fold((failure) {
        _errorMessage = failure.message;
        return false;
      }, (_) => true);

      // Return false on failure.
      if (!success) {
        _isSaving = false;
        notifyListeners();
        return false;
      }

      // Reload the category.
      await _reloadCategory(categoryId);

      // Reset saving state.
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // REORDER ITEMS
  // =========================================================================

  /// Reorders items in a category.
  Future<bool> reorderItems({
    required String categoryId,
    required int oldIndex,
    required int newIndex,
  }) async {
    // Get current items.
    final items = List<AdminManageItem>.from(itemsFor(categoryId));

    // Adjust new index for removal.
    if (newIndex > oldIndex) newIndex -= 1;

    // Validate indices.
    if (oldIndex < 0 || oldIndex >= items.length) return false;
    if (newIndex < 0 || newIndex >= items.length) return false;

    // Reorder the list.
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Update sort orders.
    _itemsByCategory[categoryId] = [
      for (var i = 0; i < items.length; i++)
        items[i].copyWith(sortOrder: i + 1),
    ];

    // Notify listeners of optimistic update.
    notifyListeners();

    // Execute the use case.
    final result = await _reorderItemsUseCase.execute(
      categoryId: categoryId,
      items: _itemsByCategory[categoryId]!,
    );

    // Handle the result.
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (_) => true);

    // Reload on failure.
    if (!success) await _reloadCategory(categoryId);

    notifyListeners();
    return success;
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Reloads a single category.
  Future<void> _reloadCategory(String categoryId) async {
    final result = await _getItemsUseCase.execute(categoryId);

    result.fold(
          (failure) => _errorMessage = failure.message,
          (items) => _itemsByCategory[categoryId] = items,
    );
  }

  /// Checks if a duplicate name exists.
  bool _hasDuplicateName({
    required String categoryId,
    required String? id,
    required String name,
  }) {
    final normalizedName = _normalizeName(name);

    return itemsFor(categoryId).any(
          (item) => item.id != id && _normalizeName(item.name) == normalizedName,
    );
  }

  /// Finds duplicate IDs in a list of items.
  List<String> _duplicateIds(List<AdminManageItem> items) {
    final seenNames = <String>{};
    final duplicateIds = <String>[];

    for (final item in items) {
      final normalizedName = _normalizeName(item.name);

      if (normalizedName.isEmpty) continue;

      if (seenNames.contains(normalizedName)) {
        duplicateIds.add(item.id);
      } else {
        seenNames.add(normalizedName);
      }
    }

    return duplicateIds;
  }

  /// Deletes duplicate items from a category.
  Future<void> _deleteDuplicateItems({
    required String categoryId,
    required List<String> duplicateIds,
  }) async {
    for (final id in duplicateIds) {
      final result = await _deleteItemUseCase.execute(
        categoryId: categoryId,
        id: id,
      );
      result.fold((failure) => _errorMessage = failure.message, (_) => null);
    }
  }

  /// Normalizes a string for comparison.
  String _normalizeName(String value) => value.trim().toLowerCase();
}