import 'package:flutter/foundation.dart';

import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/add_grocery_list_plan.dart';
import '../../../domain/usecases/create_grocery_list_usecase.dart';
import '../../../domain/usecases/get_add_grocery_list_plan_usecase.dart';

/// ViewModel for the Add Grocery List feature.
/// Manages state for the two-step grocery list creation wizard.
class AddGroceryListViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// User ID of the current user.
  final String userId;

  /// Use case for fetching the grocery list plan.
  final GetAddGroceryListPlanUseCase _getPlanUseCase;

  /// Use case for creating a grocery list.
  final CreateGroceryListUseCase _createGroceryListUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// The grocery list plan data.
  AddGroceryListPlan? _plan;

  /// Current step in the wizard (1 or 2).
  int _currentStep = 1;

  /// Selected icon index.
  int _selectedIconIndex = 0;

  /// List name entered by the user.
  String _listName = '';

  /// Start date of the grocery list.
  DateTime _startDate = DateTime.now();

  /// End date of the grocery list.
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  /// Currently selected meal date.
  DateTime _selectedMealDate = DateTime.now();

  /// Set of excluded days.
  final Set<DateTime> _excludedDays = {};

  /// Set of selected meal IDs.
  final Set<String> _selectedMealIds = {};

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Error message from loading.
  String? _errorMessage;

  /// Error message from saving.
  String? _saveErrorMessage;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new AddGroceryListViewModel.
  AddGroceryListViewModel({
    required this.userId,
    required GetAddGroceryListPlanUseCase getPlanUseCase,
    required CreateGroceryListUseCase createGroceryListUseCase,
  }) : _getPlanUseCase = getPlanUseCase,
       _createGroceryListUseCase = createGroceryListUseCase {
    // Load the plan asynchronously after construction.
    Future.microtask(loadPlan);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// The grocery list plan.
  AddGroceryListPlan? get plan => _plan;

  /// Current step in the wizard.
  int get currentStep => _currentStep;

  /// Selected icon index.
  int get selectedIconIndex => _selectedIconIndex;

  /// List name.
  String get listName => _listName;

  /// Start date.
  DateTime get startDate => _startDate;

  /// End date.
  DateTime get endDate => _endDate;

  /// Selected meal date.
  DateTime get selectedMealDate => _selectedMealDate;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Error message from loading.
  String? get errorMessage => _errorMessage;

  /// Error message from saving.
  String? get saveErrorMessage => _saveErrorMessage;

  /// List of all days in the date range.
  List<DateTime> get dateRangeDays {
    // Calculate total days in the range.
    final totalDays = _endDate.difference(_startDate).inDays + 1;

    // Generate list of days.
    return List.generate(
      totalDays < 1 ? 1 : totalDays,
      (index) => _dateOnly(_startDate.add(Duration(days: index))),
    );
  }

  /// Sorted list of excluded days.
  List<DateTime> get excludedDays =>
      _excludedDays.toList()..sort((first, second) => first.compareTo(second));

  /// Number of days in the date range.
  int get selectedDayCount => dateRangeDays.length;

  /// Number of selected meals.
  int get selectedMealCount => _selectedMealIds.length;

  /// Whether the user can continue to the next step.
  bool get canContinue => _listName.trim().isNotEmpty;

  /// Whether the user can create the grocery list.
  bool get canCreate =>
      canContinue && _selectedMealIds.isNotEmpty && !_isSaving;

  /// Selected icon ID.
  String get selectedIconId {
    // Get icon options from the plan.
    final options = _plan?.iconOptions ?? const <GroceryIconOption>[];

    // Return default if no options.
    if (options.isEmpty) return 'basket';

    // Get the selected icon ID.
    final index = _selectedIconIndex.clamp(0, options.length - 1);
    return options[index].id;
  }

  /// Visible meal days filtered by date range and excluded days.
  List<GroceryMealDayPlan> get visibleMealDays {
    // Get source meal days from the plan.
    final source = _plan?.mealDays ?? const <GroceryMealDayPlan>[];

    // Filter by date range and excluded days.
    return dateRangeDays
        .where((date) => !_excludedDays.contains(_dateOnly(date)))
        .map((date) {
          // Find sections for this date.
          final sections = source
              .where((day) => _isSameDay(day.date, date))
              .expand((day) => day.sections)
              .toList();
          return GroceryMealDayPlan(date: date, sections: sections);
        })
        .toList();
  }

  /// Currently selected meal day.
  GroceryMealDayPlan? get selectedMealDay {
    // Get visible meal days.
    final mealDays = visibleMealDays;

    // Find the selected day.
    for (final day in mealDays) {
      if (_isSameDay(day.date, _selectedMealDate)) return day;
    }

    // Return first day if available.
    return mealDays.isNotEmpty ? mealDays.first : null;
  }

  // =========================================================================
  // LOADING
  // =========================================================================

  /// Loads the grocery list plan from the repository.
  Future<void> loadPlan() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getPlanUseCase.execute(userId);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((plan) {
      _plan = plan;

      // Set initial date range based on the first meal day.
      if (plan.mealDays.isNotEmpty) {
        final firstDay = _dateOnly(plan.mealDays.first.date);
        _startDate = firstDay;
        _endDate = firstDay.add(const Duration(days: 6));
        _selectedMealDate = firstDay;
      }

      // Select all meals by default.
      _selectedMealIds
        ..clear()
        ..addAll(
          plan.mealDays
              .expand((day) => day.sections)
              .expand((section) => section.meals)
              .map((meal) => meal.id),
        );
    });

    // Handle failure.
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Reset loading state.
    _isLoading = false;
    _notifyIfActive();
  }

  // =========================================================================
  // STEP 1: BASIC INFORMATION
  // =========================================================================

  /// Selects an icon by index.
  void selectIcon(int index) {
    _selectedIconIndex = index;
    _notifyIfActive();
  }

  /// Updates the list name.
  void updateListName(String value) {
    // Limit to 50 characters.
    _listName = value.length > 50 ? value.substring(0, 50) : value;
    _notifyIfActive();
  }

  /// Updates the date range.
  void updateDateRange(DateTime start, DateTime end) {
    // Normalize dates to start of day.
    _startDate = _dateOnly(start);
    _endDate = _dateOnly(end);

    // Remove excluded days outside the new range.
    _excludedDays.removeWhere((day) {
      return day.isBefore(_startDate) || day.isAfter(_endDate);
    });

    // Update selected meal date if outside range.
    if (_selectedMealDate.isBefore(_startDate) ||
        _selectedMealDate.isAfter(_endDate)) {
      _selectedMealDate = _startDate;
    }

    _notifyIfActive();
  }

  /// Toggles an excluded day.
  void toggleExcludedDay(DateTime date) {
    // Normalize the date.
    final normalized = _dateOnly(date);

    // Toggle the exclusion.
    if (_excludedDays.contains(normalized)) {
      _excludedDays.remove(normalized);
    } else {
      _excludedDays.add(normalized);
    }

    _notifyIfActive();
  }

  /// Checks if a day is excluded.
  bool isDayExcluded(DateTime date) {
    return _excludedDays.contains(_dateOnly(date));
  }

  // =========================================================================
  // STEP 2: SELECT MEALS
  // =========================================================================

  /// Selects a meal date.
  void selectMealDate(DateTime date) {
    _selectedMealDate = _dateOnly(date);
    _notifyIfActive();
  }

  /// Toggles a meal selection.
  void toggleMeal(String mealId) {
    if (_selectedMealIds.contains(mealId)) {
      _selectedMealIds.remove(mealId);
    } else {
      _selectedMealIds.add(mealId);
    }
    _notifyIfActive();
  }

  /// Checks if a meal is selected.
  bool isMealSelected(String mealId) {
    return _selectedMealIds.contains(mealId);
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  /// Navigates to the next step.
  void goToNextStep() {
    if (_currentStep >= 2 || !canContinue) return;
    _currentStep = 2;
    _notifyIfActive();
  }

  /// Navigates to the previous step.
  void goToPreviousStep() {
    if (_currentStep <= 1) return;
    _currentStep = 1;
    _notifyIfActive();
  }

  // =========================================================================
  // CREATE GROCERY LIST
  // =========================================================================

  /// Creates the grocery list.
  Future<String?> createGroceryList() async {
    // Validate that creation is possible.
    if (!canCreate) return null;

    // Get visible meal IDs.
    final visibleMealIds = visibleMealDays
        .expand((day) => day.sections)
        .expand((section) => section.meals)
        .map((meal) => meal.id)
        .toSet();

    // Set saving state.
    _isSaving = true;
    _saveErrorMessage = null;
    _notifyIfActive();

    // Build the request.
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

    // Check if disposed.
    if (_isDisposed) return null;

    // Handle the result.
    String? listId;
    result.ifRight((id) => listId = id);
    result.ifLeft((failure) => _saveErrorMessage = failure.message);

    // Reset saving state.
    _isSaving = false;
    _notifyIfActive();

    return listId;
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  /// Returns a date without time components.
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Checks if two dates are the same day.
  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
