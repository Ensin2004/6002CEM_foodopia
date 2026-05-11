import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';

enum ManageGroceryViewMode { list, timeline }

enum ManageGroceryItemFilter { all, toBuy, bought }

class ManageGroceryListViewModel extends ChangeNotifier {
  final String listId;
  final GetManageGroceryListDetailUseCase _getDetailUseCase;

  ManageGroceryListDetail? _detail;
  ManageGroceryViewMode _viewMode = ManageGroceryViewMode.list;
  ManageGroceryItemFilter _filter = ManageGroceryItemFilter.all;
  final Set<String> _boughtItemIds = {};
  final Set<String> _collapsedTimelineDayKeys = {};
  final Set<String> _collapsedTimelineMealKeys = {};
  bool _hideBoughtItems = false;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  ManageGroceryListViewModel({
    required this.listId,
    required GetManageGroceryListDetailUseCase getDetailUseCase,
  }) : _getDetailUseCase = getDetailUseCase {
    Future.microtask(loadDetail);
  }

  ManageGroceryListDetail? get detail => _detail;
  ManageGroceryViewMode get viewMode => _viewMode;
  ManageGroceryItemFilter get filter => _filter;
  bool get hideBoughtItems => _hideBoughtItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

    result.ifRight((detail) => _detail = detail);
    result.ifLeft((failure) => _errorMessage = failure.message);

    _isLoading = false;
    _notifyIfActive();
  }

  void setViewMode(ManageGroceryViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _notifyIfActive();
  }

  void setFilter(ManageGroceryItemFilter filter) {
    _filter = filter;
    _notifyIfActive();
  }

  void toggleBought(String itemId) {
    if (_boughtItemIds.contains(itemId)) {
      _boughtItemIds.remove(itemId);
    } else {
      _boughtItemIds.add(itemId);
    }
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
    switch (_filter) {
      case ManageGroceryItemFilter.all:
        return true;
      case ManageGroceryItemFilter.toBuy:
        return !bought;
      case ManageGroceryItemFilter.bought:
        return bought;
    }
  }

  void toggleHideBoughtItems(bool value) {
    _hideBoughtItems = value;
    _notifyIfActive();
  }

  void updateDateRange(DateTime start, DateTime end) {
    final current = _detail;
    if (current == null) return;
    _detail = ManageGroceryListDetail(
      id: current.id,
      title: current.title,
      itemCount: current.itemCount,
      mealCount: current.mealCount,
      categoryCount: current.categoryCount,
      startDate: start,
      endDate: end,
      upcomingMeals: current.upcomingMeals,
      categories: current.categories,
      timelineDays: current.timelineDays,
    );
    _notifyIfActive();
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
