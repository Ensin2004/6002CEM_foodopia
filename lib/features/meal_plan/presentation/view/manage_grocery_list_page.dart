import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/usecases/add_grocery_item_usecase.dart';
import '../../domain/usecases/delete_grocery_item_usecase.dart';
import '../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../domain/usecases/update_grocery_item_bought_usecase.dart';
import '../../domain/usecases/update_grocery_list_usecase.dart';
import '../viewmodel/manage_grocery_list_viewmodel.dart';

/// Page for managing an existing grocery list.
/// Provides list view and timeline view modes with item management.
class ManageGroceryListPage extends StatelessWidget {
  /// ID of the grocery list to manage.
  final String listId;

  /// Creates a new manage grocery list page instance.
  const ManageGroceryListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => ManageGroceryListViewModel(
        listId: listId,
        getDetailUseCase: sl<GetManageGroceryListDetailUseCase>(),
        addGroceryItemUseCase: sl<AddGroceryItemUseCase>(),
        deleteGroceryItemUseCase: sl<DeleteGroceryItemUseCase>(),
        updateItemBoughtUseCase: sl<UpdateGroceryItemBoughtUseCase>(),
        updateGroceryListUseCase: sl<UpdateGroceryListUseCase>(),
      ),
      child: const _ManageGroceryListView(),
    );
  }
}

/// Internal view for the manage grocery list page.
class _ManageGroceryListView extends StatelessWidget {
  /// Creates a new manage grocery list view instance.
  const _ManageGroceryListView();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Show loading dialog while detail is loading.
    if (viewModel.isLoading && viewModel.detail == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery list...'),
      );
    }

    // Get the detail.
    final detail = viewModel.detail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Manage Grocery List',
        leading: IconButton(
          onPressed: () => context.pop(viewModel.hasSavedChanges),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: detail == null
          ? _ErrorState(
        message: viewModel.errorMessage ?? 'Unable to load grocery list',
        onRetry: viewModel.loadDetail,
      )
          : _ManageContent(detail: detail),
    );
  }
}

/// Main content widget for the manage grocery list page.
class _ManageContent extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new manage content instance.
  const _ManageContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return Stack(
      children: [
        // Main scrollable content.
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            88,
          ),
          children: [
            // Header card with summary metrics.
            _HeaderCard(detail: detail),
            const SizedBox(height: AppSpacing.lg),

            // View mode tabs.
            const _ViewModeTabs(),
            const SizedBox(height: AppSpacing.xl),

            // Dynamic content based on view mode.
            if (viewModel.viewMode == ManageGroceryViewMode.list)
              _ListMode(detail: detail)
            else
              _TimelineMode(detail: detail),

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InlineActionError(message: viewModel.actionErrorMessage!),
            ],
          ],
        ),

        // Bottom bar based on view mode.
        if (viewModel.viewMode == ManageGroceryViewMode.list)
          const Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _AddIngredientBar(),
          )
        else
          const Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _HideBoughtBar(),
          ),
      ],
    );
  }
}

/// Header card with grocery list summary.
class _HeaderCard extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new header card instance.
  const _HeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and edit button.
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7E4),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grocery list',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Edit grocery list',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(38, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showEditListDialog(context, detail),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics row.
          Row(
            children: [
              _HeaderMetric(
                icon: Icons.shopping_cart_outlined,
                value: '${detail.itemCount}',
                label: 'Items',
                sublabel: '${detail.categoryCount} categories',
              ),
              _HeaderDivider(),
              _HeaderMetric(
                icon: Icons.restaurant_outlined,
                value: '${detail.mealCount}',
                label: 'Meals',
                sublabel: _shortDateRange(detail.startDate, detail.endDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Divider between header metrics.
class _HeaderDivider extends StatelessWidget {
  /// Creates a new header divider instance.
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.primary.withValues(alpha: 0.14),
    );
  }
}

/// Shows the edit grocery list dialog.
Future<void> _showEditListDialog(
    BuildContext context,
    ManageGroceryListDetail detail,
    ) async {
  await showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ManageGroceryListViewModel>(),
      child: _EditGroceryListDialog(detail: detail),
    ),
  );
}

/// Edit grocery list dialog.
class _EditGroceryListDialog extends StatefulWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new edit grocery list dialog instance.
  const _EditGroceryListDialog({required this.detail});

  @override
  State<_EditGroceryListDialog> createState() => _EditGroceryListDialogState();
}

/// State for the edit grocery list dialog.
class _EditGroceryListDialogState extends State<_EditGroceryListDialog> {
  /// Controller for the list name input.
  late final TextEditingController _nameController;

  /// Start date.
  late DateTime _startDate;

  /// End date.
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.title);
    _startDate = widget.detail.startDate;
    _endDate = widget.detail.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Edit Grocery List', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name input.
            Text('List Name', style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'e.g. Weekly Groceries',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date range picker.
            Text('Date Range', style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _shortDateRange(_startDate, _endDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                viewModel.actionErrorMessage!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: viewModel.isSaving ? null : _saveChanges,
          child: Text(viewModel.isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  /// Opens the date range picker.
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    // Update state if picked.
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  /// Saves the changes.
  Future<void> _saveChanges() async {
    final saved = await context.read<ManageGroceryListViewModel>().updateList(
      name: _nameController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Add grocery item dialog.
class _AddGroceryItemDialog extends StatefulWidget {
  /// Related meal plan IDs.
  final List<String> relatedMealPlanIds;

  /// Creates a new add grocery item dialog instance.
  const _AddGroceryItemDialog({this.relatedMealPlanIds = const []});

  @override
  State<_AddGroceryItemDialog> createState() => _AddGroceryItemDialogState();
}

/// State for the add grocery item dialog.
class _AddGroceryItemDialogState extends State<_AddGroceryItemDialog> {
  /// Controller for ingredient name.
  late final TextEditingController _nameController;

  /// Controller for quantity.
  late final TextEditingController _amountController;

  /// Controller for unit.
  late final TextEditingController _unitController;

  /// Controller for category.
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _unitController = TextEditingController();
    _categoryController = TextEditingController(text: 'Uncategorized');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Add Ingredient', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ingredient name.
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ingredient name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quantity and unit row.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Category.
            TextField(
              controller: _categoryController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                viewModel.actionErrorMessage!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: viewModel.isSaving ? null : _saveItem,
          child: Text(viewModel.isSaving ? 'Adding...' : 'Add'),
        ),
      ],
    );
  }

  /// Saves the new item.
  Future<void> _saveItem() async {
    final saved = await context.read<ManageGroceryListViewModel>().addItem(
      name: _nameController.text,
      amountText: _amountController.text,
      unit: _unitController.text,
      categoryName: _categoryController.text,
      relatedMealPlanIds: widget.relatedMealPlanIds,
    );
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Shows the add ingredient dialog.
Future<void> _showAddIngredientDialog(
    BuildContext context, {
      List<String> relatedMealPlanIds = const [],
    }) async {
  await showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ManageGroceryListViewModel>(),
      child: _AddGroceryItemDialog(relatedMealPlanIds: relatedMealPlanIds),
    ),
  );
}

/// Inline action error widget.
class _InlineActionError extends StatelessWidget {
  /// Error message.
  final String message;

  /// Creates a new inline action error instance.
  const _InlineActionError({required this.message});

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

/// Header metric widget.
class _HeaderMetric extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Value text.
  final String value;

  /// Label text.
  final String label;

  /// Sublabel text.
  final String sublabel;

  /// Creates a new header metric instance.
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// View mode tabs widget.
class _ViewModeTabs extends StatelessWidget {
  /// Creates a new view mode tabs instance.
  const _ViewModeTabs();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AppPillSegmentedControl(
      labels: const ['List', 'Timeline'],
      selectedIndex: viewModel.viewMode == ManageGroceryViewMode.list ? 0 : 1,
      onChanged: (index) =>
          context.read<ManageGroceryListViewModel>().setViewMode(
            index == 0
                ? ManageGroceryViewMode.list
                : ManageGroceryViewMode.timeline,
          ),
    );
  }
}

/// List view mode widget.
class _ListMode extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new list mode instance.
  const _ListMode({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upcoming meals header.
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming Meals (${DateFormat('d MMM').format(detail.startDate)} - ${DateFormat('d MMM').format(detail.endDate)})',
                style: context.text.titleMedium,
              ),
            ),
            InkWell(
              onTap: () => context.push(
                AppRouter.mealPlan,
                extra: const MealPlanArgs(initialTabIndex: 0),
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'View Plan',
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Upcoming meals carousel.
        _UpcomingMealsCarousel(meals: detail.upcomingMeals),
        const SizedBox(height: AppSpacing.xl),

        // Grocery categories.
        ...detail.categories.map(
              (category) => _GroceryCategoryCard(category: category),
        ),
      ],
    );
  }
}

/// Upcoming meals carousel widget.
class _UpcomingMealsCarousel extends StatelessWidget {
  /// List of upcoming meals.
  final List<ManageUpcomingMeal> meals;

  /// Creates a new upcoming meals carousel instance.
  const _UpcomingMealsCarousel({required this.meals});

  @override
  Widget build(BuildContext context) {
    // Show empty state if no meals.
    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No meals are linked to this grocery list yet.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // Build carousel with responsive card width.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact cards reduce image letterboxing while staying readable.
        final cardWidth = (constraints.maxWidth * 0.52).clamp(172.0, 202.0);
        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _UpcomingMealCard(meal: meals[index], width: cardWidth),
          ),
        );
      },
    );
  }
}

/// Upcoming meal card widget.
class _UpcomingMealCard extends StatelessWidget {
  /// The meal data.
  final ManageUpcomingMeal meal;

  /// Card width.
  final double width;

  /// Creates a new upcoming meal card instance.
  const _UpcomingMealCard({required this.meal, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Meal image.
              Container(
                width: 88,
                height: double.infinity,
                padding: const EdgeInsets.all(5),
                color: const Color(0xFFF6F7F6),
                child: _MealImage(
                  path: meal.imagePath,
                  width: 78,
                  height: 94,
                  fit: BoxFit.contain,
                ),
              ),
              // Meal details.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MealPill(
                        icon: Icons.calendar_today,
                        label: DateFormat('d MMM').format(meal.date),
                      ),
                      Text(
                        meal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _MealPill(
                        icon: _mealTypeIcon(meal.mealType),
                        label: meal.mealType,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the icon for a meal type.
  IconData _mealTypeIcon(String mealType) {
    final value = mealType.toLowerCase();
    if (value.contains('breakfast')) return Icons.wb_sunny_outlined;
    if (value.contains('lunch')) return Icons.wb_twilight_outlined;
    if (value.contains('dinner')) return Icons.nights_stay_outlined;
    return Icons.restaurant_outlined;
  }
}

/// Meal pill widget.
class _MealPill extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Creates a new meal pill instance.
  const _MealPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns an icon for an ingredient category.
IconData _ingredientCategoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('dairy') || value.contains('drink')) {
    return Icons.local_drink_outlined;
  }
  if (value.contains('meat') ||
      value.contains('protein') ||
      value.contains('seafood')) {
    return Icons.set_meal_outlined;
  }
  if (value.contains('bakery') ||
      value.contains('bread') ||
      value.contains('grain')) {
    return Icons.bakery_dining_outlined;
  }
  if (value.contains('snack')) return Icons.cookie_outlined;
  if (value.contains('spice') || value.contains('sauce')) {
    return Icons.soup_kitchen_outlined;
  }
  if (value.contains('frozen')) return Icons.ac_unit_outlined;
  return Icons.eco_outlined;
}

/// Grocery category card widget.
class _GroceryCategoryCard extends StatelessWidget {
  /// The category data.
  final ManageGroceryCategory category;

  /// Creates a new grocery category card instance.
  const _GroceryCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Filter visible items.
    final visibleItems = category.items
        .where((item) => viewModel.shouldShowItem(item.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFFBFCFB),
        collapsedBackgroundColor: const Color(0xFFFBFCFB),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _ingredientCategoryIcon(category.title),
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        trailing: _CountBadge(
          label:
          '${visibleItems.length} item${visibleItems.length == 1 ? '' : 's'}',
        ),
        children: visibleItems.asMap().entries.map((entry) {
          return _GroceryItemRow(
            item: entry.value,
            showDivider: entry.key < visibleItems.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

/// Grocery item row widget.
class _GroceryItemRow extends StatelessWidget {
  /// The item data.
  final ManageGroceryItem item;

  /// Whether to show a divider.
  final bool showDivider;

  /// Creates a new grocery item row instance.
  const _GroceryItemRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if item is bought.
    final bought = viewModel.isBought(item.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: showDivider
            ? Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.65),
          ),
        )
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 7, 4, 7),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: bought,
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => context
                  .read<ManageGroceryListViewModel>()
                  .toggleBought(item.id),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Opacity(
              opacity: bought ? 0.55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                      decoration: bought ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.quantityLabel.trim().isNotEmpty)
                    Text(
                      item.quantityLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Delete ingredient',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: viewModel.isSaving
                ? null
                : () => context.read<ManageGroceryListViewModel>().deleteItem(
              item.id,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Timeline view mode widget.
class _TimelineMode extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new timeline mode instance.
  const _TimelineMode({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: detail.timelineDays
          .map((day) => _TimelineDay(day: day))
          .toList(),
    );
  }
}

/// Timeline day widget.
class _TimelineDay extends StatelessWidget {
  /// The day data.
  final ManageGroceryTimelineDay day;

  /// Creates a new timeline day instance.
  const _TimelineDay({required this.day});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if day is expanded.
    final isExpanded = viewModel.isTimelineDayExpanded(day.date);

    // Count total ingredients.
    final itemCount = day.meals.fold<int>(
      0,
          (count, meal) => count + meal.ingredients.length,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline vertical line.
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F7E4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(child: Container(width: 1, color: AppColors.border)),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Day content.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context
                              .read<ManageGroceryListViewModel>()
                              .toggleTimelineDay(day.date),
                          child: Text(
                            '${DateFormat('EEEE, d MMM').format(day.date)} (Day ${day.dayNumber})',
                            style: context.text.titleMedium,
                          ),
                        ),
                      ),
                      _CountBadge(label: '$itemCount items'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context
                            .read<ManageGroceryListViewModel>()
                            .toggleTimelineDay(day.date),
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: AppSpacing.md),
                    ...day.meals.asMap().entries.map(
                          (entry) => _TimelineMeal(
                        date: day.date,
                        meal: entry.value,
                        isLast: entry.key == day.meals.length - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline meal widget.
class _TimelineMeal extends StatelessWidget {
  /// Date of the meal.
  final DateTime date;

  /// The meal data.
  final ManageGroceryTimelineMeal meal;

  /// Whether this is the last meal.
  final bool isLast;

  /// Creates a new timeline meal instance.
  const _TimelineMeal({
    required this.date,
    required this.meal,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if meal is expanded.
    final isExpanded = viewModel.isTimelineMealExpanded(
      date,
      meal.mealType,
      meal.title,
    );

    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal timeline dot.
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meal.mealType == 'Breakfast'
                          ? Icons.wb_sunny
                          : Icons.nightlight,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(child: Container(width: 1, color: AppColors.border)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Meal content.
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => context
                        .read<ManageGroceryListViewModel>()
                        .toggleTimelineMeal(date, meal.mealType, meal.title),
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    meal.mealType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _CountBadge(
                            label: '${meal.ingredients.length} items',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Meal card.
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => context
                              .read<ManageGroceryListViewModel>()
                              .toggleTimelineMeal(
                            date,
                            meal.mealType,
                            meal.title,
                          ),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _MealImage(
                                    path: meal.imagePath,
                                    width: 48,
                                    height: 48,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    meal.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          _GroupedTimelineIngredients(
                            ingredients: meal.ingredients,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.md,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 30,
                              child: OutlinedButton(
                                onPressed: () => _showAddIngredientDialog(
                                  context,
                                  relatedMealPlanIds: [meal.mealPlanId],
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '+ Add Ingredient',
                                  style: context.text.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped timeline ingredients widget.
class _GroupedTimelineIngredients extends StatelessWidget {
  /// List of ingredients.
  final List<ManageGroceryItem> ingredients;

  /// Creates a new grouped timeline ingredients instance.
  const _GroupedTimelineIngredients({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Group ingredients by category.
    final grouped = <String, _TimelineIngredientGroup>{};
    for (final item in ingredients) {
      if (!viewModel.shouldShowItem(item.id)) continue;
      final key = item.categoryId.isEmpty ? item.categoryName : item.categoryId;
      grouped
          .putIfAbsent(
        key,
            () => _TimelineIngredientGroup(title: item.categoryName),
      )
          .items
          .add(item);
    }

    // Sort categories.
    final categories = grouped.values.toList()
      ..sort((first, second) => first.title.compareTo(second.title));

    return Column(
      children: categories
          .map(
            (group) => _TimelineIngredientCategory(
          title: group.title,
          ingredients: group.items,
        ),
      )
          .toList(),
    );
  }
}

/// Timeline ingredient group data class.
class _TimelineIngredientGroup {
  /// Category title.
  final String title;

  /// List of ingredients.
  final List<ManageGroceryItem> items = [];

  /// Creates a new timeline ingredient group instance.
  _TimelineIngredientGroup({required this.title});
}

/// Timeline ingredient category widget.
class _TimelineIngredientCategory extends StatelessWidget {
  /// Category title.
  final String title;

  /// List of ingredients.
  final List<ManageGroceryItem> ingredients;

  /// Creates a new timeline ingredient category instance.
  const _TimelineIngredientCategory({
    required this.title,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _ingredientCategoryIcon(title),
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(label: '${ingredients.length} items'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...ingredients.map((item) => _TimelineIngredient(item: item)),
        ],
      ),
    );
  }
}

/// Meal image widget.
class _MealImage extends StatelessWidget {
  /// Image path.
  final String path;

  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Image fit.
  final BoxFit fit;

  /// Creates a new meal image instance.
  const _MealImage({
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Shared media preview handles both recipe image and video paths.
    return SizedBox(
      width: width,
      height: height,
      child: AppRecipeMediaPreview(
        mediaPath: path,
        fit: fit,
        playOverlaySize: width < 60 ? 30 : 38,
        playIconSize: width < 60 ? 20 : 26,
      ),
    );
  }
}

/// Timeline ingredient widget.
class _TimelineIngredient extends StatelessWidget {
  /// The ingredient item.
  final ManageGroceryItem item;

  /// Creates a new timeline ingredient instance.
  const _TimelineIngredient({required this.item});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Skip if item should be hidden.
    if (!viewModel.shouldShowItem(item.id)) return const SizedBox.shrink();

    return Row(
      children: [
        Checkbox(
          value: viewModel.isBought(item.id),
          onChanged: (_) =>
              context.read<ManageGroceryListViewModel>().toggleBought(item.id),
        ),
        Expanded(child: Text(item.name, style: context.text.bodySmall)),
        Text(item.quantityLabel, style: context.text.bodySmall),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Delete ingredient',
          visualDensity: VisualDensity.compact,
          onPressed: viewModel.isSaving
              ? null
              : () => context.read<ManageGroceryListViewModel>().deleteItem(
            item.id,
          ),
          icon: const Icon(Icons.delete_outline, size: 16),
        ),
      ],
    );
  }
}

/// Count badge widget.
class _CountBadge extends StatelessWidget {
  /// Label text.
  final String label;

  /// Creates a new count badge instance.
  const _CountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Add ingredient bar widget.
class _AddIngredientBar extends StatelessWidget {
  /// Creates a new add ingredient bar instance.
  const _AddIngredientBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showAddIngredientDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Add Ingredient', style: context.text.bodyMedium),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 88,
          height: 44,
          child: ElevatedButton(
            onPressed: () => _showAddIngredientDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}

/// Hide bought items bar widget.
class _HideBoughtBar extends StatelessWidget {
  /// Creates a new hide bought bar instance.
  const _HideBoughtBar();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hide bought items', style: context.text.bodyMedium),
                Text(
                  'Checked items will be hidden',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: viewModel.hideBoughtItems,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: context
                .read<ManageGroceryListViewModel>()
                .toggleHideBoughtItems,
          ),
        ],
      ),
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

/// Formats a short date range.
String _shortDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
}