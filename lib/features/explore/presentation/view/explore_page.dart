import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../domain/entities/explore_recipe.dart';
import 'explore_recipe_detail_page.dart';
import '../viewmodel/explore_recipe_detail_viewmodel.dart';
import '../viewmodel/explore_viewmodel.dart';
import '../widgets/explore_creator_avatar.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_filters.dart';
import '../widgets/explore_recipe_grid.dart';

/// Main entry point for the recipe exploration feature.
/// Displays a grid of community recipes with filtering and search capabilities.
class ExplorePage extends StatelessWidget {
  /// Controls whether the app bar is displayed.
  /// When false, the page is embedded without navigation chrome.
  final bool showAppBar;

  /// Optional meal plan selection context for adding recipes to a meal plan.
  final MealPlanSelectionArgs? mealPlanSelection;

  const ExplorePage({
    super.key,
    this.showAppBar = false,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the viewmodel at the page level with all required dependencies.
    final page = ChangeNotifierProvider(
      create: (_) => ExploreViewModel(
        getRecipesUseCase: sl(),
        watchRecipesUseCase: sl(),
        getRecipeSetupUseCase: sl(),
        getIngredientCategoriesUseCase: sl(),
        getMealCategoriesUseCase: sl(),
        toggleCreatorFollowUseCase: sl(),
        toggleFavouriteUseCase: sl(),
      ),
      child: _ExplorePageView(mealPlanSelection: mealPlanSelection),
    );
    // Return bare page or scaffold with app bar based on configuration.
    if (!showAppBar) return page;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Explore Community Recipes',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: page,
    );
  }
}

/// Stateful widget that manages the tab-based navigation for recipe exploration.
/// Handles tab switching between All recipes, Following, and Trending views.
class _ExplorePageView extends StatefulWidget {
  final MealPlanSelectionArgs? mealPlanSelection;

  const _ExplorePageView({this.mealPlanSelection});

  @override
  State<_ExplorePageView> createState() => _ExplorePageViewState();
}

class _ExplorePageViewState extends State<_ExplorePageView>
    with SingleTickerProviderStateMixin {
  // Controller for managing the three main tabs: All, Following, Trending.
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreRecipeTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  /// Synchronizes the tab controller state with the viewmodel when tabs change.
  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<ExploreViewModel>().selectTab(
      ExploreRecipeTab.values[_tabController.index],
    );
  }

  /// Programmatically selects a tab and updates the viewmodel.
  void _selectTab(ExploreRecipeTab tab) {
    final index = ExploreRecipeTab.values.indexOf(tab);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    context.read<ExploreViewModel>().selectTab(tab);
  }

  /// Displays a modal dialog showing comments for a specific recipe.
  Future<void> _showCommentsPopup(ExploreRecipe recipe) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        // Create a separate viewmodel instance scoped to the dialog.
        return ChangeNotifierProvider(
          create: (_) => ExploreRecipeDetailViewModel(
            recipeId: recipe.id,
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
          ),
          child: const _ExploreCommentsDialog(),
        );
      },
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
    final viewModel = context.watch<ExploreViewModel>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Filter bar with search input and category filter button.
            ExploreFilters(
              tabController: _tabController,
              viewModel: viewModel,
              onSearchChanged: viewModel.updateQuery,
              onFilterTap: (target) =>
                  _showFilterDialog(context, viewModel, target: target),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: ExploreRecipeTab.values.map((tab) {
                  return _ExploreContent(
                    tab: tab,
                    viewModel: viewModel,
                    mealPlanSelection: widget.mealPlanSelection,
                    onExploreNow: () => _selectTab(ExploreRecipeTab.all),
                    onCommentTap: _showCommentsPopup,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the advanced filter dialog with category, time, and rating options.
  Future<void> _showFilterDialog(
      BuildContext context,
      ExploreViewModel viewModel, {
        ExploreFilterTarget? target,
      }) async {
    final selected = await showGeneralDialog<RecipeFilterSelection>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return RecipeFilterDialog(
          recipeCategories: viewModel.categoryOptions,
          ingredientCategories: viewModel.ingredientCategoryOptions,
          mealCategories: viewModel.mealCategoryOptions,
          initialTarget: target,
          initial: RecipeFilterSelection(
            sortOptions: viewModel.sortOptions,
            recipeCategories: viewModel.recipeCategoryFilters,
            ingredientCategories: viewModel.ingredientCategoryFilters,
            mealCategories: viewModel.mealCategoryFilters,
            preparationTimes: viewModel.preparationTimeFilters,
            ratings: viewModel.ratingFilters,
            comments: viewModel.commentsFilters,
            views: viewModel.viewsFilters,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    // Apply selected filters if the user confirmed the dialog.
    if (selected != null) {
      viewModel.updateSortOptions(selected.sortOptions);
      viewModel.updateFilters(
        recipeCategories: selected.recipeCategories,
        ingredientCategories: selected.ingredientCategories,
        mealCategories: selected.mealCategories,
        preparationTimes: selected.preparationTimes,
        ratings: selected.ratings,
        comments: selected.comments,
        views: selected.views,
      );
    }
  }
}

/// Dialog widget that displays the comment section for a recipe.
/// Contains the comment list, input field, and interaction buttons.
class _ExploreCommentsDialog extends StatelessWidget {
  const _ExploreCommentsDialog();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreRecipeDetailViewModel>();
    final recipe = viewModel.recipe;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog header with title and close button.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comments',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _ExploreCommentsDialogBody(
                      viewModel: viewModel,
                      recipe: recipe,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Body of the comments dialog that handles loading, error, and content states.
class _ExploreCommentsDialogBody extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe? recipe;

  const _ExploreCommentsDialogBody({
    required this.viewModel,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching comments.
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading comments...', inline: true);
    }

    final error = viewModel.errorMessage;
    if (error != null || recipe == null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          error ?? 'Comments unavailable',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Render the interactive comments panel with all CRUD operations.
    return ExploreCommentsPanel(
      viewModel: viewModel,
      recipe: recipe!,
      isSubmitting: viewModel.isSubmittingCommunityAction,
      onAddComment: (content) => viewModel.addComment(content),
      onToggleLike: (commentId) => viewModel.toggleCommentLike(commentId),
      onReply: (commentId, content) =>
          viewModel.addCommentReply(commentId: commentId, content: content),
      onToggleReplyLike: (replyPath) => viewModel.toggleReplyLike(replyPath),
      onReplyToReply: (replyPath, content) =>
          viewModel.addReplyToReply(replyPath: replyPath, content: content),
    );
  }
}

/// Content widget displayed for each tab in the explore page.
/// Renders the appropriate view based on the selected tab and data state.
class _ExploreContent extends StatelessWidget {
  final ExploreRecipeTab tab;
  final ExploreViewModel viewModel;
  final MealPlanSelectionArgs? mealPlanSelection;
  final VoidCallback onExploreNow;
  final ValueChanged<ExploreRecipe> onCommentTap;

  const _ExploreContent({
    required this.tab,
    required this.viewModel,
    this.mealPlanSelection,
    required this.onExploreNow,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading state while fetching recipes.
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipes...', inline: true);
    }

    final error = viewModel.errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Following tab displays a list of creators instead of recipes.
    if (tab == ExploreRecipeTab.following) {
      return _FollowingCreatorsList(
        creators: viewModel.followedCreators,
        suggestedCreators: viewModel.suggestedCreators,
        onToggleFollow: viewModel.toggleCreatorFollow,
      );
    }

    // Show empty state message when no recipes match the current filter.
    if (viewModel.shouldShowFollowingEmptyFor(tab)) {
      return ExploreEmptyState(onExploreNow: onExploreNow);
    }

    final recipes = viewModel.visibleRecipesFor(tab);
    if (recipes.isEmpty) {
      return Center(
        child: Text(
          'No recipes found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Render the recipe grid with pull-to-refresh and interaction callbacks.
    return RefreshIndicator(
      onRefresh: viewModel.loadRecipes,
      child: ExploreRecipeGridView(
        recipes: recipes,
        onCommentTap: onCommentTap,
        onFavouriteTap: viewModel.toggleFavourite,
        onImageLongPress: (recipe) => _showRecipeImage(context, recipe),
        disabledRecipeIds: mealPlanSelection?.existingRecipeIds.toSet() ?? {},
        calorieBudget: mealPlanSelection?.calorieBudget,
        onRecipeTap: (recipe) {
          context.push(
            AppRouter.exploreRecipeDetail,
            extra: ExploreRecipeDetailArgs(
              recipeId: recipe.id,
              mealPlanSelection: mealPlanSelection,
            ),
          );
        },
      ),
    );
  }

  /// Displays a full-screen dialog showing the recipe image on long press.
  Future<void> _showRecipeImage(
      BuildContext context,
      ExploreRecipe recipe,
      ) async {
    await showRecipeMediaDialog(context, recipe.imagePath);
  }
}

/// Displays a list of followed creators with follow/unfollow controls.
/// Also shows suggested creators in a horizontal scrollable section.
class _FollowingCreatorsList extends StatefulWidget {
  final List<ExploreCreatorSummary> creators;
  final List<ExploreCreatorSummary> suggestedCreators;
  final ValueChanged<String> onToggleFollow;

  const _FollowingCreatorsList({
    required this.creators,
    required this.suggestedCreators,
    required this.onToggleFollow,
  });

  @override
  State<_FollowingCreatorsList> createState() => _FollowingCreatorsListState();
}

class _FollowingCreatorsListState extends State<_FollowingCreatorsList> {
  // Pagination threshold for loading more suggested creators.
  static const _suggestionBatchSize = 20;
  int _visibleSuggestionCount = _suggestionBatchSize;

  @override
  void didUpdateWidget(covariant _FollowingCreatorsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adjust visible count when suggested creators list changes.
    if (widget.suggestedCreators.length < _visibleSuggestionCount) {
      _visibleSuggestionCount =
      widget.suggestedCreators.length < _suggestionBatchSize
          ? _suggestionBatchSize
          : widget.suggestedCreators.length;
    }
  }

  /// Increases the number of visible suggested creators by batch size.
  void _showMoreSuggestions() {
    setState(() {
      final nextCount = _visibleSuggestionCount + _suggestionBatchSize;
      _visibleSuggestionCount = nextCount > widget.suggestedCreators.length
          ? widget.suggestedCreators.length
          : nextCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = widget.suggestedCreators
        .take(_visibleSuggestionCount)
        .toList(growable: false);
    final hasMoreSuggestions =
        widget.suggestedCreators.length > visibleSuggestions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Section header for followed creators.
        _CreatorSectionHeader(
          title: 'Total following: ${widget.creators.length}',
        ),
        const SizedBox(height: 8),
        if (widget.creators.isEmpty)
          const _CreatorEmptyMessage(message: 'No followed creators yet.')
        else
          ..._separatedCreatorTiles(creators: widget.creators),
        const SizedBox(height: 22),
        // Section header for suggested creators.
        const _CreatorSectionHeader(title: 'Suggested for you'),
        const SizedBox(height: 10),
        if (visibleSuggestions.isEmpty)
          const _CreatorEmptyMessage(message: 'No suggested creators yet.')
        else
          SizedBox(
            height: 194,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount:
              visibleSuggestions.length + (hasMoreSuggestions ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                // Show "View more" card at the end of the list if more exist.
                if (index == visibleSuggestions.length) {
                  return _SuggestedViewMoreCard(
                    onPressed: _showMoreSuggestions,
                  );
                }
                final creator = visibleSuggestions[index];
                return _SuggestedCreatorCard(
                  creator: creator,
                  onToggleFollow: widget.onToggleFollow,
                );
              },
            ),
          ),
      ],
    );
  }

  /// Builds a list of creator tiles separated by dividers.
  List<Widget> _separatedCreatorTiles({
    required List<ExploreCreatorSummary> creators,
  }) {
    final widgets = <Widget>[];
    for (var index = 0; index < creators.length; index++) {
      widgets.add(
        _FollowingCreatorTile(
          creator: creators[index],
          onToggleFollow: widget.onToggleFollow,
        ),
      );
      if (index != creators.length - 1) {
        widgets.add(
          const Divider(height: 1, thickness: 0.7, color: AppColors.border),
        );
      }
    }
    return widgets;
  }
}

/// Header widget for creator list sections with bold title styling.
class _CreatorSectionHeader extends StatelessWidget {
  final String title;

  const _CreatorSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty state message displayed when no creators are available in a section.
class _CreatorEmptyMessage extends StatelessWidget {
  final String message;

  const _CreatorEmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Tile widget displaying a followed creator with avatar, name, follower count, and unfollow button.
class _FollowingCreatorTile extends StatelessWidget {
  final ExploreCreatorSummary creator;
  final ValueChanged<String> onToggleFollow;

  const _FollowingCreatorTile({
    required this.creator,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          AppRouter.exploreCreatorDetail,
          extra: ExploreCreatorDetailArgs(creatorUid: creator.uid),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            ExploreCreatorAvatar(
              imagePath: creator.avatarPath,
              radius: 28,
              imageSize: 56,
              iconSize: 32,
              hasBorder: true,
            ),
            const SizedBox(width: 18),
            Expanded(child: _CreatorTextBlock(creator: creator)),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => onToggleFollow(creator.uid),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Following',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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

/// Card widget for suggested creators with follow button and avatar.
class _SuggestedCreatorCard extends StatelessWidget {
  final ExploreCreatorSummary creator;
  final ValueChanged<String> onToggleFollow;

  const _SuggestedCreatorCard({
    required this.creator,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          AppRouter.exploreCreatorDetail,
          extra: ExploreCreatorDetailArgs(creatorUid: creator.uid),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 164,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: [
                const SizedBox(height: 4),
                _SuggestedCreatorAvatar(creator: creator),
                const SizedBox(height: 6),
                Text(
                  creator.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => onToggleFollow(creator.uid),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar widget for suggested creator cards with larger size.
class _SuggestedCreatorAvatar extends StatelessWidget {
  final ExploreCreatorSummary creator;

  const _SuggestedCreatorAvatar({required this.creator});

  @override
  Widget build(BuildContext context) {
    return ExploreCreatorAvatar(
      imagePath: creator.avatarPath,
      radius: 38,
      imageSize: 76,
      iconSize: 36,
      hasBorder: false,
    );
  }
}

/// Card that triggers loading more suggested creators when pressed.
class _SuggestedViewMoreCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _SuggestedViewMoreCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Center(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text('View more'),
          ),
        ),
      ),
    );
  }
}

/// Text block displaying creator name and formatted follower count.
class _CreatorTextBlock extends StatelessWidget {
  final ExploreCreatorSummary creator;

  const _CreatorTextBlock({required this.creator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          creator.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_compactCount(creator.followerCount)} Followers',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Formats a number into a compact string with 'k' suffix for thousands.
/// Example: 1500 -> '1.5k', 10000 -> '10k'
String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}