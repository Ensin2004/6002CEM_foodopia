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
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../../meal_plan/domain/usecases/save_recipe_meal_plan_usecase.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_recipe_detail_viewmodel.dart';

part 'explore_recipe_detail_recipe_tab.dart';
part 'explore_recipe_detail_nutrition_tab.dart';
part 'explore_recipe_detail_community_tab.dart';

class ExploreRecipeDetailPage extends StatelessWidget {
  final String recipeId;
  final bool showLibraryActions;
  final bool isPublished;
  final MealPlanSelectionArgs? mealPlanSelection;

  const ExploreRecipeDetailPage({
    super.key,
    required this.recipeId,
    this.showLibraryActions = false,
    this.isPublished = true,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
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
        toggleFavouriteUseCase: sl(),
        saveRecipeMealPlanUseCase: sl<SaveRecipeMealPlanUseCase>(),
      ),
      child: _ExploreRecipeDetailView(
        showLibraryActions: showLibraryActions,
        isPublished: isPublished,
        mealPlanSelection: mealPlanSelection,
      ),
    );
  }
}

class _ExploreRecipeDetailView extends StatefulWidget {
  final bool showLibraryActions;
  final bool isPublished;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _ExploreRecipeDetailView({
    required this.showLibraryActions,
    required this.isPublished,
    this.mealPlanSelection,
  });

  @override
  State<_ExploreRecipeDetailView> createState() =>
      _ExploreRecipeDetailViewState();
}

class _ExploreRecipeDetailViewState extends State<_ExploreRecipeDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreRecipeDetailTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    _selectDetailTab(_tabController.index);
  }

  void _selectDetailTab(int index) {
    context.read<ExploreRecipeDetailViewModel>().selectTab(
      ExploreRecipeDetailTab.values[index],
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _openAddMealPlan() {
    context.push(
      AppRouter.addMealPlan,
      extra: AddMealPlanArgs(
        mealType: 'Breakfast',
        mealCategoryId: 'breakfast',
        selectedDate: DateTime.now(),
      ),
    );
  }

  void _openRecipeReview(ExploreRecipeDetailViewModel viewModel) {
    final recipeId = viewModel.recipe?.id;
    if (recipeId == null || recipeId.isEmpty) return;

    context.push(
      AppRouter.addRecipeReview,
      extra: AddRecipeReviewArgs(recipeId: recipeId),
    );
  }

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

  Future<void> _selectForMealPlan(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    final selection = widget.mealPlanSelection;
    if (selection == null) return;
    final recipeId = viewModel.recipe?.id;
    if (recipeId != null && selection.existingRecipeIds.contains(recipeId)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This recipe is already added.')),
        );
      return;
    }

    final success = await viewModel.saveToMealPlan(
      userId: selection.userId,
      date: selection.selectedDate,
      mealCategory: AddMealCategoryOption(
        id: selection.mealCategoryId,
        name: selection.mealCategoryName,
      ),
      source: selection.source,
    );
    if (!mounted) return;

    final message = success
        ? 'Meal plan added.'
        : viewModel.communityActionErrorMessage ?? 'Unable to add meal plan.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (!success) return;

    context.go(
      AppRouter.mealPlan,
      extra: MealPlanArgs(initialTabIndex: 0, userId: selection.userId),
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
        actions: widget.showLibraryActions
            ? [
                IconButton(
                  tooltip: 'Edit recipe',
                  onPressed: viewModel.recipe == null
                      ? null
                      : () => _openRecipeReview(viewModel),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ]
            : null,
      ),
      body: _DetailBody(
        viewModel: viewModel,
        tabController: _tabController,
        onTabSelected: _selectDetailTab,
        onComingSoonTap: _showComingSoonMessage,
        onPlanMeal: _openAddMealPlan,
        showLibraryActions: widget.showLibraryActions,
        isPublished: widget.isPublished,
        onFavouriteTap: () => _toggleFavourite(viewModel),
        isMealPlanSelection: widget.mealPlanSelection != null,
      ),
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

class _DetailBody extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final TabController tabController;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final VoidCallback onFavouriteTap;
  final bool showLibraryActions;
  final bool isPublished;
  final bool isMealPlanSelection;

  const _DetailBody({
    required this.viewModel,
    required this.tabController,
    required this.onTabSelected,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.onFavouriteTap,
    required this.showLibraryActions,
    required this.isPublished,
    required this.isMealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipe...', inline: true);
    }

    final error = viewModel.errorMessage;
    final recipe = viewModel.recipe;
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
                  showPlanMeal: !isMealPlanSelection,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

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

class _RecipeHeader extends StatelessWidget {
  final ExploreRecipe recipe;
  final bool isPublished;
  final VoidCallback onFavouriteTap;

  const _RecipeHeader({
    required this.recipe,
    required this.isPublished,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            const SizedBox(width: 8),
            IconButton(
              tooltip: recipe.isFavourite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              onPressed: onFavouriteTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 42, height: 42),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                recipe.isFavourite ? Icons.favorite : Icons.favorite_border,
                size: 26,
                color: recipe.isFavourite ? AppColors.favourite : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'By ${recipe.author} - ${recipe.publishedAtLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
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

class _TopTabs extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<int> onTabSelected;

  const _TopTabs({
    required this.tabController,
    required this.onTabSelected,
  });

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
    final height = _heights[_currentIndex] ??
        (_heights.isEmpty ? 1.0 : _heights.values.first);

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

class _SelectedTabContent extends StatelessWidget {
  final ExploreRecipeDetailTab tab;
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;
  final bool isPublished;

  const _SelectedTabContent({
    required this.tab,
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.isPublished,
    required this.showPlanMeal,
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
        );
      case ExploreRecipeDetailTab.nutrition:
        return _NutritionTab(recipe: recipe, onServingTap: onComingSoonTap);
      case ExploreRecipeDetailTab.community:
        return _CommunityTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
          isPublished: isPublished,
        );
    }
  }
}

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
