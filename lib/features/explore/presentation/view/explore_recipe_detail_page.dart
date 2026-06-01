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
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreRecipeDetailTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
    _isPublished = widget.isPublished;
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<ExploreRecipeDetailViewModel>().selectTab(
      ExploreRecipeDetailTab.values[_tabController.index],
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

  Future<void> _confirmVisibilityChange(
    ExploreRecipeDetailViewModel viewModel,
  ) async {
    final nextPublished = !_isPublished;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            nextPublished ? 'Publish recipe?' : 'Make recipe private?',
          ),
          content: Text(
            nextPublished
                ? 'This recipe will be visible to other users in Explore.'
                : 'This recipe will be hidden from Explore but remain in your library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(nextPublished ? 'Publish' : 'Make Private'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(
        message: nextPublished ? 'Publishing recipe...' : 'Updating recipe...',
      ),
    );

    final success = await viewModel.updateVisibility(
      isPublished: nextPublished,
    );

    if (!mounted) return;
    rootNavigator.pop();

    if (success) {
      setState(() => _isPublished = nextPublished);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? nextPublished
                      ? 'Recipe published.'
                      : 'Recipe is now private.'
                : viewModel.communityActionErrorMessage ??
                      'Unable to update recipe visibility.',
          ),
        ),
      );
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
                  tooltip: _isPublished ? 'Make private' : 'Publish recipe',
                  onPressed: viewModel.recipe == null
                      ? null
                      : () => _confirmVisibilityChange(viewModel),
                  icon: Icon(
                    _isPublished
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
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
        onComingSoonTap: _showComingSoonMessage,
        onStartCooking: _openAddMealPlan,
        showLibraryActions: widget.showLibraryActions,
        isPublished: _isPublished,
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
  final VoidCallback onComingSoonTap;
  final VoidCallback onStartCooking;
  final VoidCallback onFavouriteTap;
  final bool showLibraryActions;
  final bool isPublished;
  final bool isMealPlanSelection;

  const _DetailBody({
    required this.viewModel,
    required this.tabController,
    required this.onComingSoonTap,
    required this.onStartCooking,
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
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
          SliverToBoxAdapter(child: _TopTabs(tabController: tabController)),
        ];
      },
      body: TabBarView(
        controller: tabController,
        children: ExploreRecipeDetailTab.values.map((tab) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _SelectedTabContent(
              tab: tab,
              viewModel: viewModel,
              recipe: recipe,
              onComingSoonTap: onComingSoonTap,
              onStartCooking: onStartCooking,
              isPublished: isPublished,
              showStartCooking: !isMealPlanSelection,
            ),
          );
        }).toList(),
      ),
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

  const _TopTabs({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      controller: tabController,
      tabs: ExploreRecipeDetailTab.values.map(_detailTabLabel).toList(),
      margin: const EdgeInsets.only(top: 12),
      isScrollable: false,
    );
  }
}

class _SelectedTabContent extends StatelessWidget {
  final ExploreRecipeDetailTab tab;
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onStartCooking;
  final bool showStartCooking;
  final bool isPublished;

  const _SelectedTabContent({
    required this.tab,
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onStartCooking,
    required this.isPublished,
    required this.showStartCooking,
  });

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case ExploreRecipeDetailTab.recipe:
        return _RecipeTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
          onStartCooking: onStartCooking,
          showStartCooking: showStartCooking,
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

class _RecipeTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onStartCooking;
  final bool showStartCooking;

  const _RecipeTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onStartCooking,
    required this.showStartCooking,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About This Recipe', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.description, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        Text('Other Names', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          recipe.otherNames.isEmpty ? 'None' : recipe.otherNames.join(', '),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Text('Category', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.category, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Allergen Info', style: textTheme.titleMedium),
            const SizedBox(width: 4),
            const Icon(Icons.warning_amber, size: 15, color: AppColors.error),
          ],
        ),
        const SizedBox(height: 6),
        Text(recipe.allergenInfo, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        AppPillSegmentedControl(
          labels: const ['Ingredients', 'Instructions'],
          selectedIndex: ExploreRecipeMethodTab.values.indexOf(
            viewModel.selectedMethodTab,
          ),
          onChanged: (index) =>
              viewModel.selectMethodTab(ExploreRecipeMethodTab.values[index]),
        ),
        const SizedBox(height: 16),
        if (viewModel.selectedMethodTab == ExploreRecipeMethodTab.ingredients)
          _IngredientsList(
            recipe: recipe,
            onStartCooking: onStartCooking,
            showStartCooking: showStartCooking,
          )
        else
          _InstructionsList(recipe: recipe),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onStartCooking;
  final bool showStartCooking;

  const _IngredientsList({
    required this.recipe,
    required this.onStartCooking,
    required this.showStartCooking,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;
    final ingredientGroups = _groupIngredientsByCategory(recipe.ingredients);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients List', style: textTheme.titleMedium),
        Text('${recipe.ingredients.length} items', style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        ...ingredientGroups.expand(
          (group) => <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                group.name,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...group.ingredients.map(
              (ingredient) => _IngredientListItem(ingredient: ingredient),
            ),
          ],
        ),
        if (showStartCooking) ...[
          const SizedBox(height: 6),
          PrimaryButton(
            onPressed: onStartCooking,
            text:
                'Start Cooking (Total Calorie: ${recipe.nutrition.calories} kcal)',
            verticalPadding: 14,
          ),
        ],
      ],
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final ExploreRecipe recipe;

  const _InstructionsList({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipe.instructionSections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...section.steps.asMap().entries.map((entry) {
                final stepIndex = entry.key;
                final step = entry.value;
                final isLast = stepIndex == section.steps.length - 1;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: stepIndex == section.steps.length - 1 ? 0 : 10,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InstructionTimelineMarker(showLine: !isLast),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _RecipeDetailThumbnail(
                                    imagePath: step.imagePath,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step.description,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InstructionTimelineMarker extends StatelessWidget {
  final bool showLine;

  const _InstructionTimelineMarker({required this.showLine});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          CircleAvatar(radius: 11, backgroundColor: colors.primary),
          if (showLine) const Expanded(child: _DottedTimelineLine()),
        ],
      ),
    );
  }
}

class _DottedTimelineLine extends StatelessWidget {
  const _DottedTimelineLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedTimelineLinePainter(color: context.colors.primary),
      child: const SizedBox(width: 1, height: double.infinity),
    );
  }
}

class _DottedTimelineLinePainter extends CustomPainter {
  final Color color;

  const _DottedTimelineLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashHeight = 3.0;
    const gap = 4.0;
    final x = size.width / 2;

    double y = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTimelineLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RecipeDetailThumbnail extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const _RecipeDetailThumbnail({
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showRecipeMediaDialog(context, imagePath),
      child: AppRemoteOrAssetImage(
        imagePath: imagePath,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

enum _NutritionSummaryMode { total, serving }

enum _IngredientMacroCategory { carbohydrates, protein, fats }

class _NutritionTab extends StatefulWidget {
  final ExploreRecipe recipe;
  final VoidCallback onServingTap;

  const _NutritionTab({required this.recipe, required this.onServingTap});

  @override
  State<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<_NutritionTab> {
  _NutritionSummaryMode _summaryMode = _NutritionSummaryMode.serving;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final recipe = widget.recipe;
    final displayNutrition = _nutritionForMode(recipe, _summaryMode);
    final totalMacroGrams =
        displayNutrition.carbsGrams +
        displayNutrition.proteinGrams +
        displayNutrition.fatGrams;
    final servings = recipe.servings <= 0 ? 1 : recipe.servings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Nutrition Summary', style: textTheme.titleMedium),
                  const Spacer(),
                  PopupMenuButton<_NutritionSummaryMode>(
                    initialValue: _summaryMode,
                    onSelected: (mode) => setState(() => _summaryMode = mode),
                    itemBuilder: (context) =>
                        _NutritionSummaryMode.values.map((mode) {
                          return PopupMenuItem(
                            value: mode,
                            child: Text(_nutritionModeLabel(mode)),
                          );
                        }).toList(),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _nutritionModeLabel(_summaryMode),
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(118),
                          painter: _MacroRingPainter(
                            carbs: displayNutrition.carbsGrams,
                            protein: displayNutrition.proteinGrams,
                            fat: displayNutrition.fatGrams,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${displayNutrition.calories}',
                              style: textTheme.headlineSmall,
                            ),
                            Text('kcal', style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _MacroRow(
                          label: 'Carbohydrate',
                          grams: displayNutrition.carbsGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.primary,
                        ),
                        _MacroRow(
                          label: 'Protein',
                          grams: displayNutrition.proteinGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.error,
                        ),
                        _MacroRow(
                          label: 'Fat',
                          grams: displayNutrition.fatGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Ingredients Breakdown', style: textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              _IngredientMacroPager(
                key: ValueKey(_summaryMode),
                ingredients: recipe.ingredients,
                totalNutrition: displayNutrition,
                servings: servings,
                summaryMode: _summaryMode,
                onSeeAll: (category, totalGrams) =>
                    _showIngredientBreakdownDialog(
                      context,
                      category,
                      totalGrams,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIngredientBreakdownDialog(
    BuildContext context,
    _IngredientMacroCategory category,
    double totalGrams,
  ) {
    final ingredients = _sortedIngredientsByMacro(
      widget.recipe.ingredients,
      category,
      summaryMode: _summaryMode,
      servings: widget.recipe.servings <= 0 ? 1 : widget.recipe.servings,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 36,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_ingredientMacroLabel(category)} Breakdown',
                        style: context.text.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: ingredients
                          .map(
                            (ingredient) => _IngredientNutritionRow(
                              ingredient: ingredient,
                              category: category,
                              color: _ingredientMacroColor(category),
                              totalGrams: totalGrams,
                              servings: widget.recipe.servings <= 0
                                  ? 1
                                  : widget.recipe.servings,
                              summaryMode: _summaryMode,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _nutritionModeLabel(_NutritionSummaryMode mode) {
    switch (mode) {
      case _NutritionSummaryMode.serving:
        return 'Per serving';
      case _NutritionSummaryMode.total:
        return 'Total serving';
    }
  }

  static ExploreNutrition _nutritionForMode(
    ExploreRecipe recipe,
    _NutritionSummaryMode mode,
  ) {
    if (mode == _NutritionSummaryMode.total) return recipe.nutrition;

    final servings = recipe.servings <= 0 ? 1 : recipe.servings;
    return ExploreNutrition(
      calories: (recipe.nutrition.calories / servings).round(),
      carbsGrams: (recipe.nutrition.carbsGrams / servings).round(),
      proteinGrams: (recipe.nutrition.proteinGrams / servings).round(),
      fatGrams: (recipe.nutrition.fatGrams / servings).round(),
    );
  }

  static double _ingredientMacroValue(
    ExploreIngredient ingredient,
    _IngredientMacroCategory category, {
    required _NutritionSummaryMode summaryMode,
    required int servings,
  }) {
    final totalValue = switch (category) {
      _IngredientMacroCategory.carbohydrates => ingredient.carbsGrams,
      _IngredientMacroCategory.protein => ingredient.proteinGrams,
      _IngredientMacroCategory.fats => ingredient.fatGrams,
    };
    if (summaryMode == _NutritionSummaryMode.total) return totalValue;
    return totalValue / (servings <= 0 ? 1 : servings);
  }

  static List<ExploreIngredient> _sortedIngredientsByMacro(
    List<ExploreIngredient> ingredients,
    _IngredientMacroCategory category, {
    required _NutritionSummaryMode summaryMode,
    required int servings,
  }) {
    return [...ingredients]..sort((first, second) {
      final firstValue = _ingredientMacroValue(
        first,
        category,
        summaryMode: summaryMode,
        servings: servings,
      );
      final secondValue = _ingredientMacroValue(
        second,
        category,
        summaryMode: summaryMode,
        servings: servings,
      );
      final valueCompare = secondValue.compareTo(firstValue);
      if (valueCompare != 0) return valueCompare;
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
  }

  static String _ingredientMacroLabel(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return 'Carbohydrates';
      case _IngredientMacroCategory.protein:
        return 'Protein';
      case _IngredientMacroCategory.fats:
        return 'Fats';
    }
  }

  static Color _ingredientMacroColor(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return AppColors.primary;
      case _IngredientMacroCategory.protein:
        return AppColors.error;
      case _IngredientMacroCategory.fats:
        return AppColors.secondary;
    }
  }
}

class _IngredientMacroPager extends StatefulWidget {
  final List<ExploreIngredient> ingredients;
  final ExploreNutrition totalNutrition;
  final int servings;
  final _NutritionSummaryMode summaryMode;
  final void Function(_IngredientMacroCategory category, double totalGrams)
  onSeeAll;

  const _IngredientMacroPager({
    super.key,
    required this.ingredients,
    required this.totalNutrition,
    required this.servings,
    required this.summaryMode,
    required this.onSeeAll,
  });

  @override
  State<_IngredientMacroPager> createState() => _IngredientMacroPagerState();
}

class _IngredientMacroPagerState extends State<_IngredientMacroPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _categories = [
    _IngredientMacroCategory.carbohydrates,
    _IngredientMacroCategory.protein,
    _IngredientMacroCategory.fats,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 374,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _categories.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _IngredientMacroPage(
                key: ValueKey('${widget.summaryMode}-$category'),
                category: category,
                color: _NutritionTabState._ingredientMacroColor(category),
                ingredients: widget.ingredients,
                totalGrams: _totalGramsFor(category),
                servings: widget.servings,
                summaryMode: widget.summaryMode,
                onSeeAll: () =>
                    widget.onSeeAll(category, _totalGramsFor(category)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_categories.length, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }

  double _totalGramsFor(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return widget.totalNutrition.carbsGrams.toDouble();
      case _IngredientMacroCategory.protein:
        return widget.totalNutrition.proteinGrams.toDouble();
      case _IngredientMacroCategory.fats:
        return widget.totalNutrition.fatGrams.toDouble();
    }
  }
}

class _IngredientMacroPage extends StatelessWidget {
  final _IngredientMacroCategory category;
  final Color color;
  final List<ExploreIngredient> ingredients;
  final double totalGrams;
  final int servings;
  final _NutritionSummaryMode summaryMode;
  final VoidCallback onSeeAll;

  const _IngredientMacroPage({
    super.key,
    required this.category,
    required this.color,
    required this.ingredients,
    required this.totalGrams,
    required this.servings,
    required this.summaryMode,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final sortedIngredients = _NutritionTabState._sortedIngredientsByMacro(
      ingredients,
      category,
      summaryMode: summaryMode,
      servings: servings,
    );
    final visibleIngredients = sortedIngredients.take(5).toList();
    final totalLabel = _formatMacroGramValue(totalGrams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _NutritionTabState._ingredientMacroLabel(category),
              style: context.text.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${_NutritionTabState._nutritionModeLabel(summaryMode)} - ${totalLabel}g',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See all',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleIngredients.isEmpty)
          Text('No ingredients yet.', style: context.text.bodySmall)
        else
          ...visibleIngredients.map(
            (ingredient) => _IngredientNutritionRow(
              ingredient: ingredient,
              category: category,
              color: color,
              totalGrams: totalGrams,
              servings: servings,
              summaryMode: summaryMode,
            ),
          ),
      ],
    );
  }

  static String _formatMacroGramValue(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}

class _IngredientListItem extends StatelessWidget {
  final ExploreIngredient ingredient;

  const _IngredientListItem({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _RecipeDetailThumbnail(
              imagePath: ingredient.imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
                Text(ingredient.calories, style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ingredient.amount,
                maxLines: 3,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_IngredientCategoryGroup> _groupIngredientsByCategory(
  List<ExploreIngredient> ingredients,
) {
  final groups = <String, _IngredientCategoryGroup>{};

  for (final ingredient in ingredients) {
    final name = ingredient.ingredientCategoryName.trim().isEmpty
        ? 'Uncategorized'
        : ingredient.ingredientCategoryName.trim();
    groups.putIfAbsent(name, () => _IngredientCategoryGroup(name, []));
    groups[name]!.ingredients.add(ingredient);
  }

  for (final group in groups.values) {
    group.ingredients.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  return groups.values.toList();
}

class _IngredientCategoryGroup {
  final String name;
  final List<ExploreIngredient> ingredients;

  const _IngredientCategoryGroup(this.name, this.ingredients);
}

class _NutritionPanel extends StatelessWidget {
  final Widget child;

  const _NutritionPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final int totalGrams;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.totalGrams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final value = totalGrams <= 0 ? 0.0 : (grams / totalGrams).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: AppColors.background,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  '${(value * 100).round()}%',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${grams}g',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final int carbs;
  final int protein;
  final int fat;

  const _MacroRingPainter({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final rect = Offset.zero & size;
    final total = (carbs + protein + fat).toDouble();
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.background;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.5708,
      6.2832,
      false,
      backgroundPaint,
    );

    if (total <= 0) return;

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    var startAngle = -1.5708;
    const gapAngle = 0.08;
    final segments = [
      _MacroRingSegment(value: carbs, color: AppColors.primary),
      _MacroRingSegment(value: protein, color: AppColors.error),
      _MacroRingSegment(value: fat, color: AppColors.secondary),
    ];

    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.2832;
      segmentPaint.color = segment.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        (sweep - gapAngle).clamp(0.0, 6.2832).toDouble(),
        false,
        segmentPaint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.carbs != carbs ||
        oldDelegate.protein != protein ||
        oldDelegate.fat != fat;
  }
}

class _MacroRingSegment {
  final int value;
  final Color color;

  const _MacroRingSegment({required this.value, required this.color});
}

class _IngredientNutritionRow extends StatelessWidget {
  final ExploreIngredient ingredient;
  final _IngredientMacroCategory category;
  final Color color;
  final double totalGrams;
  final int servings;
  final _NutritionSummaryMode summaryMode;

  const _IngredientNutritionRow({
    required this.ingredient,
    required this.category,
    required this.color,
    required this.totalGrams,
    required this.servings,
    required this.summaryMode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final value = _NutritionTabState._ingredientMacroValue(
      ingredient,
      category,
      summaryMode: summaryMode,
      servings: servings,
    );
    final valueLabel = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    final percent = totalGrams <= 0
        ? 0
        : ((value / totalGrams).clamp(0.0, 1.0) * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _RecipeDetailThumbnail(
              imagePath: ingredient.imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: textTheme.bodySmall,
                        ),
                        Text(
                          '${valueLabel}g',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalGrams <= 0
                      ? 0
                      : (value / totalGrams).clamp(0.0, 1.0),
                  color: color,
                  backgroundColor: AppColors.background,
                  minHeight: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final bool isPublished;

  const _CommunityTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.isPublished,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final relatedRecipes = recipe.relatedRecipes.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.4),
              ),
              child: AppRemoteOrAssetAvatar(
                radius: 24,
                imagePath: recipe.authorAvatarPath,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.author, style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    recipe.community.authorBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            if (!recipe.isCreatedByCurrentUser) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: recipe.isFollowingAuthor
                    ? FilledButton.icon(
                        onPressed: () => viewModel.toggleCreatorFollow(),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Following'),
                      )
                    : OutlinedButton(
                        onPressed: () => viewModel.toggleCreatorFollow(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(color: context.colors.primary),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Follow'),
                      ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Related Recipes', style: textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push(
                  AppRouter.exploreCreatorDetail,
                  extra: ExploreCreatorDetailArgs(
                    creatorUid: recipe.creatorUid,
                  ),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (relatedRecipes.isEmpty)
          Text(
            'No recent recipes from this creator yet.',
            style: textTheme.bodySmall,
          )
        else
          SizedBox(
            height: 102,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 30) / 4;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: relatedRecipes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return SizedBox(
                      width: itemWidth,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == relatedRecipes.length - 1 ? 0 : 10,
                        ),
                        child: _RelatedRecipeCard(item: item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        AppPillSegmentedControl(
          labels: const ['Ratings', 'Comments'],
          selectedIndex: ExploreCommunityTab.values.indexOf(
            viewModel.selectedCommunityTab,
          ),
          onChanged: (index) =>
              viewModel.selectCommunityTab(ExploreCommunityTab.values[index]),
        ),
        const SizedBox(height: 24),
        if (viewModel.selectedCommunityTab == ExploreCommunityTab.ratings)
          _RatingsPanel(
            viewModel: viewModel,
            recipe: recipe,
            isPublished: isPublished,
            isSubmitting: viewModel.isSubmittingCommunityAction,
            canRate: !recipe.isCreatedByCurrentUser,
            onRatingSelected: (rating) =>
                _submitRating(context, viewModel, rating),
          )
        else
          ExploreCommentsPanel(
            viewModel: viewModel,
            recipe: recipe,
            isSubmitting: viewModel.isSubmittingCommunityAction,
            onAddComment: (content) =>
                _submitComment(context, viewModel, content),
            onToggleLike: (commentId) => viewModel.toggleCommentLike(commentId),
            onReply: (commentId, content) => viewModel.addCommentReply(
              commentId: commentId,
              content: content,
            ),
            onToggleReplyLike: viewModel.toggleReplyLike,
            onReplyToReply: (replyPath, content) => viewModel.addReplyToReply(
              replyPath: replyPath,
              content: content,
            ),
          ),
      ],
    );
  }

  Future<void> _submitRating(
    BuildContext context,
    ExploreRecipeDetailViewModel viewModel,
    int rating,
  ) async {
    final success = await viewModel.submitRating(rating.toDouble());
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Rating submitted.'
                : viewModel.communityActionErrorMessage ??
                      'Unable to submit rating.',
          ),
        ),
      );
  }

  Future<void> _submitComment(
    BuildContext context,
    ExploreRecipeDetailViewModel viewModel,
    String content,
  ) async {
    final success = await viewModel.addComment(content);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Comment posted.'
                : viewModel.communityActionErrorMessage ??
                      'Unable to post comment.',
          ),
        ),
      );
  }
}

class _RelatedRecipeCard extends StatelessWidget {
  final ExploreRecipeSummary item;

  const _RelatedRecipeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        context.push(
          AppRouter.exploreRecipeDetail,
          extra: ExploreRecipeDetailArgs(recipeId: item.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 1.6),
              ),
              child: ClipOval(
                child: AppRecipeMediaPreview(
                  mediaPath: item.imagePath,
                  fit: BoxFit.cover,
                  playOverlaySize: 28,
                  playIconSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CommunitySectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _RatingsPanel extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final bool isPublished;
  final bool isSubmitting;
  final bool canRate;
  final ValueChanged<int> onRatingSelected;

  const _RatingsPanel({
    required this.viewModel,
    required this.recipe,
    required this.isPublished,
    required this.isSubmitting,
    required this.canRate,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommunitySectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 104,
                  height: 112,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isPublished
                            ? recipe.rating.toStringAsFixed(1)
                            : 'No rating',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _RatingStars(size: 22, rating: recipe.rating),
                      const SizedBox(height: 4),
                      Text(
                        isPublished
                            ? '${recipe.ratingCount} ratings'
                            : 'Unpublished',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: recipe.community.ratingBreakdown.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Row(
                              children: [
                                Text(
                                  '${row.stars}',
                                  style: textTheme.bodySmall,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: recipe.ratingCount == 0
                                  ? 0
                                  : row.count / recipe.ratingCount,
                              color: context.colors.primary,
                              backgroundColor: AppColors.background,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${row.count}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RateRecipeCard(
          isSubmitting: isSubmitting,
          canRate: canRate,
          onRatingSelected: onRatingSelected,
        ),
        const SizedBox(height: 14),
        _ViewRatingsCard(
          reviews: viewModel.visibleReviews,
          starFilter: viewModel.ratingStarFilter,
          dateFilter: viewModel.ratingDateFilter,
          onFiltersChanged: viewModel.updateRatingFilters,
        ),
      ],
    );
  }
}

class _RateRecipeCard extends StatefulWidget {
  final bool isSubmitting;
  final bool canRate;
  final ValueChanged<int> onRatingSelected;

  const _RateRecipeCard({
    required this.isSubmitting,
    required this.canRate,
    required this.onRatingSelected,
  });

  @override
  State<_RateRecipeCard> createState() => _RateRecipeCardState();
}

class _RateRecipeCardState extends State<_RateRecipeCard> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return _CommunitySectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate this Recipe', style: textTheme.titleMedium),
          Text(
            widget.canRate
                ? 'Tap a star to rate'
                : 'You cannot rate your own recipe',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (widget.isSubmitting)
            const LoadingDialog(message: 'Submitting rating...', inline: true)
          else if (!widget.canRate)
            const SizedBox.shrink()
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return InkResponse(
                      onTap: () => setState(() => _selectedRating = rating),
                      radius: 26,
                      child: Icon(
                        rating <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.secondary,
                        size: 34,
                      ),
                    );
                  }),
                ),
                if (_selectedRating > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => widget.onRatingSelected(_selectedRating),
                      child: const Text('Submit Rating'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ViewRatingsCard extends StatelessWidget {
  final List<ExploreReview> reviews;
  final ExploreRatingStarFilter starFilter;
  final ExploreCommunityDateFilter dateFilter;
  final void Function({
    required ExploreRatingStarFilter star,
    required ExploreCommunityDateFilter date,
  })
  onFiltersChanged;

  const _ViewRatingsCard({
    required this.reviews,
    required this.starFilter,
    required this.dateFilter,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return _CommunitySectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('View Ratings', style: textTheme.titleMedium),
              const Spacer(),
              _CompactPopupDropdown(
                label: _ratingsDropdownLabel(starFilter, dateFilter),
                items: [
                  ...ExploreRatingStarFilter.values.map(
                    (filter) => _CompactPopupItem(
                      value: 'star:${filter.name}',
                      label: _ratingStarLabel(filter),
                    ),
                  ),
                  ...ExploreCommunityDateFilter.values.map(
                    (filter) => _CompactPopupItem(
                      value: 'date:${filter.name}',
                      label: _dateFilterLabel(filter),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value.startsWith('star:')) {
                    final filter = ExploreRatingStarFilter.values.firstWhere(
                      (item) => item.name == value.substring(5),
                    );
                    onFiltersChanged(star: filter, date: dateFilter);
                  } else if (value.startsWith('date:')) {
                    final filter = ExploreCommunityDateFilter.values.firstWhere(
                      (item) => item.name == value.substring(5),
                    );
                    onFiltersChanged(star: starFilter, date: filter);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No ratings yet', style: textTheme.bodySmall),
            )
          else
            ...reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }

  static String _ratingStarLabel(ExploreRatingStarFilter filter) {
    switch (filter) {
      case ExploreRatingStarFilter.all:
        return 'All';
      case ExploreRatingStarFilter.one:
        return '1 star';
      case ExploreRatingStarFilter.two:
        return '2 star';
      case ExploreRatingStarFilter.three:
        return '3 star';
      case ExploreRatingStarFilter.four:
        return '4 star';
      case ExploreRatingStarFilter.five:
        return '5 star';
    }
  }

  static String _dateFilterLabel(ExploreCommunityDateFilter filter) {
    switch (filter) {
      case ExploreCommunityDateFilter.all:
        return 'All';
      case ExploreCommunityDateFilter.latest:
        return 'Latest';
      case ExploreCommunityDateFilter.oldest:
        return 'Oldest';
    }
  }

  static String _ratingsDropdownLabel(
    ExploreRatingStarFilter star,
    ExploreCommunityDateFilter date,
  ) {
    if (star == ExploreRatingStarFilter.all &&
        date == ExploreCommunityDateFilter.all) {
      return 'All';
    }
    final parts = <String>[];
    if (star != ExploreRatingStarFilter.all) parts.add(_ratingStarLabel(star));
    if (date != ExploreCommunityDateFilter.all) {
      parts.add(_dateFilterLabel(date));
    }
    return parts.join(', ');
  }
}

class _ReviewTile extends StatelessWidget {
  final ExploreReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              AppRemoteOrAssetAvatar(imagePath: review.avatarPath),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author, style: textTheme.labelLarge),
                    Text(review.timeAgo, style: textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                child: _RatingStars(size: 18, rating: review.rating),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactPopupItem {
  final String value;
  final String label;

  const _CompactPopupItem({required this.value, required this.label});
}

class _CompactPopupDropdown extends StatelessWidget {
  final String label;
  final List<_CompactPopupItem> items;
  final ValueChanged<String> onSelected;

  const _CompactPopupDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem(value: item.value, child: Text(item.label));
        }).toList();
      },
      child: Container(
        height: 30,
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double size;
  final double rating;

  const _RatingStars({required this.size, required this.rating});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isFilled = index < rating.round();
          return Icon(
            Icons.star,
            size: size,
            color: isFilled ? AppColors.secondary : AppColors.border,
          );
        }),
      ),
    );
  }
}

class ExploreCommentsPanel extends StatefulWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final bool isSubmitting;
  final ValueChanged<String> onAddComment;
  final ValueChanged<String> onToggleLike;
  final Future<bool> Function(String commentId, String content) onReply;
  final ValueChanged<String> onToggleReplyLike;
  final Future<bool> Function(String replyPath, String content) onReplyToReply;

  const ExploreCommentsPanel({
    super.key,
    required this.viewModel,
    required this.recipe,
    required this.isSubmitting,
    required this.onAddComment,
    required this.onToggleLike,
    required this.onReply,
    required this.onToggleReplyLike,
    required this.onReplyToReply,
  });

  @override
  State<ExploreCommentsPanel> createState() => _ExploreCommentsPanelState();
}

class _ExploreCommentsPanelState extends State<ExploreCommentsPanel> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty || widget.isSubmitting) return;
    widget.onAddComment(content);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final comments = widget.viewModel.visibleComments;

    return _CommunitySectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${comments.length} Comments', style: textTheme.titleMedium),
              const Spacer(),
              _CompactPopupDropdown(
                label: _commentDateLabel(widget.viewModel.commentDateFilter),
                items: ExploreCommunityDateFilter.values.map((filter) {
                  return _CompactPopupItem(
                    value: filter.name,
                    label: _commentDateLabel(filter),
                  );
                }).toList(),
                onSelected: (value) {
                  final filter = ExploreCommunityDateFilter.values.firstWhere(
                    (item) => item.name == value,
                  );
                  widget.viewModel.updateCommentDateFilter(filter);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No comments yet', style: textTheme.bodySmall),
            )
          else
            ...comments.map((comment) {
              return _CommentTile(
                comment: comment,
                isSubmitting: widget.isSubmitting,
                onToggleLike: () => widget.onToggleLike(comment.id),
                onReply: (content) => widget.onReply(comment.id, content),
                onToggleReplyLike: widget.onToggleReplyLike,
                onReplyToReply: widget.onReplyToReply,
              );
            }),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 3,
            enabled: !widget.isSubmitting,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitComment(),
            decoration: InputDecoration(
              hintText: 'Add a comment',
              prefixIcon: Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: context.colors.surfaceContainerHighest.withValues(
                alpha: 0.46,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.4,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: widget.isSubmitting ? null : _submitComment,
                icon: Icon(
                  Icons.send,
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          if (widget.isSubmitting)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LoadingDialog(message: 'Posting comment...', inline: true),
            ),
        ],
      ),
    );
  }

  static String _commentDateLabel(ExploreCommunityDateFilter filter) {
    switch (filter) {
      case ExploreCommunityDateFilter.all:
        return 'All';
      case ExploreCommunityDateFilter.latest:
        return 'Latest';
      case ExploreCommunityDateFilter.oldest:
        return 'Oldest';
    }
  }
}

class _CommentTile extends StatefulWidget {
  final ExploreComment comment;
  final bool isSubmitting;
  final VoidCallback onToggleLike;
  final Future<bool> Function(String content) onReply;
  final ValueChanged<String> onToggleReplyLike;
  final Future<bool> Function(String replyPath, String content) onReplyToReply;

  const _CommentTile({
    required this.comment,
    required this.isSubmitting,
    required this.onToggleLike,
    required this.onReply,
    required this.onToggleReplyLike,
    required this.onReplyToReply,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || widget.isSubmitting) return;
    final success = await widget.onReply(content);
    if (!mounted) return;
    if (success) {
      _replyController.clear();
      setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final comment = widget.comment;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppRemoteOrAssetAvatar(
                    radius: 24,
                    imagePath: comment.avatarPath,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.timeAgo,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      comment.content,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _LikeIconButton(
                    isLiked: comment.isLiked,
                    onTap: widget.isSubmitting ? null : widget.onToggleLike,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.isSubmitting
                        ? null
                        : () => setState(() => _isReplying = !_isReplying),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Reply'),
                  ),
                  const Spacer(),
                  _LikeCountLabel(
                    likes: comment.likes,
                    onTap: widget.isSubmitting ? null : widget.onToggleLike,
                  ),
                ],
              ),
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: comment.replies.map((reply) {
                      return _ReplyTile(
                        reply: reply,
                        isSubmitting: widget.isSubmitting,
                        onToggleLike: widget.onToggleReplyLike,
                        onReply: widget.onReplyToReply,
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_isReplying) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _replyController,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !widget.isSubmitting,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitReply(),
                  decoration: InputDecoration(
                    hintText: 'Write a reply',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    suffixIcon: IconButton(
                      onPressed: widget.isSubmitting ? null : _submitReply,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeIconButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onTap;
  final double iconSize;

  const _LikeIconButton({
    required this.isLiked,
    required this.onTap,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          size: iconSize,
          color: isLiked ? context.colors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LikeCountLabel extends StatelessWidget {
  final int likes;
  final VoidCallback? onTap;

  const _LikeCountLabel({required this.likes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          '$likes',
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ReplyTile extends StatefulWidget {
  final ExploreCommentReply reply;
  final bool isSubmitting;
  final ValueChanged<String> onToggleLike;
  final Future<bool> Function(String replyPath, String content) onReply;

  const _ReplyTile({
    required this.reply,
    required this.isSubmitting,
    required this.onToggleLike,
    required this.onReply,
  });

  @override
  State<_ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends State<_ReplyTile> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || widget.isSubmitting) return;
    final success = await widget.onReply(widget.reply.documentPath, content);
    if (!mounted) return;
    if (success) {
      _replyController.clear();
      setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final reply = widget.reply;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppRemoteOrAssetAvatar(radius: 16, imagePath: reply.avatarPath),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      reply.timeAgo,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reply.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _LikeIconButton(
                isLiked: reply.isLiked,
                iconSize: 17,
                onTap: widget.isSubmitting
                    ? null
                    : () => widget.onToggleLike(reply.documentPath),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              TextButton(
                onPressed: widget.isSubmitting
                    ? null
                    : () => setState(() => _isReplying = !_isReplying),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Reply'),
              ),
              const Spacer(),
              _LikeCountLabel(
                likes: reply.likes,
                onTap: widget.isSubmitting
                    ? null
                    : () => widget.onToggleLike(reply.documentPath),
              ),
            ],
          ),
          if (reply.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: Column(
                children: reply.replies.map((nestedReply) {
                  return _ReplyTile(
                    reply: nestedReply,
                    isSubmitting: widget.isSubmitting,
                    onToggleLike: widget.onToggleLike,
                    onReply: widget.onReply,
                  );
                }).toList(),
              ),
            ),
          if (_isReplying) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _replyController,
              minLines: 1,
              maxLines: 3,
              enabled: !widget.isSubmitting,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitReply(),
              decoration: InputDecoration(
                hintText: 'Write a reply',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                suffixIcon: IconButton(
                  onPressed: widget.isSubmitting ? null : _submitReply,
                  icon: const Icon(Icons.send),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
