import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../../admin_moderation/domain/usecases/mark_admin_recipe_reviewed_usecase.dart';
import '../../../admin_moderation/domain/usecases/update_admin_recipe_visibility_usecase.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../../meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../../meal_plan/domain/entities/meal_serving_amount.dart';
import '../../../meal_plan/domain/services/meal_calorie_guidance_service.dart';
import '../../../meal_plan/domain/usecases/get_meal_categories_usecase.dart';
import '../../../meal_plan/domain/usecases/save_recipe_meal_plan_usecase.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_recipe_detail_viewmodel.dart';

part 'explore_recipe_detail_recipe_tab.dart';
part 'explore_recipe_detail_nutrition_tab.dart';
part 'explore_recipe_detail_community_tab.dart';

/// Displays detailed recipe information with three tab views: recipe, nutrition, and community.
/// Supports library actions, meal plan selection, and favourite toggling.
class ExploreRecipeDetailPage extends StatelessWidget {
  final String recipeId;
  final bool showLibraryActions;
  final bool isPublished;
  final bool isAdminModeration;
  final MealPlanSelectionArgs? mealPlanSelection;

  const ExploreRecipeDetailPage({
    super.key,
    required this.recipeId,
    this.showLibraryActions = false,
    this.isPublished = true,
    this.isAdminModeration = false,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Provides the view model to the widget tree for state management.
    return ChangeNotifierProvider(
      create: (_) => ExploreRecipeDetailViewModel(
        recipeId: recipeId,
        getRecipeDetailUseCase: sl(),
        submitRecipeRatingUseCase: sl(),
        addRecipeCommentUseCase: sl(),
        incrementRecipeViewCountUseCase: sl(),
        toggleRecipeCommentLikeUseCase: sl(),
        addRecipeCommentReplyUseCase: sl(),
        toggleRecipeReplyLikeUseCase: sl(),
        addRecipeReplyToReplyUseCase: sl(),
        watchRecipeDetailUseCase: sl(),
        toggleCreatorFollowUseCase: sl(),
        updateRecipeVisibilityUseCase: sl(),
        updateAdminRecipeVisibilityUseCase:
            sl<UpdateAdminRecipeVisibilityUseCase>(),
        markAdminRecipeReviewedUseCase: sl<MarkAdminRecipeReviewedUseCase>(),
        toggleFavouriteUseCase: sl(),
        saveRecipeMealPlanUseCase: sl<SaveRecipeMealPlanUseCase>(),
        getMealCategoriesUseCase: sl<GetMealCategoriesUseCase>(),
        isAdminModeration: isAdminModeration,
      ),
      child: _ExploreRecipeDetailView(
        showLibraryActions: showLibraryActions,
        isPublished: isPublished,
        isAdminModeration: isAdminModeration,
        mealPlanSelection: mealPlanSelection,
      ),
    );
  }
}

class _ExploreRecipeDetailView extends StatefulWidget {
  final bool showLibraryActions;
  final bool isPublished;
  final bool isAdminModeration;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _ExploreRecipeDetailView({
    required this.showLibraryActions,
    required this.isPublished,
    required this.isAdminModeration,
    this.mealPlanSelection,
  });

  @override
  State<_ExploreRecipeDetailView> createState() =>
      _ExploreRecipeDetailViewState();
}

/// Manages the recipe detail view state, tab navigation, and user interactions.
class _ExploreRecipeDetailViewState extends State<_ExploreRecipeDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    // Initializes the tab controller with the number of available tabs.
    _tabController = TabController(
      length: ExploreRecipeDetailTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
    _isPublished = widget.isPublished;
  }

  // Synchronizes tab changes with the view model state.
  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    _selectDetailTab(_tabController.index);
  }

  // Updates the selected tab in the view model.
  void _selectDetailTab(int index) {
    context.read<ExploreRecipeDetailViewModel>().selectTab(
      ExploreRecipeDetailTab.values[index],
    );
  }

  // Displays a snackbar indicating the feature is not yet available.
  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  // Navigates to the recipe review screen for editing.
  void _openRecipeReview(ExploreRecipeDetailViewModel viewModel) {
    final recipeId = viewModel.recipe?.id;
    if (recipeId == null || recipeId.isEmpty) return;

    context.push(
      AppRouter.addRecipeReview,
      extra: AddRecipeReviewArgs(recipeId: recipeId),
    );
  }

  // Toggles the favourite status and shows a feedback message.
  Future<void> _toggleFavourite(ExploreRecipeDetailViewModel viewModel) async {
    final success = await viewModel.toggleFavourite();
    if (!mounted) return;

    final message = success
        ? viewModel.recipe?.isFavourite == true
              ? 'Added to library favourites.'
              : 'Removed from library favourites.'
        : viewModel.communityActionErrorMessage ??
              'Unable to update favourites.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Opens a bottom sheet for selecting dates and meal categories to add the recipe to a meal plan.
  /// Handles loading states, user authentication, and error feedback.
  Future<void> _openMealPlanCalendar(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    var isShowingLoadingDialog = false;
    try {
      // Guards against null recipe or in-progress operations.
      if (viewModel.recipe == null || viewModel.isSavingMealPlan) return;

      // Verifies user authentication before proceeding.
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Sign in to add this meal plan.')),
          );
        return;
      }

      // Loads meal categories if not already available.
      if (viewModel.mealCategories.isEmpty) {
        await viewModel.loadMealCategories();
        if (!mounted) return;
      }

      // Displays the calendar selection bottom sheet.
      final request =
          await showModalBottomSheet<_RecipeCalendarMealPlanRequest>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _RecipeCalendarMealPlanSheet(
              categories: viewModel.mealCategories.isEmpty
                  ? RecipeDetailMealPlanDefaults.categories
                  : viewModel.mealCategories,
              initialServings: (viewModel.recipe?.servings ?? 1).toDouble(),
            ),
          );
      if (request == null || !mounted) return;

      // Shows a loading dialog while saving the meal plan.
      isShowingLoadingDialog = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingDialog(message: 'Adding meal plan...'),
      );
      final result = await viewModel.saveToMealPlanDates(
        userId: userId,
        dates: request.dates,
        mealCategories: request.mealCategories,
        source: 'recipe_detail_calendar',
        servingCount: request.servingCount,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      isShowingLoadingDialog = false;

      // Displays success or error feedback.
      final message = result.isSuccess
          ? result.savedCount == 1
                ? 'Meal plan added.'
                : '${result.savedCount} meal plans added.'
          : result.errorMessage ?? 'Unable to add meal plan.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      // Handles unexpected errors and cleans up loading state.
      if (!mounted) return;
      if (isShowingLoadingDialog) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Unable to open calendar: $error')),
        );
    }
  }

  /// Handles selecting a recipe for a specific meal plan slot from a selection context.
  /// Checks for duplicates, asks for serving count, and navigates to the meal plan screen on success.
  Future<void> _selectForMealPlan(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    final selection = widget.mealPlanSelection;
    if (selection == null) return;
    // Prevents duplicate additions to the meal plan.
    final recipeId = viewModel.recipe?.id;
    if (recipeId != null && selection.existingRecipeIds.contains(recipeId)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This recipe is already added.')),
        );
      return;
    }
    final servingCount = selection.normalizedPlannedServings;
    final recipe = viewModel.recipe;
    final guidance = MealCalorieGuidanceService().evaluate(
      budget: selection.calorieBudget,
      mealCalories: recipe == null
          ? 0
          : MealServingAmount.scaledCalories(
              recipeCalories: recipe.nutrition.calories,
              recipeServings: recipe.servings,
              plannedServings: servingCount,
            ),
    );
    if (guidance.status == MealCalorieGuidanceStatus.exceeds) {
      final shouldAdd = await _showOverTargetDialog(guidance);
      if (shouldAdd != true || !mounted) return;
    }

    // Saves the recipe to the meal plan.
    final success = await viewModel.saveToMealPlan(
      userId: selection.userId,
      date: selection.selectedDate,
      mealCategory: AddMealCategoryOption(
        id: selection.mealCategoryId,
        name: selection.mealCategoryName,
      ),
      source: selection.source,
      servingCount: servingCount,
    );
    if (!mounted) return;

    // Shows feedback message based on the operation result.
    final message = success
        ? 'Meal plan added.'
        : viewModel.communityActionErrorMessage ?? 'Unable to add meal plan.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (!success) return;

    // Return success to the existing planning page so it can refresh cheaply.
    context.pop(true);
  }

  Future<void> _toggleAdminVisibility(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    if (viewModel.recipe == null || viewModel.isUpdatingVisibility) return;

    final nextPublished = !_isPublished;
    final actionLabel = nextPublished ? 'unhide' : 'hide';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${nextPublished ? 'Unhide' : 'Hide'} recipe?'),
        content: Text(
          nextPublished
              ? 'This recipe will become visible to users again.'
              : 'This recipe will no longer be visible to users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(nextPublished ? 'Unhide' : 'Hide'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(
        message: nextPublished ? 'Unhiding recipe...' : 'Hiding recipe...',
      ),
    );
    final success = await viewModel.updateVisibility(
      isPublished: nextPublished,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      setState(() => _isPublished = nextPublished);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Recipe ${nextPublished ? 'unhidden' : 'hidden'}.'
                : viewModel.communityActionErrorMessage ??
                      'Unable to $actionLabel recipe.',
          ),
        ),
      );
  }

  Future<void> _markAdminReviewed(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    if (viewModel.recipe == null || viewModel.isUpdatingVisibility) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: 'Marking reviewed...'),
    );
    final success = await viewModel.markAsReviewed();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Recipe marked as reviewed.'
                : viewModel.communityActionErrorMessage ??
                      'Unable to mark recipe as reviewed.',
          ),
        ),
      );
  }

  /// Shows an over-target confirmation dialog.
  Future<bool?> _showOverTargetDialog(MealCalorieGuidance guidance) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Calorie target exceeded'),
        content: Text(
          'This meal exceeds your daily target by '
          '${guidance.exceededByCalories ?? 0} ${guidance.calorieUnit}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose another'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreRecipeDetailViewModel>();
    // Checks if the recipe is already added to the meal plan in selection mode.
    final alreadyAdded =
        widget.mealPlanSelection?.existingRecipeIds.contains(
          viewModel.recipe?.id ?? '',
        ) ??
        false;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Recipe Details',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
        actions: [
          if (widget.isAdminModeration)
            PopupMenuButton<String>(
              tooltip: 'Moderation actions',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'reviewed') {
                  _markAdminReviewed(viewModel);
                } else {
                  _toggleAdminVisibility(viewModel);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _isPublished ? 'hide' : 'unhide',
                  child: Text(_isPublished ? 'Hide recipe' : 'Unhide recipe'),
                ),
                const PopupMenuItem(
                  value: 'reviewed',
                  child: Text('Mark as reviewed'),
                ),
              ],
            )
          else
            IconButton(
              tooltip: 'Add to meal plan',
              onPressed: viewModel.recipe == null || viewModel.isSavingMealPlan
                  ? null
                  : () => _openMealPlanCalendar(viewModel),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          if (widget.showLibraryActions)
            IconButton(
              tooltip: 'Edit recipe',
              onPressed: viewModel.recipe == null
                  ? null
                  : () => _openRecipeReview(viewModel),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _DetailBody(
        viewModel: viewModel,
        tabController: _tabController,
        onTabSelected: _selectDetailTab,
        onComingSoonTap: _showComingSoonMessage,
        onPlanMeal: () => _openMealPlanCalendar(viewModel),
        showLibraryActions: widget.showLibraryActions,
        isPublished: _isPublished,
        isAdminModeration: widget.isAdminModeration,
        onFavouriteTap: () => _toggleFavourite(viewModel),
        isMealPlanSelection: widget.mealPlanSelection != null,
        mealPlanSelection: widget.mealPlanSelection,
      ),
      // Shows a bottom action button when in meal plan selection mode.
      bottomNavigationBar: widget.mealPlanSelection == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PrimaryButton(
                  text: alreadyAdded
                      ? 'Already Added'
                      : viewModel.isSavingMealPlan
                      ? 'Adding...'
                      : 'Select',
                  onPressed:
                      viewModel.recipe == null ||
                          viewModel.isSavingMealPlan ||
                          alreadyAdded
                      ? null
                      : () => _selectForMealPlan(viewModel),
                ),
              ),
            ),
    );
  }
}

/// Encapsulates the data required to add a recipe to a meal plan calendar.
class _RecipeCalendarMealPlanRequest {
  final List<DateTime> dates;
  final List<AddMealCategoryOption> mealCategories;
  final double servingCount;

  const _RecipeCalendarMealPlanRequest({
    required this.dates,
    required this.mealCategories,
    required this.servingCount,
  });
}

/// Bottom sheet widget that allows users to select dates, meal categories, and servings.
class _RecipeCalendarMealPlanSheet extends StatefulWidget {
  final List<AddMealCategoryOption> categories;
  final double initialServings;

  const _RecipeCalendarMealPlanSheet({
    required this.categories,
    required this.initialServings,
  });

  @override
  State<_RecipeCalendarMealPlanSheet> createState() =>
      _RecipeCalendarMealPlanSheetState();
}

class _RecipeCalendarMealPlanSheetState
    extends State<_RecipeCalendarMealPlanSheet> {
  late DateTime _focusedDate;
  late double _servings;
  final Set<String> _selectedCategoryIds = {};
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    // Sets today as the default focused date and selected date.
    final today = _dateOnly(DateTime.now());
    _focusedDate = today;
    _selectedDates.add(today);
    // Selects a preferred initial category (breakfast if available).
    _selectedCategoryIds.add(_preferredInitialCategory(_categories).id);
    _servings = MealServingAmount.normalize(widget.initialServings);
  }

  // Returns the list of categories, falling back to defaults if empty.
  List<AddMealCategoryOption> get _categories {
    return widget.categories.isEmpty
        ? RecipeDetailMealPlanDefaults.categories
        : widget.categories;
  }

  // Toggles a date in the selected dates set.
  void _toggleDate(DateTime date) {
    final normalized = _dateOnly(date);
    setState(() {
      if (_selectedDates.contains(normalized)) {
        _selectedDates.remove(normalized);
      } else {
        _selectedDates.add(normalized);
      }
    });
  }

  // Toggles a meal category in the selected categories set.
  void _toggleCategory(AddMealCategoryOption category) {
    setState(() {
      if (_selectedCategoryIds.contains(category.id)) {
        _selectedCategoryIds.remove(category.id);
      } else {
        _selectedCategoryIds.add(category.id);
      }
    });
  }

  // Submits the selection and returns the request to the parent widget.
  void _submit() {
    if (_selectedDates.isEmpty || _selectedCategoryIds.isEmpty) return;
    final dates = _selectedDates.toList()..sort();
    final categories = _categories
        .where((category) => _selectedCategoryIds.contains(category.id))
        .toList();
    Navigator.of(context).pop(
      _RecipeCalendarMealPlanRequest(
        dates: dates,
        mealCategories: categories,
        servingCount: _servings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final today = _dateOnly(DateTime.now());
    final firstDate = DateTime(today.year - 1, today.month, today.day);
    final lastDate = DateTime(today.year + 2, today.month, today.day);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle indicator at the top of the sheet.
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header row with title and close button.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add to meal plan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Meal type selection section with filter chips.
              Text('Meal type', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final selected = _selectedCategoryIds.contains(category.id);
                  return FilterChip(
                    label: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.secondary.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: selected ? AppColors.secondary : AppColors.border,
                    ),
                    onSelected: (_) => _toggleCategory(category),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Selection count summary.
              Text(
                _selectedCategoryIds.isEmpty
                    ? 'Select one or more meal types.'
                    : _selectedCategoryIds.length == 1
                    ? '1 meal type selected'
                    : '${_selectedCategoryIds.length} meal types selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Date selection section with calendar picker.
              Text('Dates', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CalendarDatePicker(
                  initialDate: _focusedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  currentDate: today,
                  onDateChanged: (date) {
                    _focusedDate = _dateOnly(date);
                    _toggleDate(date);
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Displays selected dates as removable chips.
              _SelectedDateChips(
                dates: _selectedDates.toList()..sort(),
                onRemove: _toggleDate,
              ),
              const SizedBox(height: 16),
              // Serving count adjustment section.
              Text('Servings', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Decrease servings',
                      onPressed: _servings <= MealServingAmount.min
                          ? null
                          : () => setState(
                              () => _servings = MealServingAmount.stepDown(
                                _servings,
                              ),
                            ),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        MealServingAmount.format(_servings),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase servings',
                      onPressed: _servings >= MealServingAmount.max
                          ? null
                          : () => setState(
                              () => _servings = MealServingAmount.stepUp(
                                _servings,
                              ),
                            ),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons: cancel and submit.
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _selectedDates.isEmpty || _selectedCategoryIds.isEmpty
                          ? null
                          : _submit,
                      child: const Text('Add meal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Selects a preferred initial category, defaulting to breakfast if available.
  static AddMealCategoryOption _preferredInitialCategory(
    List<AddMealCategoryOption> categories,
  ) {
    return categories.firstWhere(
      (category) => category.id.toLowerCase() == 'breakfast',
      orElse: () => categories.first,
    );
  }
}

/// Displays selected dates as removable chips for visual feedback.
class _SelectedDateChips extends StatelessWidget {
  final List<DateTime> dates;
  final ValueChanged<DateTime> onRemove;

  const _SelectedDateChips({required this.dates, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return Text('Select one or more dates.', style: context.text.bodySmall);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map((date) {
        return InputChip(
          label: Text(_dateLabel(date)),
          onDeleted: () => onRemove(date),
        );
      }).toList(),
    );
  }
}

/// Builds the main scrollable body of the recipe detail page with tabs.
class _DetailBody extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final TabController tabController;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final VoidCallback onFavouriteTap;
  final bool showLibraryActions;
  final bool isPublished;
  final bool isAdminModeration;
  final bool isMealPlanSelection;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _DetailBody({
    required this.viewModel,
    required this.tabController,
    required this.onTabSelected,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.onFavouriteTap,
    required this.showLibraryActions,
    required this.isPublished,
    required this.isAdminModeration,
    required this.isMealPlanSelection,
    required this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Shows a loading indicator while the recipe is being fetched.
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipe...', inline: true);
    }

    final error = viewModel.errorMessage;
    final recipe = viewModel.recipe;
    // Displays an error message if the recipe failed to load.
    if (error != null || recipe == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error ?? 'Recipe unavailable',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ),
      );
    }

    final selectedIndex = ExploreRecipeDetailTab.values.indexOf(
      viewModel.selectedTab,
    );

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _HeroImage(recipe: recipe)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _RecipeHeader(
              recipe: recipe,
              isPublished: isPublished,
              onFavouriteTap: onFavouriteTap,
              showFavourite: !isAdminModeration,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _TopTabs(
            tabController: tabController,
            onTabSelected: onTabSelected,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          sliver: SliverToBoxAdapter(
            child: _AutoSizingDetailTabView(
              selectedIndex: selectedIndex,
              onPageChanged: (index) {
                if (tabController.index != index) {
                  tabController.animateTo(index);
                }
                onTabSelected(index);
              },
              children: ExploreRecipeDetailTab.values.map((tab) {
                return _SelectedTabContent(
                  tab: tab,
                  viewModel: viewModel,
                  recipe: recipe,
                  onComingSoonTap: onComingSoonTap,
                  onPlanMeal: onPlanMeal,
                  isPublished: isPublished,
                  isAdminModeration: isAdminModeration,
                  showPlanMeal: !isMealPlanSelection && !isAdminModeration,
                  mealPlanSelection: mealPlanSelection,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays the recipe hero image with a page view for multiple images.
class _HeroImage extends StatefulWidget {
  final ExploreRecipe recipe;

  const _HeroImage({required this.recipe});

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipeImages = widget.recipe.imagePaths;
    // Falls back to a single image if no image list is provided.
    final images = recipeImages == null || recipeImages.isEmpty
        ? <String>[widget.recipe.imagePath]
        : recipeImages;

    return Stack(
      children: [
        ColoredBox(
          color: colors.surfaceContainerHighest,
          child: AspectRatio(
            aspectRatio: 1.55,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showRecipeMediaDialog(context, images[index]),
                  child: AppRecipeMedia(
                    mediaPath: images[index],
                    fit: BoxFit.contain,
                    showVideoControls: isRecipeVideoPath(images[index]),
                    allowFullscreen: isRecipeVideoPath(images[index]),
                  ),
                );
              },
            ),
          ),
        ),
        // Image counter badge displayed on top of the hero image.
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${images.length}',
              style: context.text.titleSmall?.copyWith(
                color: colors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays the recipe title, author, publication info, and key metrics.
class _RecipeHeader extends StatelessWidget {
  final ExploreRecipe recipe;
  final bool isPublished;
  final VoidCallback onFavouriteTap;
  final bool showFavourite;

  const _RecipeHeader({
    required this.recipe,
    required this.isPublished,
    required this.onFavouriteTap,
    required this.showFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with favourite button.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
            ),
            if (showFavourite) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: recipe.isFavourite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onPressed: onFavouriteTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  recipe.isFavourite ? Icons.favorite : Icons.favorite_border,
                  size: 26,
                  color: recipe.isFavourite ? AppColors.favourite : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Author and publication date.
        Text(
          'By ${recipe.author} - ${recipe.publishedAtLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        // Metrics grid: time, difficulty, servings, rating.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.75,
          children: [
            _MetricTile(
              icon: Icons.schedule,
              color: context.colors.primary,
              title: recipe.totalTime,
              subtitle: 'Time',
            ),
            _MetricTile(
              icon: Icons.restaurant_menu,
              color: AppColors.error,
              title: recipe.difficulty,
              subtitle: 'Difficulty',
            ),
            _MetricTile(
              icon: Icons.groups_2_outlined,
              color: AppColors.primary,
              title: recipe.servings.toString(),
              subtitle: recipe.servings == 1 ? 'Serving' : 'Servings',
            ),
            _MetricTile(
              icon: Icons.star,
              color: AppColors.secondary,
              title: isPublished
                  ? recipe.rating.toStringAsFixed(1)
                  : 'No rating',
              subtitle: 'Rating',
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual metric tile displaying an icon, value, and label.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the tab bar for switching between recipe, nutrition, and community views.
class _TopTabs extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<int> onTabSelected;

  const _TopTabs({required this.tabController, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      controller: tabController,
      tabs: ExploreRecipeDetailTab.values.map(_detailTabLabel).toList(),
      margin: const EdgeInsets.only(top: 12),
      isScrollable: false,
      onTap: onTabSelected,
    );
  }
}

/// Manages the height of tab content dynamically using a page view.
class _AutoSizingDetailTabView extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const _AutoSizingDetailTabView({
    required this.selectedIndex,
    required this.onPageChanged,
    required this.children,
  });

  @override
  State<_AutoSizingDetailTabView> createState() =>
      _AutoSizingDetailTabViewState();
}

class _AutoSizingDetailTabViewState extends State<_AutoSizingDetailTabView> {
  late final PageController _pageController;
  // Caches measured heights for each tab content.
  final Map<int, double> _heights = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _pageController = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant _AutoSizingDetailTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == _currentIndex) return;

    _currentIndex = widget.selectedIndex;
    // Animates to the selected page when the index changes externally.
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height =
        _heights[_currentIndex] ??
        (_heights.isEmpty ? 1.0 : _heights.values.first);

    // Animates height changes smoothly when tab content changes.
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        child: PageView.builder(
          controller: _pageController,
          clipBehavior: Clip.none,
          itemCount: widget.children.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            widget.onPageChanged(index);
          },
          itemBuilder: (context, index) {
            return OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: _MeasureSize(
                onChange: (size) {
                  // Updates the cached height only when it changes.
                  if (size.height <= 0 || _heights[index] == size.height) {
                    return;
                  }
                  setState(() => _heights[index] = size.height);
                },
                child: widget.children[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Measures the size of its child widget and reports changes.
class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.child, required this.onChange});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    // Reports the size after the frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      final size = renderObject.size;
      if (_oldSize == size) return;
      _oldSize = size;
      widget.onChange(size);
    });

    return widget.child;
  }
}

/// Selects and builds the appropriate tab content based on the current tab.
class _SelectedTabContent extends StatelessWidget {
  final ExploreRecipeDetailTab tab;
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;
  final bool isPublished;
  final bool isAdminModeration;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _SelectedTabContent({
    required this.tab,
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.isPublished,
    required this.isAdminModeration,
    required this.showPlanMeal,
    required this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case ExploreRecipeDetailTab.recipe:
        return _RecipeTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
          onPlanMeal: onPlanMeal,
          showPlanMeal: showPlanMeal,
          calorieGuidance: mealPlanSelection == null
              ? null
              : MealCalorieGuidanceService().evaluate(
                  budget: mealPlanSelection!.calorieBudget,
                  mealCalories: MealServingAmount.scaledCalories(
                    recipeCalories: recipe.nutrition.calories,
                    recipeServings: recipe.servings,
                    plannedServings:
                        mealPlanSelection!.normalizedPlannedServings,
                  ),
                ),
        );
      case ExploreRecipeDetailTab.nutrition:
        return _NutritionTab(recipe: recipe, onServingTap: onComingSoonTap);
      case ExploreRecipeDetailTab.community:
        return _CommunityTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
          isPublished: isPublished,
          isAdminModeration: isAdminModeration,
        );
    }
  }
}

// Converts a tab enum to its display label.
String _detailTabLabel(ExploreRecipeDetailTab tab) {
  switch (tab) {
    case ExploreRecipeDetailTab.recipe:
      return 'Recipe';
    case ExploreRecipeDetailTab.nutrition:
      return 'Nutrition';
    case ExploreRecipeDetailTab.community:
      return 'Community';
  }
}

// Normalizes a DateTime to date-only format (ignores time).
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// Formats a date as a readable string (e.g., "Jan 1, 2023").
String _dateLabel(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
