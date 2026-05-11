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
import '../../domain/usecases/get_add_grocery_list_plan_usecase.dart';
import '../viewmodel/add_grocery_list_viewmodel.dart';

class AddGroceryListPage extends StatelessWidget {
  const AddGroceryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddGroceryListViewModel(
        getPlanUseCase: sl<GetAddGroceryListPlanUseCase>(),
      ),
      child: const _AddGroceryListView(),
    );
  }
}

class _AddGroceryListView extends StatefulWidget {
  const _AddGroceryListView();

  @override
  State<_AddGroceryListView> createState() => _AddGroceryListViewState();
}

class _AddGroceryListViewState extends State<_AddGroceryListView> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();

    if (viewModel.isLoading && viewModel.plan == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery setup...'),
      );
    }

    final plan = viewModel.plan;
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
            context.read<AddGroceryListViewModel>().goToPreviousStep();
          } else {
            context.pop();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: viewModel.currentStep == 1
                  ? _BasicInfoStep(plan: plan, nameController: _nameController)
                  : _SelectMealsStep(plan: plan),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGroceryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

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

class _BasicInfoStep extends StatelessWidget {
  final AddGroceryListPlan plan;
  final TextEditingController nameController;

  const _BasicInfoStep({required this.plan, required this.nameController});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text('List Icon', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _IconPicker(options: plan.iconOptions),
        const SizedBox(height: AppSpacing.lg),
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
        Text('Date Range', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _DateRangeSelector(
          startDate: viewModel.startDate,
          endDate: viewModel.endDate,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SelectionSummaryBox(
          title: '${viewModel.selectedDayCount} days selected',
          subtitle: _formatDateRange(viewModel.startDate, viewModel.endDate),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Exclude Days (Optional)', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ExcludeDayChips(days: viewModel.dateRangeDays),
        const SizedBox(height: AppSpacing.sm),
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

class _IconPicker extends StatelessWidget {
  final List<GroceryIconOption> options;

  const _IconPicker({required this.options});

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

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

  Future<void> _pickDateRange(BuildContext context) async {
    final viewModel = context.read<AddGroceryListViewModel>();
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

    if (picked != null && context.mounted) {
      context.read<AddGroceryListViewModel>().updateDateRange(
        picked.start,
        picked.end,
      );
    }
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

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

class _SelectionSummaryBox extends StatelessWidget {
  final String title;
  final String subtitle;

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

class _ExcludeDayChips extends StatelessWidget {
  final List<DateTime> days;

  const _ExcludeDayChips({required this.days});

  @override
  Widget build(BuildContext context) {
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

class _SelectMealsStep extends StatelessWidget {
  final AddGroceryListPlan plan;

  const _SelectMealsStep({required this.plan});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();
    final selectedDay = viewModel.selectedMealDay;

    return Column(
      children: [
        SizedBox(
          height: 76,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final day = plan.mealDays[index];
              return _MealDayCard(date: day.date);
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemCount: plan.mealDays.length,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
                _SelectedMealDateHeader(
                  date: selectedDay.date,
                  mealCount: selectedDay.sections.fold<int>(
                    0,
                    (count, section) => count + section.meals.length,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...selectedDay.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _SelectableMealSection(section: section),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Text(
                      'Create Grocery List',
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

class _MealDayCard extends StatelessWidget {
  final DateTime date;

  const _MealDayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();
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

class _SelectedMealDateHeader extends StatelessWidget {
  final DateTime date;
  final int mealCount;

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

class _SelectableMealSection extends StatelessWidget {
  final GroceryMealSectionPlan section;

  const _SelectableMealSection({required this.section});

  @override
  Widget build(BuildContext context) {
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

class _SelectableMealRow extends StatelessWidget {
  final GroceryMealPlanItem meal;

  const _SelectableMealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();
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
            child: Image.asset(
              meal.imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
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

class _EmptyMealsForSelection extends StatelessWidget {
  const _EmptyMealsForSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/images/empty_page.png', height: 140),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

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

String _formatDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
}
