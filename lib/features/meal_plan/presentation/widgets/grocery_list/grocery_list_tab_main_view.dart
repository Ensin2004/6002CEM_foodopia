import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';

/// Main view for the Grocery List tab in the meal plan page.
/// Displays weekly and custom grocery lists with search and filtering.
class GroceryListTabMainView extends StatelessWidget {
  /// List of grocery list summaries.
  final List<GroceryListSummary> lists;

  /// Creates a new grocery list tab main view instance.
  const GroceryListTabMainView({super.key, required this.lists});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Get filtered lists.
    final weeklyLists = viewModel.filteredWeeklyHistory;
    final customLists = viewModel.filteredCustomGroceryLists;

    // Check if active tab is selected.
    final isActiveTab =
        viewModel.selectedGroceryListTab == GroceryListTabFilter.active;

    return Stack(
      children: [
        // Main content with refresh indicator.
        RefreshIndicator(
          onRefresh: viewModel.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              104,
            ),
            children: [
              // Tab selector.
              AppPillSegmentedControl(
                labels: const ['Active', 'Past'],
                selectedIndex:
                    viewModel.selectedGroceryListTab ==
                        GroceryListTabFilter.active
                    ? 0
                    : 1,
                onChanged: (index) =>
                    context.read<MealPlanViewModel>().selectGroceryListTab(
                      index == 0
                          ? GroceryListTabFilter.active
                          : GroceryListTabFilter.past,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search row.
              const _GrocerySearchRow(),
              const SizedBox(height: AppSpacing.md),

              // Tip box.
              const _GroceryTipBox(),
              const SizedBox(height: AppSpacing.md),

              // Weekly start day control.
              _WeeklyStartDayControl(
                weekStartDay:
                    viewModel.currentWeeklyGroceryList?.weekStartDay ??
                    'monday',
              ),
              const SizedBox(height: AppSpacing.md),

              // Weekly lists section.
              if (weeklyLists.isNotEmpty) ...[
                _SectionHeader(
                  title: isActiveTab ? 'Weekly Groceries' : 'Weekly History',
                ),
                const SizedBox(height: AppSpacing.sm),
                ...weeklyLists.map(
                  (list) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _WeeklyGroceriesCard(list: list),
                  ),
                ),
              ],

              // Custom lists section.
              if (customLists.isNotEmpty) ...[
                const _SectionHeader(title: 'Custom Lists'),
                const SizedBox(height: AppSpacing.sm),
                ...customLists.map(
                  (list) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _GroceryListCard(list: list),
                  ),
                ),
              ],

              // Empty state.
              if (weeklyLists.isEmpty && customLists.isEmpty)
                const _EmptyGroceryLists(),
            ],
          ),
        ),

        // Add button.
        const Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
          child: _AddGroceryListButton(),
        ),
      ],
    );
  }
}

/// Weekly grocery week-start setting.
class _WeeklyStartDayControl extends StatelessWidget {
  /// Current week start day value.
  final String weekStartDay;

  /// Creates a new weekly start day control.
  const _WeeklyStartDayControl({required this.weekStartDay});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final normalized = weekStartDay.toLowerCase() == 'sunday'
        ? 'sunday'
        : 'monday';
    final selectedIndex = normalized == 'sunday' ? 1 : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_view_week_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Grocery Starts',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applies to auto weekly grocery lists only.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppPillSegmentedControl(
            labels: const ['Monday', 'Sunday'],
            selectedIndex: selectedIndex,
            onChanged: viewModel.isUpdatingWeeklyGroceryWeekStartDay
                ? (_) {}
                : (index) {
                    final nextValue = index == 1 ? 'sunday' : 'monday';
                    if (nextValue == normalized) return;
                    _confirmWeekStartChange(context, nextValue);
                  },
          ),
          if (viewModel.isUpdatingWeeklyGroceryWeekStartDay) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Updating weekly grocery list...',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmWeekStartChange(
    BuildContext context,
    String nextValue,
  ) async {
    final nextLabel = _weekStartLabel(nextValue);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Start weekly groceries on $nextLabel?'),
        content: Text(
          'Your current weekly grocery list will be synced to the new week range. '
          'Past grocery lists and custom grocery lists will stay unchanged.',
          style: context.text.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final viewModel = context.read<MealPlanViewModel>();
    await viewModel.updateWeeklyGroceryWeekStartDay(nextValue);

    if (!context.mounted) return;

    final message = viewModel.groceryActionErrorMessage == null
        ? 'Weekly grocery start day updated.'
        : viewModel.groceryActionErrorMessage!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Section header widget.
class _SectionHeader extends StatelessWidget {
  /// Title of the section.
  final String title;

  /// Creates a new section header instance.
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

/// Weekly groceries card widget.
class _WeeklyGroceriesCard extends StatelessWidget {
  /// The grocery list summary.
  final GroceryListSummary list;

  /// Creates a new weekly groceries card instance.
  const _WeeklyGroceriesCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0FAF2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          // Get the view model.
          final viewModel = context.read<MealPlanViewModel>();

          // Navigate to manage grocery list.
          await context.push(
            AppRouter.manageGroceryList,
            extra: ManageGroceryListArgs(listId: list.id),
          );

          // Reload after returning so date/status edits are reflected.
          if (context.mounted) {
            await viewModel.loadDashboard();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Icon container.
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // List details.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            list.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const _DefaultBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${list.itemCount} items',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 5),
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
                            _formatDateRange(list.startDate, list.endDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Week starts ${_weekStartLabel(list.weekStartDay)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grocery search row widget.
class _GrocerySearchRow extends StatefulWidget {
  /// Creates a new grocery search row instance.
  const _GrocerySearchRow();

  @override
  State<_GrocerySearchRow> createState() => _GrocerySearchRowState();
}

/// State for the grocery search row.
class _GrocerySearchRowState extends State<_GrocerySearchRow> {
  /// Text controller for the search input.
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize with the current search query.
    _controller = TextEditingController(
      text: context.read<MealPlanViewModel>().grocerySearchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final query = context.watch<MealPlanViewModel>().grocerySearchQuery;

    // Sync controller with view model.
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field.
        TextField(
          controller: _controller,
          onChanged: context.read<MealPlanViewModel>().updateGrocerySearchQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search name, category, date...',
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary.withValues(alpha: 0.45),
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: context
                        .read<MealPlanViewModel>()
                        .clearGrocerySearchQuery,
                    icon: const Icon(Icons.close, size: 18),
                  ),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Formats a date range for display.
String _formatDateRange(DateTime start, DateTime end) {
  final startText = DateFormat('d MMM').format(start);
  final endText = DateFormat('d MMM yyyy').format(end);
  return '$startText - $endText';
}

/// Returns a human-readable week start label.
String _weekStartLabel(String value) {
  return value.toLowerCase() == 'sunday' ? 'Sunday' : 'Monday';
}

/// Grocery tip box widget.
class _GroceryTipBox extends StatelessWidget {
  /// Creates a new grocery tip box instance.
  const _GroceryTipBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create lists for different occasions and manage your shopping easily.',
                  style: context.text.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grocery list card widget.
class _GroceryListCard extends StatelessWidget {
  /// The grocery list summary.
  final GroceryListSummary list;

  /// Creates a new grocery list card instance.
  const _GroceryListCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            // Get the view model.
            final viewModel = context.read<MealPlanViewModel>();

            // Navigate to manage grocery list.
            await context.push(
              AppRouter.manageGroceryList,
              extra: ManageGroceryListArgs(listId: list.id),
            );

            // Reload after returning so date/status edits are reflected.
            if (context.mounted) {
              await viewModel.loadDashboard();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Icon container.
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F7E4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // List details.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              list.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (list.isDefault) const _DefaultBadge(),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${list.itemCount} items',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 5),
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
                              _formatDateRange(list.startDate, list.endDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Category icons.
                      Row(
                        children: [
                          const Spacer(),
                          ...list.categories
                              .take(3)
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _CategoryIcon(category: category),
                                ),
                              ),
                          if (list.extraCategoryCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _ExtraBadge(
                                count: list.extraCategoryCount,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formats a date range for display.
  String _formatDateRange(DateTime start, DateTime end) {
    final startText = DateFormat('d MMM').format(start);
    final endText = DateFormat('d MMM yyyy').format(end);
    return '$startText - $endText';
  }
}

/// Default badge widget.
class _DefaultBadge extends StatelessWidget {
  /// Creates a new default badge instance.
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Default',
        style: context.text.bodySmall?.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Category icon widget.
class _CategoryIcon extends StatelessWidget {
  /// Category name.
  final String category;

  /// Creates a new category icon instance.
  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    return Icon(_iconForCategory(category), size: 16, color: AppColors.primary);
  }

  /// Returns an icon for a category.
  IconData _iconForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('meat')) return Icons.set_meal_outlined;
    if (normalized.contains('dairy')) return Icons.local_drink_outlined;
    if (normalized.contains('drink')) return Icons.local_bar_outlined;
    if (normalized.contains('snack')) return Icons.cookie_outlined;
    if (normalized.contains('bakery')) return Icons.bakery_dining_outlined;
    return Icons.eco_outlined;
  }
}

/// Extra badge widget.
class _ExtraBadge extends StatelessWidget {
  /// Number of extra categories.
  final int count;

  /// Creates a new extra badge instance.
  const _ExtraBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F8EB),
        shape: BoxShape.circle,
      ),
      child: Text(
        '+$count',
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Add grocery list button widget.
class _AddGroceryListButton extends StatelessWidget {
  /// Creates a new add grocery list button instance.
  const _AddGroceryListButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Get the view model.
          final viewModel = context.read<MealPlanViewModel>();

          // Navigate to add grocery list.
          final result = await context.push(
            AppRouter.addGroceryList,
            extra: AddGroceryListArgs(userId: viewModel.userId),
          );

          // Reload dashboard if a list was created.
          if (result != null && context.mounted) {
            await context.read<MealPlanViewModel>().loadDashboard();
          }
        },
        icon: const Icon(Icons.calendar_month, size: 20),
        label: Text(
          'Add Grocery List',
          style: context.text.labelLarge?.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.secondary.withValues(alpha: 0.32),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

/// Empty grocery lists state widget.
class _EmptyGroceryLists extends StatelessWidget {
  /// Creates a new empty grocery lists instance.
  const _EmptyGroceryLists();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 140),
          const SizedBox(height: AppSpacing.md),
          Text('No grocery lists here yet', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
