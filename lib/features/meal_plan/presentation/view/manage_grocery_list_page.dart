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
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
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
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7E4),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(
              Icons.shopping_basket,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GROCERY LIST NAME',
                  style: context.text.bodySmall?.copyWith(fontSize: 9),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit grocery list',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showEditListDialog(context, detail),
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _HeaderMetric(
                      icon: Icons.shopping_cart_outlined,
                      value: '${detail.itemCount} items',
                      label: 'Across ${detail.categoryCount} categories',
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _HeaderMetric(
                      icon: Icons.restaurant,
                      value: '${detail.mealCount} meals',
                      label: _shortDateRange(detail.startDate, detail.endDate),
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

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(fontSize: 9),
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
            Text(
              'View Plan',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: detail.upcomingMeals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _UpcomingMealCard(meal: detail.upcomingMeals[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...detail.categories.map(
          (category) => _GroceryCategoryCard(category: category),
        ),
      ],
    );
  }
}

class _UpcomingMealCard extends StatelessWidget {
  final ManageUpcomingMeal meal;

  const _UpcomingMealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _MealImage(path: meal.imagePath, width: 64, height: 86),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormat('d MMM').format(meal.date),
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meal.mealType,
                  style: context.text.bodySmall?.copyWith(fontSize: 10),
                ),
                Text(
                  meal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: ExpansionTile(
        initiallyExpanded: category.title == 'Dairy',
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
        title: Text(category.title, style: context.text.titleMedium),
        trailing: Text(
          '${visibleItems.length} items',
          style: context.text.labelLarge?.copyWith(color: AppColors.primary),
        ),
        children: visibleItems
            .map((item) => _GroceryItemRow(item: item))
            .toList(),
      ),
    );
  }
}

class _GroceryItemRow extends StatelessWidget {
  final ManageGroceryItem item;

  const _GroceryItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageGroceryListViewModel>();
    final bought = viewModel.isBought(item.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 8),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: context.text.bodyLarge),
                Text(
                  item.quantityLabel,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: bought,
            activeColor: AppColors.primary,
            onChanged: (_) => context
                .read<ManageGroceryListViewModel>()
                .toggleBought(item.id),
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
                          ...meal.ingredients.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: _TimelineIngredient(item: item),
                            ),
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
                                onPressed: () {},
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

class _MealImage extends StatelessWidget {
  final String path;
  final double width;
  final double height;

  const _MealImage({
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
            _ImageFallback(width: width, height: height),
      );
    }
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
        Text(item.emoji),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(item.name, style: context.text.bodySmall)),
        Text(item.quantityLabel, style: context.text.bodySmall),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.delete_outline, size: 16),
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
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 88,
          height: 44,
          child: ElevatedButton(
            onPressed: () {},
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
