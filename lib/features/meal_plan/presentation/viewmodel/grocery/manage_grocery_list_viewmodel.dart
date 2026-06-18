import 'package:flutter/foundation.dart';

import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/manage_grocery_list_detail.dart';
import '../../../domain/usecases/add_grocery_item_usecase.dart';
import '../../../domain/usecases/delete_grocery_item_usecase.dart';
import '../../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../../domain/usecases/update_grocery_item_bought_usecase.dart';
import '../../../domain/usecases/update_grocery_list_usecase.dart';

/// View mode for the grocery list management screen.
enum ManageGroceryViewMode {
  /// List view showing items grouped by category.
  list,

  /// Timeline view showing items grouped by meal date.
  timeline,
}

/// ViewModel for the Manage Grocery List feature.
/// Manages state for viewing, editing, and organizing grocery lists.
class ManageGroceryListViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// ID of the grocery list being managed.
  final String listId;

  /// Use case for fetching grocery list detail.
  final GetManageGroceryListDetailUseCase _getDetailUseCase;

  /// Use case for adding a grocery item.
  final AddGroceryItemUseCase _addGroceryItemUseCase;

  /// Use case for deleting a grocery item.
  final DeleteGroceryItemUseCase _deleteGroceryItemUseCase;

  /// Use case for updating item bought status.
  final UpdateGroceryItemBoughtUseCase _updateItemBoughtUseCase;

  /// Use case for updating grocery list details.
  final UpdateGroceryListUseCase _updateGroceryListUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// The grocery list detail data.
  ManageGroceryListDetail? _detail;

  /// Current view mode.
  ManageGroceryViewMode _viewMode = ManageGroceryViewMode.list;

  /// Set of bought item IDs.
  final Set<String> _boughtItemIds = {};

  /// Set of collapsed timeline day keys.
  final Set<String> _collapsedTimelineDayKeys = {};

  /// Set of collapsed timeline meal keys.
  final Set<String> _collapsedTimelineMealKeys = {};

  /// Whether to hide bought items.
  bool _hideBoughtItems = false;

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Whether changes have been saved.
  bool _hasSavedChanges = false;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Error message from loading.
  String? _errorMessage;

  /// Error message from actions.
  String? _actionErrorMessage;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new ManageGroceryListViewModel.
  ManageGroceryListViewModel({
    required this.listId,
    required GetManageGroceryListDetailUseCase getDetailUseCase,
    required AddGroceryItemUseCase addGroceryItemUseCase,
    required DeleteGroceryItemUseCase deleteGroceryItemUseCase,
    required UpdateGroceryItemBoughtUseCase updateItemBoughtUseCase,
    required UpdateGroceryListUseCase updateGroceryListUseCase,
  }) : _getDetailUseCase = getDetailUseCase,
       _addGroceryItemUseCase = addGroceryItemUseCase,
       _deleteGroceryItemUseCase = deleteGroceryItemUseCase,
       _updateItemBoughtUseCase = updateItemBoughtUseCase,
       _updateGroceryListUseCase = updateGroceryListUseCase {
    // Load the detail asynchronously after construction.
    Future.microtask(loadDetail);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// The grocery list detail.
  ManageGroceryListDetail? get detail => _detail;

  /// Current view mode.
  ManageGroceryViewMode get viewMode => _viewMode;

  /// Whether to hide bought items.
  bool get hideBoughtItems => _hideBoughtItems;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Whether changes have been saved.
  bool get hasSavedChanges => _hasSavedChanges;

  /// Error message from loading.
  String? get errorMessage => _errorMessage;

  /// Error message from actions.
  String? get actionErrorMessage => _actionErrorMessage;

  /// Total number of items in the list.
  int get totalItemCount =>
      _detail?.categories.fold<int>(
        0,
        (sum, category) => sum + category.items.length,
      ) ??
      0;

  /// Number of bought items.
  int get boughtCount => _boughtItemIds.length;

  /// Number of items still to buy.
  int get toBuyCount => totalItemCount - boughtCount;

  // =========================================================================
  // LOADING
  // =========================================================================

  /// Loads the grocery list detail from the repository.
  Future<void> loadDetail() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getDetailUseCase.execute(listId);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((detail) {
      _detail = detail;

      // Initialize bought item IDs from the detail.
      _boughtItemIds
        ..clear()
        ..addAll(
          detail.categories
              .expand((category) => category.items)
              .where((item) => item.bought)
              .map((item) => item.id),
        );
    });

    // Handle failure.
    result.ifLeft((failure) => _errorMessage = failure.message);

    // Reset loading state.
    _isLoading = false;
    _notifyIfActive();
  }

  // =========================================================================
  // VIEW MODE
  // =========================================================================

  /// Sets the view mode.
  void setViewMode(ManageGroceryViewMode mode) {
    // Return if mode is unchanged.
    if (_viewMode == mode) return;

    // Update the mode.
    _viewMode = mode;
    _notifyIfActive();
  }

  // =========================================================================
  // ITEM MANAGEMENT
  // =========================================================================

  /// Toggles the bought status of an item.
  Future<void> toggleBought(String itemId) async {
    // Determine the next value.
    final nextValue = !_boughtItemIds.contains(itemId);

    // Update the local state optimistically.
    if (_boughtItemIds.contains(itemId)) {
      _boughtItemIds.remove(itemId);
    } else {
      _boughtItemIds.add(itemId);
    }

    // Clear any previous action error.
    _actionErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _updateItemBoughtUseCase.execute(
      listId: listId,
      itemId: itemId,
      bought: nextValue,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle failure - rollback the optimistic update.
    result.ifLeft((failure) {
      _actionErrorMessage = failure.message;
      if (nextValue) {
        _boughtItemIds.remove(itemId);
      } else {
        _boughtItemIds.add(itemId);
      }
    });

    _notifyIfActive();
  }

  /// Checks if an item is bought.
  bool isBought(String itemId) => _boughtItemIds.contains(itemId);

  /// Adds a new item to the grocery list.
  Future<bool> addItem({
    required String name,
    required String amountText,
    required String unit,
    required String categoryName,
    List<String> relatedMealPlanIds = const [],
  }) async {
    // Validate the name.
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _actionErrorMessage = 'Ingredient name is required.';
      _notifyIfActive();
      return false;
    }

    // Validate the amount.
    final amount = double.tryParse(amountText.trim());
    if (amountText.trim().isNotEmpty && amount == null) {
      _actionErrorMessage = 'Quantity must be a number.';
      _notifyIfActive();
      return false;
    }

    // Set saving state.
    _isSaving = true;
    _actionErrorMessage = null;
    _notifyIfActive();

    // Build the request.
    final result = await _addGroceryItemUseCase.execute(
      AddGroceryItemRequest(
        listId: listId,
        name: trimmedName,
        amount: amount ?? 0,
        unit: unit,
        categoryName: categoryName,
        relatedMealPlanIds: relatedMealPlanIds,
      ),
    );

    // Check if disposed.
    if (_isDisposed) return false;

    // Handle the result.
    var saved = false;
    result.ifRight((_) => saved = true);
    result.ifLeft((failure) => _actionErrorMessage = failure.message);

    // Reset saving state.
    _isSaving = false;
    _notifyIfActive();

    // Reload the detail if saved successfully.
    if (saved) {
      _hasSavedChanges = true;
      await loadDetail();
    }

    return saved;
  }

  /// Deletes an item from the grocery list.
  Future<void> deleteItem(String itemId) async {
    // Set saving state.
    _isSaving = true;
    _actionErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _deleteGroceryItemUseCase.execute(
      listId: listId,
      itemId: itemId,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle failure.
    result.ifLeft((failure) => _actionErrorMessage = failure.message);

    // Reset saving state.
    _isSaving = false;
    _notifyIfActive();

    // Reload the detail if deleted successfully.
    if (result.isRight()) {
      await loadDetail();
    }
  }

  // =========================================================================
  // TIMELINE COLLAPSE
  // =========================================================================

  /// Checks if a timeline day is expanded.
  bool isTimelineDayExpanded(DateTime date) {
    return !_collapsedTimelineDayKeys.contains(_dayKey(date));
  }

  /// Checks if a timeline meal is expanded.
  bool isTimelineMealExpanded(DateTime date, String mealType, String title) {
    return !_collapsedTimelineMealKeys.contains(
      _mealKey(date, mealType, title),
    );
  }

  /// Toggles a timeline day expansion.
  void toggleTimelineDay(DateTime date) {
    final key = _dayKey(date);
    if (_collapsedTimelineDayKeys.contains(key)) {
      _collapsedTimelineDayKeys.remove(key);
    } else {
      _collapsedTimelineDayKeys.add(key);
    }
    _notifyIfActive();
  }

  /// Toggles a timeline meal expansion.
  void toggleTimelineMeal(DateTime date, String mealType, String title) {
    final key = _mealKey(date, mealType, title);
    if (_collapsedTimelineMealKeys.contains(key)) {
      _collapsedTimelineMealKeys.remove(key);
    } else {
      _collapsedTimelineMealKeys.add(key);
    }
    _notifyIfActive();
  }

  // =========================================================================
  // FILTERING
  // =========================================================================

  /// Determines if an item should be shown based on hide bought filter.
  bool shouldShowItem(String itemId) {
    final bought = isBought(itemId);
    if (_hideBoughtItems && bought) return false;
    return true;
  }

  /// Toggles the hide bought items filter.
  void toggleHideBoughtItems(bool value) {
    _hideBoughtItems = value;
    _notifyIfActive();
  }

  // =========================================================================
  // LIST UPDATE
  // =========================================================================

  /// Updates the grocery list details.
  Future<bool> updateList({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Validate the name.
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _actionErrorMessage = 'List name is required.';
      _notifyIfActive();
      return false;
    }

    // Validate the date range.
    if (endDate.isBefore(startDate)) {
      _actionErrorMessage = 'End date cannot be before start date.';
      _notifyIfActive();
      return false;
    }

    // Set saving state.
    _isSaving = true;
    _actionErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _updateGroceryListUseCase.execute(
      listId: listId,
      name: trimmedName,
      startDate: startDate,
      endDate: endDate,
    );

    // Check if disposed.
    if (_isDisposed) return false;

    // Handle the result.
    var saved = false;
    result.ifRight((_) => saved = true);
    result.ifLeft((failure) => _actionErrorMessage = failure.message);

    // Reset saving state.
    _isSaving = false;
    _notifyIfActive();

    // Reload the detail if saved successfully.
    if (saved) {
      await loadDetail();
    }

    return saved;
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  /// Generates a unique key for a day.
  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  /// Generates a unique key for a meal.
  String _mealKey(DateTime date, String mealType, String title) {
    return '${_dayKey(date)}-$mealType-$title';
  }

  // =========================================================================
  // DISPOSAL
  // =========================================================================

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
