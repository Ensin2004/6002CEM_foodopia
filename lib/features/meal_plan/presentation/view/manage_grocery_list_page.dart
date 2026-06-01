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
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/usecases/add_grocery_item_usecase.dart';
import '../../domain/usecases/delete_grocery_item_usecase.dart';
import '../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../domain/usecases/update_grocery_item_bought_usecase.dart';
import '../../domain/usecases/update_grocery_list_usecase.dart';
import '../viewmodel/manage_grocery_list_viewmodel.dart';

class ManageGroceryListPage extends StatelessWidget {
  final String listId;

  const ManageGroceryListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
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

class _ManageGroceryListView extends StatelessWidget {
  const _ManageGroceryListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();

    if (viewModel.isLoading && viewModel.detail == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery list...'),
      );
    }

    final detail = viewModel.detail;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Manage Grocery List',
        leading: IconButton(
          onPressed: () => context.pop(),
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

class _ManageContent extends StatelessWidget {
  final ManageGroceryListDetail detail;

  const _ManageContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            88,
          ),
          children: [
            _HeaderCard(detail: detail),
            const SizedBox(height: AppSpacing.lg),
            const _ViewModeTabs(),
            const SizedBox(height: AppSpacing.xl),
            if (viewModel.viewMode == ManageGroceryViewMode.list)
              _ListMode(detail: detail)
            else
              _TimelineMode(detail: detail),
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InlineActionError(message: viewModel.actionErrorMessage!),
            ],
          ],
        ),
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

class _HeaderCard extends StatelessWidget {
  final ManageGroceryListDetail detail;

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

class _HeaderDivider extends StatelessWidget {
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

class _EditGroceryListDialog extends StatefulWidget {
  final ManageGroceryListDetail detail;

  const _EditGroceryListDialog({required this.detail});

  @override
  State<_EditGroceryListDialog> createState() => _EditGroceryListDialogState();
}

class _EditGroceryListDialogState extends State<_EditGroceryListDialog> {
  late final TextEditingController _nameController;
  late DateTime _startDate;
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
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Edit Grocery List', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
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

class _AddGroceryItemDialog extends StatefulWidget {
  final List<String> relatedMealPlanIds;

  const _AddGroceryItemDialog({this.relatedMealPlanIds = const []});

  @override
  State<_AddGroceryItemDialog> createState() => _AddGroceryItemDialogState();
}

class _AddGroceryItemDialogState extends State<_AddGroceryItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;
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
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Add Ingredient', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ingredient name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
            TextField(
              controller: _categoryController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
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

class _InlineActionError extends StatelessWidget {
  final String message;

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

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;

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

class _ViewModeTabs extends StatelessWidget {
  const _ViewModeTabs();

  @override
  Widget build(BuildContext context) {
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

class _ListMode extends StatelessWidget {
  final ManageGroceryListDetail detail;

  const _ListMode({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _UpcomingMealsCarousel(meals: detail.upcomingMeals),
        const SizedBox(height: AppSpacing.xl),
        ...detail.categories.map(
          (category) => _GroceryCategoryCard(category: category),
        ),
      ],
    );
  }
}

class _UpcomingMealsCarousel extends StatelessWidget {
  final List<ManageUpcomingMeal> meals;

  const _UpcomingMealsCarousel({required this.meals});

  @override
  Widget build(BuildContext context) {
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

class _UpcomingMealCard extends StatelessWidget {
  final ManageUpcomingMeal meal;
  final double width;

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

  IconData _mealTypeIcon(String mealType) {
    final value = mealType.toLowerCase();
    if (value.contains('breakfast')) return Icons.wb_sunny_outlined;
    if (value.contains('lunch')) return Icons.wb_twilight_outlined;
    if (value.contains('dinner')) return Icons.nights_stay_outlined;
    return Icons.restaurant_outlined;
  }
}

class _MealPill extends StatelessWidget {
  final IconData icon;
  final String label;

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

class _GroceryCategoryCard extends StatelessWidget {
  final ManageGroceryCategory category;

  const _GroceryCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
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

class _GroceryItemRow extends StatelessWidget {
  final ManageGroceryItem item;
  final bool showDivider;

  const _GroceryItemRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
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

class _TimelineMode extends StatelessWidget {
  final ManageGroceryListDetail detail;

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

class _TimelineDay extends StatelessWidget {
  final ManageGroceryTimelineDay day;

  const _TimelineDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
    final isExpanded = viewModel.isTimelineDayExpanded(day.date);
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

class _TimelineMeal extends StatelessWidget {
  final DateTime date;
  final ManageGroceryTimelineMeal meal;
  final bool isLast;

  const _TimelineMeal({
    required this.date,
    required this.meal,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
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

class _GroupedTimelineIngredients extends StatelessWidget {
  final List<ManageGroceryItem> ingredients;

  const _GroupedTimelineIngredients({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
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

class _TimelineIngredientGroup {
  final String title;
  final List<ManageGroceryItem> items = [];

  _TimelineIngredientGroup({required this.title});
}

class _TimelineIngredientCategory extends StatelessWidget {
  final String title;
  final List<ManageGroceryItem> ingredients;

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

class _MealImage extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final BoxFit fit;

  const _MealImage({
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(width: width, height: height),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          _ImageFallback(width: width, height: height),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double width;
  final double height;

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

class _TimelineIngredient extends StatelessWidget {
  final ManageGroceryItem item;

  const _TimelineIngredient({required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
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

class _CountBadge extends StatelessWidget {
  final String label;

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

class _AddIngredientBar extends StatelessWidget {
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

class _HideBoughtBar extends StatelessWidget {
  const _HideBoughtBar();

  @override
  Widget build(BuildContext context) {
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

String _shortDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
}
