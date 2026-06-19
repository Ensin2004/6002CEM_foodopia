import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/theme_extension.dart';
import '../../../../domain/entities/add_grocery_list_plan.dart';
import '../../../viewmodel/grocery/add_grocery_list_viewmodel.dart';

/// Second step in the add grocery flow.
class AddGrocerySelectMealsStep extends StatelessWidget {
  /// Creates the select meals step.
  const AddGrocerySelectMealsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddGroceryListViewModel>();
    final selectedDay = viewModel.selectedMealDay;
    final mealDays = viewModel.visibleMealDays;

    return Column(
      children: [
        // Date selector.
        SizedBox(
          height: 76,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final day = mealDays[index];
              return _AddGroceryMealDayCard(date: day.date);
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemCount: mealDays.length,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Selected date meal sections.
        if (selectedDay == null)
          const Expanded(child: _AddGroceryEmptyMealsForSelection())
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
                if (viewModel.saveErrorMessage != null) ...[
                  _AddGroceryInlineError(message: viewModel.saveErrorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _AddGrocerySelectedMealDateHeader(
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
                    child: _AddGrocerySelectableMealSection(section: section),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _CreateGroceryListButton(viewModel: viewModel),
              ],
            ),
          ),
      ],
    );
  }
}

/// Create grocery list action button.
class _CreateGroceryListButton extends StatelessWidget {
  /// View model used for create state.
  final AddGroceryListViewModel viewModel;

  /// Creates the create action button.
  const _CreateGroceryListButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text(
          viewModel.isSaving ? 'Creating...' : 'Create Grocery List',
          style: context.text.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Inline error message for create failures.
class _AddGroceryInlineError extends StatelessWidget {
  /// Error message.
  final String message;

  /// Creates the inline error.
  const _AddGroceryInlineError({required this.message});

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

/// Day chip for meal selection.
class _AddGroceryMealDayCard extends StatelessWidget {
  /// Date represented by the chip.
  final DateTime date;

  /// Creates the meal day card.
  const _AddGroceryMealDayCard({required this.date});

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

/// Header for the selected meal date.
class _AddGrocerySelectedMealDateHeader extends StatelessWidget {
  /// Selected date.
  final DateTime date;

  /// Number of planned meals.
  final int mealCount;

  /// Creates the selected meal date header.
  const _AddGrocerySelectedMealDateHeader({
    required this.date,
    required this.mealCount,
  });

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

/// Expandable section for selectable meals.
class _AddGrocerySelectableMealSection extends StatelessWidget {
  /// Meal section.
  final GroceryMealSectionPlan section;

  /// Creates the selectable meal section.
  const _AddGrocerySelectableMealSection({required this.section});

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
            .map((meal) => _AddGrocerySelectableMealRow(meal: meal))
            .toList(),
      ),
    );
  }
}

/// Selectable row for one planned meal.
class _AddGrocerySelectableMealRow extends StatelessWidget {
  /// Meal item.
  final GroceryMealPlanItem meal;

  /// Creates the selectable meal row.
  const _AddGrocerySelectableMealRow({required this.meal});

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
            child: _AddGroceryMealImage(
              path: meal.imagePath,
              width: 48,
              height: 48,
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

/// Meal thumbnail with asset and network support.
class _AddGroceryMealImage extends StatelessWidget {
  /// Image path.
  final String path;

  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Creates the meal image.
  const _AddGroceryMealImage({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isRemote = path.startsWith('http://') || path.startsWith('https://');

    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _AddGroceryImageFallback(width: width, height: height),
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _AddGroceryImageFallback(width: width, height: height),
    );
  }
}

/// Fallback shown when meal image loading fails.
class _AddGroceryImageFallback extends StatelessWidget {
  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Creates the image fallback.
  const _AddGroceryImageFallback({required this.width, required this.height});

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

/// Empty state shown when no date can be selected.
class _AddGroceryEmptyMealsForSelection extends StatelessWidget {
  /// Creates the empty meals state.
  const _AddGroceryEmptyMealsForSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/images/empty_page.png', height: 140),
    );
  }
}
