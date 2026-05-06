import 'package:flutter/material.dart';

import '../../domain/entities/admin_manage_item.dart';
import '../../domain/usecases/delete_admin_manage_item_usecase.dart';
import '../../domain/usecases/get_admin_manage_items_usecase.dart';
import '../../domain/usecases/save_admin_manage_item_usecase.dart';
import '../../domain/usecases/seed_admin_manage_defaults_usecase.dart';

/// Category metadata for admin-managed selectable values.
class AdminManageCategory {
  final String id;
  final String title;
  final String itemLabel;
  final String description;
  final String tip;
  final String emptyMessage;
  final IconData icon;
  final List<String> seedValues;

  const AdminManageCategory({
    required this.id,
    required this.title,
    required this.itemLabel,
    required this.description,
    required this.tip,
    required this.emptyMessage,
    required this.icon,
    required this.seedValues,
  });
}

/// Admin state for managing recipe categories and user preference defaults.
class AdminManageViewModel extends ChangeNotifier {
  final GetAdminManageItemsUseCase _getItemsUseCase;
  final SaveAdminManageItemUseCase _saveItemUseCase;
  final DeleteAdminManageItemUseCase _deleteItemUseCase;
  final SeedAdminManageDefaultsUseCase _seedDefaultsUseCase;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, List<AdminManageItem>> _itemsByCategory = {};

  AdminManageViewModel({
    required GetAdminManageItemsUseCase getItemsUseCase,
    required SaveAdminManageItemUseCase saveItemUseCase,
    required DeleteAdminManageItemUseCase deleteItemUseCase,
    required SeedAdminManageDefaultsUseCase seedDefaultsUseCase,
  }) : _getItemsUseCase = getItemsUseCase,
       _saveItemUseCase = saveItemUseCase,
       _deleteItemUseCase = deleteItemUseCase,
       _seedDefaultsUseCase = seedDefaultsUseCase {
    loadAll();
  }

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
      seedValues: ['Breakfast', 'Lunch', 'Tea Time', 'Dinner'],
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
      seedValues: ['Dairy', 'Meat', 'Vegetables', 'Seafood'],
    ),
  ];

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
      seedValues: ['Vegetarian', 'High Protein', 'Low Carb', 'Halal'],
    ),
    AdminManageCategory(
      id: 'allergies',
      title: 'Allergies',
      itemLabel: 'Allergy',
      description: 'Manage common allergies shown during sign up.',
      tip: 'These allergy defaults help users set profile preferences faster.',
      emptyMessage: 'No allergies yet',
      icon: Icons.health_and_safety,
      seedValues: ['Dairy', 'Eggs', 'Peanuts', 'Seafood'],
    ),
    AdminManageCategory(
      id: 'dislikes',
      title: 'Food Dislikes',
      itemLabel: 'Food Dislike',
      description: 'Manage common food dislikes shown during sign up.',
      tip: 'These dislike defaults help users personalize meal suggestions.',
      emptyMessage: 'No dislikes yet',
      icon: Icons.thumb_down,
      seedValues: ['Onion', 'Garlic', 'Spicy Food', 'Mushrooms'],
    ),
  ];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<AdminManageItem> itemsFor(String categoryId) =>
      _itemsByCategory[categoryId] ?? [];

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final category in [
        ...recipeSetupCategories,
        ...preferenceCategories,
      ]) {
        final result = await _getItemsUseCase.execute(category.id);
        result.fold(
          (failure) => _errorMessage = failure.message,
          (items) => _itemsByCategory[category.id] = items,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveItem({
    required String categoryId,
    String? id,
    required String name,
    required String description,
    String iconKey = '',
    required int sortOrder,
    required bool isActive,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Name cannot be empty';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
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

      final success = result.fold((failure) {
        _errorMessage = failure.message;
        return false;
      }, (_) => true);

      if (!success) {
        _isSaving = false;
        notifyListeners();
        return false;
      }

      await _reloadCategory(categoryId);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _deleteItemUseCase.execute(
        categoryId: categoryId,
        id: id,
      );
      final success = result.fold((failure) {
        _errorMessage = failure.message;
        return false;
      }, (_) => true);

      if (!success) {
        _isSaving = false;
        notifyListeners();
        return false;
      }

      await _reloadCategory(categoryId);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> seedDefaults(AdminManageCategory category) async {
    if (itemsFor(category.id).isNotEmpty) return;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _seedDefaultsUseCase.execute(
        categoryId: category.id,
        values: category.seedValues,
      );
      result.fold((failure) => _errorMessage = failure.message, (_) => null);
      await _reloadCategory(category.id);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isSaving = false;
    notifyListeners();
  }

  Future<void> _reloadCategory(String categoryId) async {
    final result = await _getItemsUseCase.execute(categoryId);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (items) => _itemsByCategory[categoryId] = items,
    );
  }
}
