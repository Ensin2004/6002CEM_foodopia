import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../domain/usecases/update_grocery_item_bought_usecase.dart';
import '../../domain/usecases/update_grocery_list_usecase.dart';

enum ManageGroceryViewMode { list, timeline }

class ManageGroceryListViewModel extends ChangeNotifier {
  final String listId;
  final GetManageGroceryListDetailUseCase _getDetailUseCase;
  final UpdateGroceryItemBoughtUseCase _updateItemBoughtUseCase;
  final UpdateGroceryListUseCase _updateGroceryListUseCase;

  ManageGroceryListDetail? _detail;
  ManageGroceryViewMode _viewMode = ManageGroceryViewMode.list;
  final Set<String> _boughtItemIds = {};
  final Set<String> _collapsedTimelineDayKeys = {};
  final Set<String> _collapsedTimelineMealKeys = {};
  bool _hideBoughtItems = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  ManageGroceryListViewModel({
    required this.listId,
    required GetManageGroceryListDetailUseCase getDetailUseCase,
    required UpdateGroceryItemBoughtUseCase updateItemBoughtUseCase,
    required UpdateGroceryListUseCase updateGroceryListUseCase,
  }) : _getDetailUseCase = getDetailUseCase,
       _updateItemBoughtUseCase = updateItemBoughtUseCase,
       _updateGroceryListUseCase = updateGroceryListUseCase {
    Future.microtask(loadDetail);
  }

  ManageGroceryListDetail? get detail => _detail;
  ManageGroceryViewMode get viewMode => _viewMode;
  bool get hideBoughtItems => _hideBoughtItems;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  int get totalItemCount =>
      _detail?.categories.fold<int>(
        0,
        (sum, category) => sum + category.items.length,
      ) ??
      0;
  int get boughtCount => _boughtItemIds.length;
  int get toBuyCount => totalItemCount - boughtCount;

  Future<void> loadDetail() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getDetailUseCase.execute(listId);
    if (_isDisposed) return;

    result.ifRight((detail) {
      _detail = detail;
      _boughtItemIds
        ..clear()
        ..addAll(
          detail.categories
              .expand((category) => category.items)
              .where((item) => item.bought)
              .map((item) => item.id),
        );
    });
    result.ifLeft((failure) => _errorMessage = failure.message);

    _isLoading = false;
    _notifyIfActive();
  }

  void setViewMode(ManageGroceryViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _notifyIfActive();
  }

  Future<void> toggleBought(String itemId) async {
    final nextValue = !_boughtItemIds.contains(itemId);
    if (_boughtItemIds.contains(itemId)) {
      _boughtItemIds.remove(itemId);
    } else {
      _boughtItemIds.add(itemId);
    }
    _actionErrorMessage = null;
    _notifyIfActive();

    final result = await _updateItemBoughtUseCase.execute(
      listId: listId,
      itemId: itemId,
      bought: nextValue,
    );
    if (_isDisposed) return;

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

  bool isBought(String itemId) => _boughtItemIds.contains(itemId);

  bool isTimelineDayExpanded(DateTime date) {
    return !_collapsedTimelineDayKeys.contains(_dayKey(date));
  }

  bool isTimelineMealExpanded(DateTime date, String mealType, String title) {
    return !_collapsedTimelineMealKeys.contains(
      _mealKey(date, mealType, title),
    );
  }

  void toggleTimelineDay(DateTime date) {
    final key = _dayKey(date);
    if (_collapsedTimelineDayKeys.contains(key)) {
      _collapsedTimelineDayKeys.remove(key);
    } else {
      _collapsedTimelineDayKeys.add(key);
    }
    _notifyIfActive();
  }

  void toggleTimelineMeal(DateTime date, String mealType, String title) {
    final key = _mealKey(date, mealType, title);
    if (_collapsedTimelineMealKeys.contains(key)) {
      _collapsedTimelineMealKeys.remove(key);
    } else {
      _collapsedTimelineMealKeys.add(key);
    }
    _notifyIfActive();
  }

  bool shouldShowItem(String itemId) {
    final bought = isBought(itemId);
    if (_hideBoughtItems && bought) return false;
    return true;
  }

  void toggleHideBoughtItems(bool value) {
    _hideBoughtItems = value;
    _notifyIfActive();
  }

  Future<bool> updateList({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _actionErrorMessage = 'List name is required.';
      _notifyIfActive();
      return false;
    }
    if (endDate.isBefore(startDate)) {
      _actionErrorMessage = 'End date cannot be before start date.';
      _notifyIfActive();
      return false;
    }

    _isSaving = true;
    _actionErrorMessage = null;
    _notifyIfActive();

    final result = await _updateGroceryListUseCase.execute(
      listId: listId,
      name: trimmedName,
      startDate: startDate,
      endDate: endDate,
    );
    if (_isDisposed) return false;

    var saved = false;
    result.ifRight((_) => saved = true);
    result.ifLeft((failure) => _actionErrorMessage = failure.message);
    _isSaving = false;
    _notifyIfActive();

    if (saved) {
      await loadDetail();
    }
    return saved;
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _mealKey(DateTime date, String mealType, String title) {
    return '${_dayKey(date)}-$mealType-$title';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
