import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/theme_extension.dart';
import '../../../../domain/entities/add_grocery_list_plan.dart';
import '../../../viewmodel/grocery/add_grocery_list_viewmodel.dart';

/// First step in the add grocery flow.
class AddGroceryBasicInfoStep extends StatelessWidget {
  /// Grocery setup plan.
  final AddGroceryListPlan plan;

  /// List name text controller.
  final TextEditingController nameController;

  /// Creates the basic information step.
  const AddGroceryBasicInfoStep({
    super.key,
    required this.plan,
    required this.nameController,
  });

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
        // Icon selection section.
        Text('List Icon', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AddGroceryIconPicker(options: plan.iconOptions),
        const SizedBox(height: AppSpacing.lg),

        // List name input section.
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

        // Date range section.
        Text('Date Range', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _AddGroceryDateRangeSelector(
          startDate: viewModel.startDate,
          endDate: viewModel.endDate,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AddGrocerySelectionSummaryBox(
          title: '${viewModel.selectedDayCount} days selected',
          subtitle: _formatDateRange(viewModel.startDate, viewModel.endDate),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Excluded days section.
        Text('Exclude Days (Optional)', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'Choose an icon that represents your grocery list.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AddGroceryExcludeDayChips(days: viewModel.dateRangeDays),
        const SizedBox(height: AppSpacing.sm),
        _AddGrocerySelectionSummaryBox(
          title:
              '${viewModel.excludedDays.length} day${viewModel.excludedDays.length == 1 ? '' : 's'} selected',
          subtitle: viewModel.excludedDays.isEmpty
              ? 'No excluded days'
              : viewModel.excludedDays
                    .map((date) => DateFormat('EEE, d MMM').format(date))
                    .join(', '),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Step navigation button.
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

/// Horizontal icon picker for grocery list identity.
class _AddGroceryIconPicker extends StatelessWidget {
  /// Icon options from the setup plan.
  final List<GroceryIconOption> options;

  /// Creates the icon picker.
  const _AddGroceryIconPicker({required this.options});

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
        ],
      ),
    );
  }
}

/// Date range picker row.
class _AddGroceryDateRangeSelector extends StatelessWidget {
  /// Start date.
  final DateTime startDate;

  /// End date.
  final DateTime endDate;

  /// Creates the date range selector.
  const _AddGroceryDateRangeSelector({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AddGroceryDateBox(
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
          child: _AddGroceryDateBox(
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

    // Store selected range after the dialog closes.
    if (picked != null && context.mounted) {
      context.read<AddGroceryListViewModel>().updateDateRange(
        picked.start,
        picked.end,
      );
    }
  }
}

/// Tappable date display box.
class _AddGroceryDateBox extends StatelessWidget {
  /// Field label.
  final String label;

  /// Displayed date.
  final DateTime date;

  /// Tap callback.
  final VoidCallback onTap;

  /// Creates a date box.
  const _AddGroceryDateBox({
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

/// Highlighted summary card for selected dates.
class _AddGrocerySelectionSummaryBox extends StatelessWidget {
  /// Summary title.
  final String title;

  /// Summary subtitle.
  final String subtitle;

  /// Creates a selection summary box.
  const _AddGrocerySelectionSummaryBox({
    required this.title,
    required this.subtitle,
  });

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

/// Horizontal day chips for excluded dates.
class _AddGroceryExcludeDayChips extends StatelessWidget {
  /// Days in the selected date range.
  final List<DateTime> days;

  /// Creates the excluded day chips.
  const _AddGroceryExcludeDayChips({required this.days});

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

/// Formats a compact date range label.
String _formatDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
}
