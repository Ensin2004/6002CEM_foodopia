import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/usecases/create_grocery_list_usecase.dart';
import '../../domain/usecases/get_add_grocery_list_plan_usecase.dart';

class AddGroceryListViewModel extends ChangeNotifier {
  final String userId;
  final GetAddGroceryListPlanUseCase _getPlanUseCase;
  final CreateGroceryListUseCase _createGroceryListUseCase;

  AddGroceryListPlan? _plan;
  int _currentStep = 1;
  int _selectedIconIndex = 0;
  String _listName = '';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  DateTime _selectedMealDate = DateTime.now();
  final Set<DateTime> _excludedDays = {};
  final Set<String> _selectedMealIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _saveErrorMessage;

  AddGroceryListViewModel({
    required this.userId,
    required GetAddGroceryListPlanUseCase getPlanUseCase,
    required CreateGroceryListUseCase createGroceryListUseCase,
  }) : _getPlanUseCase = getPlanUseCase,
       _createGroceryListUseCase = createGroceryListUseCase {
    Future.microtask(loadPlan);
  }

  AddGroceryListPlan? get plan => _plan;
  int get currentStep => _currentStep;
  int get selectedIconIndex => _selectedIconIndex;
  String get listName => _listName;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  DateTime get selectedMealDate => _selectedMealDate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get saveErrorMessage => _saveErrorMessage;

  List<DateTime> get dateRangeDays {
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    return List.generate(
      totalDays < 1 ? 1 : totalDays,
      (index) => _dateOnly(_startDate.add(Duration(days: index))),
    );
  }

  List<DateTime> get excludedDays =>
      _excludedDays.toList()..sort((first, second) => first.compareTo(second));

  int get selectedDayCount => dateRangeDays.length;
  int get selectedMealCount => _selectedMealIds.length;
  bool get canContinue => _listName.trim().isNotEmpty;
  bool get canCreate =>
      canContinue && _selectedMealIds.isNotEmpty && !_isSaving;

  String get selectedIconId {
    final options = _plan?.iconOptions ?? const <GroceryIconOption>[];
    if (options.isEmpty) return 'basket';
    final index = _selectedIconIndex.clamp(0, options.length - 1);
    return options[index].id;
  }

  List<GroceryMealDayPlan> get visibleMealDays {
    final source = _plan?.mealDays ?? const <GroceryMealDayPlan>[];
    return dateRangeDays
        .where((date) => !_excludedDays.contains(_dateOnly(date)))
        .map((date) {
          final sections = source
              .where((day) => _isSameDay(day.date, date))
              .expand((day) => day.sections)
              .toList();
          return GroceryMealDayPlan(date: date, sections: sections);
        })
        .toList();
  }

  GroceryMealDayPlan? get selectedMealDay {
    final mealDays = visibleMealDays;
    for (final day in mealDays) {
      if (_isSameDay(day.date, _selectedMealDate)) return day;
    }
    return mealDays.isNotEmpty ? mealDays.first : null;
  }

  Future<void> loadPlan() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getPlanUseCase.execute(userId);
    if (_isDisposed) return;

    result.ifRight((plan) {
      _plan = plan;
      if (plan.mealDays.isNotEmpty) {
        final firstDay = _dateOnly(plan.mealDays.first.date);
        _startDate = firstDay;
        _endDate = firstDay.add(const Duration(days: 6));
        _selectedMealDate = firstDay;
      }
      _selectedMealIds
        ..clear()
        ..addAll(
          plan.mealDays
              .expand((day) => day.sections)
              .expand((section) => section.meals)
              .map((meal) => meal.id),
        );
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectIcon(int index) {
    _selectedIconIndex = index;
    _notifyIfActive();
  }

  void updateListName(String value) {
    _listName = value.length > 50 ? value.substring(0, 50) : value;
    _notifyIfActive();
  }

  void updateDateRange(DateTime start, DateTime end) {
    _startDate = _dateOnly(start);
    _endDate = _dateOnly(end);
    _excludedDays.removeWhere((day) {
      return day.isBefore(_startDate) || day.isAfter(_endDate);
    });
    if (_selectedMealDate.isBefore(_startDate) ||
        _selectedMealDate.isAfter(_endDate)) {
      _selectedMealDate = _startDate;
    }
    _notifyIfActive();
  }

  void toggleExcludedDay(DateTime date) {
    final normalized = _dateOnly(date);
    if (_excludedDays.contains(normalized)) {
      _excludedDays.remove(normalized);
    } else {
      _excludedDays.add(normalized);
    }
    _notifyIfActive();
  }

  bool isDayExcluded(DateTime date) {
    return _excludedDays.contains(_dateOnly(date));
  }

  void selectMealDate(DateTime date) {
    _selectedMealDate = _dateOnly(date);
    _notifyIfActive();
  }

  void toggleMeal(String mealId) {
    if (_selectedMealIds.contains(mealId)) {
      _selectedMealIds.remove(mealId);
    } else {
      _selectedMealIds.add(mealId);
    }
    _notifyIfActive();
  }

  bool isMealSelected(String mealId) {
    return _selectedMealIds.contains(mealId);
  }

  void goToNextStep() {
    if (_currentStep >= 2 || !canContinue) return;
    _currentStep = 2;
    _notifyIfActive();
  }

  void goToPreviousStep() {
    if (_currentStep <= 1) return;
    _currentStep = 1;
    _notifyIfActive();
  }

  Future<String?> createGroceryList() async {
    if (!canCreate) return null;
    final visibleMealIds = visibleMealDays
        .expand((day) => day.sections)
        .expand((section) => section.meals)
        .map((meal) => meal.id)
        .toSet();
    _isSaving = true;
    _saveErrorMessage = null;
    _notifyIfActive();

    final result = await _createGroceryListUseCase.execute(
      CreateGroceryListRequest(
        userId: userId,
        title: _listName,
        iconId: selectedIconId,
        startDate: _startDate,
        endDate: _endDate,
        excludedDays: excludedDays,
        mealPlanIds: _selectedMealIds
            .where((mealId) => visibleMealIds.contains(mealId))
            .toList(),
      ),
    );
    if (_isDisposed) return null;

    String? listId;
    result.ifRight((id) => listId = id);
    result.ifLeft((failure) => _saveErrorMessage = failure.message);
    _isSaving = false;
    _notifyIfActive();
    return listId;
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
