import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/usecases/create_grocery_list_usecase.dart';
import '../../domain/usecases/get_add_grocery_list_plan_usecase.dart';
import '../viewmodel/add_grocery_list_viewmodel.dart';

/// Page for creating a new grocery list.
/// Provides a two-step wizard for configuring list details and selecting meals.
class AddGroceryListPage extends StatelessWidget {
  /// User ID of the current user.
  final String userId;

  /// Creates a new add grocery list page instance.
  const AddGroceryListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => AddGroceryListViewModel(
        userId: userId,
        getPlanUseCase: sl<GetAddGroceryListPlanUseCase>(),
        createGroceryListUseCase: sl<CreateGroceryListUseCase>(),
      ),
      child: const _AddGroceryListView(),
    );
  }
}

/// Internal view for the add grocery list page.
class _AddGroceryListView extends StatefulWidget {
  /// Creates a new add grocery list view instance.
  const _AddGroceryListView();

  @override
  State<_AddGroceryListView> createState() => _AddGroceryListViewState();
}

/// State for the add grocery list view.
class _AddGroceryListViewState extends State<_AddGroceryListView> {
  /// Text controller for the list name input.
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    // Show loading dialog while plan is loading.
    if (viewModel.isLoading && viewModel.plan == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery setup...'),
      );
    }

    // Get the plan.
    final plan = viewModel.plan;

    // Show error state if plan is null.
    if (plan == null) {
      return Scaffold(
        appBar: _AddGroceryAppBar(onBack: () => context.pop()),
        body: _ErrorState(
          message: viewModel.errorMessage ?? 'Unable to load grocery setup',
          onRetry: viewModel.loadPlan,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _AddGroceryAppBar(
        onBack: () {
          if (viewModel.currentStep == 2) {
            // Go back to previous step.
            context.read<AddGroceryListViewModel>().goToPreviousStep();
          } else {
            // Pop the page.
            context.pop();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: AppStepProgressBar(
                totalSteps: 2,
                currentStep: viewModel.currentStep,
                labels: const ['Basic Information', 'Select Meals'],
              ),
            ),
            // Dynamic step content.
            Expanded(
              child: viewModel.currentStep == 1
                  ? _BasicInfoStep(plan: plan, nameController: _nameController)
                  : const _SelectMealsStep(),
            ),
          ],
        ),
      ),
    );
  }
}

/// App bar for the add grocery list page.
class _AddGroceryAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Callback when back button is pressed.
  final VoidCallback onBack;

  /// Creates a new add grocery app bar instance.
  const _AddGroceryAppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'Add Grocery List',
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.chevron_left),
      ),
    );
  }
}

/// Step 1: Basic information step.
class _BasicInfoStep extends StatelessWidget {
  /// The grocery list plan.
  final AddGroceryListPlan plan;

  /// Text controller for list name.
  final TextEditingController nameController;

  /// Creates a new basic info step instance.
  const _BasicInfoStep({required this.plan, required this.nameController});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        // Icon selection.
        Text('List Icon', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _IconPicker(options: plan.iconOptions),
        const SizedBox(height: AppSpacing.lg),

        // List name input.
        Text('List Name', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: nameController,
          onChanged: context.read<AddGroceryListViewModel>().updateListName,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: 'e.g. Weekly Groceries',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${viewModel.listName.length}/50',
            style: context.text.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date range selection.
        Text('Date Range', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _DateRangeSelector(
          startDate: viewModel.startDate,
          endDate: viewModel.endDate,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Selection summary.
        _SelectionSummaryBox(
          title: '${viewModel.selectedDayCount} days selected',
          subtitle: _formatDateRange(viewModel.startDate, viewModel.endDate),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Exclude days selection.
        Text('Exclude Days (Optional)', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ExcludeDayChips(days: viewModel.dateRangeDays),
        const SizedBox(height: AppSpacing.sm),

        // Excluded days summary.
        _SelectionSummaryBox(
          title:
          '${viewModel.excludedDays.length} day${viewModel.excludedDays.length == 1 ? '' : 's'} selected',
          subtitle: viewModel.excludedDays.isEmpty
              ? 'No excluded days'
              : viewModel.excludedDays
              .map((date) => DateFormat('EEE, d MMM').format(date))
              .join(', '),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Next button.
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: viewModel.canContinue
                ? context.read<AddGroceryListViewModel>().goToNextStep
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'Next',
              style: context.text.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon picker widget.
class _IconPicker extends StatelessWidget {
  /// List of icon options.
  final List<GroceryIconOption> options;

  /// Creates a new icon picker instance.
  const _IconPicker({required this.options});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final selected = viewModel.selectedIconIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: InkWell(
                onTap: () =>
                    context.read<AddGroceryListViewModel>().selectIcon(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE3F7E7) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Icon(option.icon, color: AppColors.primary, size: 21),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Date range selector widget.
class _DateRangeSelector extends StatelessWidget {
  /// Start date.
  final DateTime startDate;

  /// End date.
  final DateTime endDate;

  /// Creates a new date range selector instance.
  const _DateRangeSelector({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateBox(
            label: 'Start Date',
            date: startDate,
            onTap: () => _pickDateRange(context),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('-'),
        ),
        Expanded(
          child: _DateBox(
            label: 'End Date',
            date: endDate,
            onTap: () => _pickDateRange(context),
          ),
        ),
      ],
    );
  }

  /// Opens the date range picker dialog.
  Future<void> _pickDateRange(BuildContext context) async {
    // Get the view model.
    final viewModel = context.read<AddGroceryListViewModel>();

    // Show date range picker.
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: viewModel.startDate,
        end: viewModel.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    // Update the date range if picked.
    if (picked != null && context.mounted) {
      context.read<AddGroceryListViewModel>().updateDateRange(
        picked.start,
        picked.end,
      );
    }
  }
}

/// Date box widget.
class _DateBox extends StatelessWidget {
  /// Label text.
  final String label;

  /// Date to display.
  final DateTime date;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Creates a new date box instance.
  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: context.text.bodySmall)),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Selection summary box widget.
class _SelectionSummaryBox extends StatelessWidget {
  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Creates a new selection summary box instance.
  const _SelectionSummaryBox({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECB3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Exclude day chips widget.
class _ExcludeDayChips extends StatelessWidget {
  /// List of days in the date range.
  final List<DateTime> days;

  /// Creates a new exclude day chips instance.
  const _ExcludeDayChips({required this.days});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((date) {
          final excluded = viewModel.isDayExcluded(date);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: InkWell(
              onTap: () => context
                  .read<AddGroceryListViewModel>()
                  .toggleExcludedDay(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: excluded ? const Color(0xFFE3F7E7) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: excluded ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: context.text.bodySmall?.copyWith(
                        color: excluded
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM').format(date),
                      style: context.text.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Step 2: Select meals step.
class _SelectMealsStep extends StatelessWidget {
  /// Creates a new select meals step instance.
  const _SelectMealsStep();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    // Get the selected day and meal days.
    final selectedDay = viewModel.selectedMealDay;
    final mealDays = viewModel.visibleMealDays;

    return Column(
      children: [
        // Day selector horizontal list.
        SizedBox(
          height: 76,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final day = mealDays[index];
              return _MealDayCard(date: day.date);
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemCount: mealDays.length,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Selected day content.
        if (selectedDay == null)
          const Expanded(child: _EmptyMealsForSelection())
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                // Error message if any.
                if (viewModel.saveErrorMessage != null) ...[
                  _InlineError(message: viewModel.saveErrorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Selected date header.
                _SelectedMealDateHeader(
                  date: selectedDay.date,
                  mealCount: selectedDay.sections.fold<int>(
                    0,
                        (count, section) => count + section.meals.length,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Meal sections.
                ...selectedDay.sections.map(
                      (section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _SelectableMealSection(section: section),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Create button.
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: viewModel.canCreate
                        ? () async {
                      final listId = await context
                          .read<AddGroceryListViewModel>()
                          .createGroceryList();
                      if (listId != null && context.mounted) {
                        context.pop(listId);
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Text(
                      viewModel.isSaving
                          ? 'Creating...'
                          : 'Create Grocery List',
                      style: context.text.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Inline error message widget.
class _InlineError extends StatelessWidget {
  /// Error message.
  final String message;

  /// Creates a new inline error instance.
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(color: Colors.red.shade700),
      ),
    );
  }
}

/// Meal day card widget.
class _MealDayCard extends StatelessWidget {
  /// Date of the day.
  final DateTime date;

  /// Creates a new meal day card instance.
  const _MealDayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    // Check if this day is selected.
    final selected =
        viewModel.selectedMealDate.year == date.year &&
            viewModel.selectedMealDate.month == date.month &&
            viewModel.selectedMealDate.day == date.day;

    return InkWell(
      onTap: () => context.read<AddGroceryListViewModel>().selectMealDate(date),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F7E7) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: context.text.bodySmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              DateFormat('d MMM').format(date),
              style: context.text.bodySmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selected meal date header widget.
class _SelectedMealDateHeader extends StatelessWidget {
  /// Selected date.
  final DateTime date;

  /// Number of meals on this date.
  final int mealCount;

  /// Creates a new selected meal date header instance.
  const _SelectedMealDateHeader({required this.date, required this.mealCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFE0F7E4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(date),
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              '$mealCount meals planned',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Selectable meal section widget.
class _SelectableMealSection extends StatelessWidget {
  /// The meal section.
  final GroceryMealSectionPlan section;

  /// Creates a new selectable meal section instance.
  const _SelectableMealSection({required this.section});

  @override
  Widget build(BuildContext context) {
    // Determine meal label.
    final mealLabel = section.meals.length == 1
        ? '1 meal'
        : '${section.meals.length} meals';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        collapsedShape: const Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        title: Text(section.title, style: context.text.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mealLabel,
              style: context.text.labelLarge?.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
        children: section.meals
            .map((meal) => _SelectableMealRow(meal: meal))
            .toList(),
      ),
    );
  }
}

/// Selectable meal row widget.
class _SelectableMealRow extends StatelessWidget {
  /// The meal item.
  final GroceryMealPlanItem meal;

  /// Creates a new selectable meal row instance.
  const _SelectableMealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    // Check if meal is selected.
    final selected = viewModel.isMealSelected(meal.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _MealImage(path: meal.imagePath, width: 48, height: 48),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              meal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: selected,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (_) =>
                context.read<AddGroceryListViewModel>().toggleMeal(meal.id),
          ),
        ],
      ),
    );
  }
}

/// Meal image widget.
class _MealImage extends StatelessWidget {
  /// Image path (asset or URL).
  final String path;

  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Creates a new meal image instance.
  const _MealImage({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the path is a remote URL.
    final isRemote = path.startsWith('http://') || path.startsWith('https://');

    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(width: width, height: height),
      );
    }

    // Load from assets.
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _ImageFallback(width: width, height: height),
    );
  }
}

/// Image fallback widget.
class _ImageFallback extends StatelessWidget {
  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Creates a new image fallback instance.
  const _ImageFallback({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE8F8EB),
      child: const Icon(Icons.restaurant, color: AppColors.primary),
    );
  }
}

/// Empty meals for selection widget.
class _EmptyMealsForSelection extends StatelessWidget {
  /// Creates a new empty meals for selection instance.
  const _EmptyMealsForSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/images/empty_page.png', height: 140),
    );
  }
}

/// Error state widget.
class _ErrorState extends StatelessWidget {
  /// Error message.
  final String message;

  /// Callback when retry is pressed.
  final Future<void> Function() onRetry;

  /// Creates a new error state instance.
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Formats a date range for display.
String _formatDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
}