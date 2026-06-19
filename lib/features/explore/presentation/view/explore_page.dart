import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import 'explore_recipe_detail_page.dart';
import '../viewmodel/explore_recipe_detail_viewmodel.dart';
import '../viewmodel/explore_viewmodel.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_recipe_grid.dart';

enum _ExploreFilterTarget {
  recipeCategory,
  meal,
  ingredients,
  preparationTime,
  comments,
  views,
}

class ExplorePage extends StatelessWidget {
  final bool showAppBar;
  final MealPlanSelectionArgs? mealPlanSelection;

  const ExplorePage({
    super.key,
    this.showAppBar = false,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
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

class _ExplorePageView extends StatefulWidget {
  final MealPlanSelectionArgs? mealPlanSelection;

  const _ExplorePageView({this.mealPlanSelection});

  @override
  State<_ExplorePageView> createState() => _ExplorePageViewState();
}

class _ExplorePageViewState extends State<_ExplorePageView>
    with SingleTickerProviderStateMixin {
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

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<ExploreViewModel>().selectTab(
      ExploreRecipeTab.values[_tabController.index],
    );
  }

  void _selectTab(ExploreRecipeTab tab) {
    final index = ExploreRecipeTab.values.indexOf(tab);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    context.read<ExploreViewModel>().selectTab(tab);
  }

  Future<void> _showCommentsPopup(ExploreRecipe recipe) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
            _ExploreFilters(
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

  Future<void> _showFilterDialog(
    BuildContext context,
    ExploreViewModel viewModel, {
    _ExploreFilterTarget? target,
  }) async {
    final selected = await showGeneralDialog<_RecipeFilterSelection>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _RecipeFilterDialog(
          recipeCategories: viewModel.categoryOptions,
          ingredientCategories: viewModel.ingredientCategoryOptions,
          mealCategories: viewModel.mealCategoryOptions,
          initialTarget: target,
          initial: _RecipeFilterSelection(
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

class _ExploreCommentsDialogBody extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe? recipe;

  const _ExploreCommentsDialogBody({
    required this.viewModel,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
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

    if (tab == ExploreRecipeTab.following) {
      return _FollowingCreatorsList(
        creators: viewModel.followedCreators,
        suggestedCreators: viewModel.suggestedCreators,
        onToggleFollow: viewModel.toggleCreatorFollow,
      );
    }

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

  Future<void> _showRecipeImage(
    BuildContext context,
    ExploreRecipe recipe,
  ) async {
    await showRecipeMediaDialog(context, recipe.imagePath);
  }
}

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
  static const _suggestionBatchSize = 20;
  int _visibleSuggestionCount = _suggestionBatchSize;

  @override
  void didUpdateWidget(covariant _FollowingCreatorsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestedCreators.length < _visibleSuggestionCount) {
      _visibleSuggestionCount =
          widget.suggestedCreators.length < _suggestionBatchSize
          ? _suggestionBatchSize
          : widget.suggestedCreators.length;
    }
  }

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
        _CreatorSectionHeader(
          title: 'Total following: ${widget.creators.length}',
        ),
        const SizedBox(height: 8),
        if (widget.creators.isEmpty)
          const _CreatorEmptyMessage(message: 'No followed creators yet.')
        else
          ..._separatedCreatorTiles(
            creators: widget.creators,
          ),
        const SizedBox(height: 22),
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
                if (index == visibleSuggestions.length) {
                  return _SuggestedViewMoreCard(onPressed: _showMoreSuggestions);
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

class _CreatorSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _CreatorSectionHeader({required this.title, this.trailing});

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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CreatorEmptyMessage extends StatelessWidget {
  final String message;

  const _CreatorEmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

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
            _ExploreCreatorAvatar(
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

class _SuggestedCreatorAvatar extends StatelessWidget {
  final ExploreCreatorSummary creator;

  const _SuggestedCreatorAvatar({required this.creator});

  @override
  Widget build(BuildContext context) {
    return _ExploreCreatorAvatar(
      imagePath: creator.avatarPath,
      radius: 38,
      imageSize: 76,
      iconSize: 36,
      hasBorder: false,
    );
  }
}

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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}

class _ExploreFilters extends StatefulWidget {
  final TabController tabController;
  final ExploreViewModel viewModel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_ExploreFilterTarget?> onFilterTap;

  const _ExploreFilters({
    required this.tabController,
    required this.viewModel,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<_ExploreFilters> createState() => _ExploreFiltersState();
}

class _ExploreFiltersState extends State<_ExploreFilters> {
  final _searchController = TextEditingController();
  final _recentSearches = <String>[];

  @override
  void didUpdateWidget(covariant _ExploreFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.viewModel.query) {
      _searchController.text = widget.viewModel.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSearchMenu() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: _ExploreSearchSheet(
            initialQuery: widget.viewModel.query,
            recentSearches: _recentSearches,
            discoveries: _discoverOptions,
            creators: _creatorOptions,
            onRemoveRecent: _removeRecentSearch,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
    if (selected == null) return;
    final query = selected.trim();
    _searchController.text = query;
    widget.onSearchChanged(query);
    if (query.isNotEmpty) {
      setState(() {
        _recentSearches.removeWhere(
          (item) => item.toLowerCase() == query.toLowerCase(),
        );
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 6) {
          _recentSearches.removeRange(6, _recentSearches.length);
        }
      });
    }
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == search.toLowerCase(),
      );
    });
  }

  List<_CreatorSearchOption> get _creatorOptions {
    final options = <String, _CreatorSearchOption>{};
    for (final recipe in widget.viewModel.recipes) {
      if (recipe.isCreatedByCurrentUser || recipe.creatorUid.isEmpty) {
        continue;
      }
      final existing = options[recipe.creatorUid];
      options[recipe.creatorUid] = _CreatorSearchOption(
        name: recipe.author == 'You' ? 'Creator' : recipe.author,
        avatarPath: recipe.authorAvatarPath,
        popularityScore:
            (existing?.popularityScore ?? 0) +
            recipe.totalViews +
            recipe.commentCount +
            recipe.ratingCount,
      );
    }
    final sorted = options.values.toList()
      ..sort(
        (first, second) =>
            second.popularityScore.compareTo(first.popularityScore),
      );
    return sorted.take(5).toList();
  }

  List<_DiscoverSearchOption> get _discoverOptions {
    final recipes = [
      ...widget.viewModel.recipes,
    ]..sort((first, second) => second.publishedAt.compareTo(first.publishedAt));
    return recipes.take(6).map((recipe) {
      return _DiscoverSearchOption(
        title: recipe.title,
        category: recipe.category,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  readOnly: true,
                  onTap: _openSearchMenu,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 24),
                    hintText: 'Search food, brand, category, ...',
                    suffixIcon: SizedBox(
                      width: _searchController.text.trim().isEmpty ? 56 : 102,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.trim().isNotEmpty)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          IconButton(
                            tooltip: 'Sort and filter',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => widget.onFilterTap(null),
                            icon: const Icon(Icons.filter_alt, size: 24),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 4),
                  children: [
                    _FilterPill(
                      icon: Icons.restaurant_menu,
                      label: 'Recipe Category',
                      onTap: () => widget.onFilterTap(
                        _ExploreFilterTarget.recipeCategory,
                      ),
                    ),
                    _FilterPill(
                      icon: Icons.breakfast_dining,
                      label: 'Meal',
                      onTap: () =>
                          widget.onFilterTap(_ExploreFilterTarget.meal),
                    ),
                    _FilterPill(
                      icon: Icons.eco,
                      label: 'Ingredients',
                      onTap: () => widget.onFilterTap(
                        _ExploreFilterTarget.ingredients,
                      ),
                    ),
                    _FilterPill(
                      icon: Icons.timer_outlined,
                      label: 'Preparation Time',
                      onTap: () => widget.onFilterTap(
                        _ExploreFilterTarget.preparationTime,
                      ),
                    ),
                    _FilterPill(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comments',
                      onTap: () =>
                          widget.onFilterTap(_ExploreFilterTarget.comments),
                    ),
                    _FilterPill(
                      icon: Icons.visibility_outlined,
                      label: 'Views',
                      onTap: () =>
                          widget.onFilterTap(_ExploreFilterTarget.views),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              AppSegmentedTabs(
                controller: widget.tabController,
                tabs: ExploreRecipeTab.values.map(_tabLabel).toList(),
                isScrollable: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tabLabel(ExploreRecipeTab tab) {
    switch (tab) {
      case ExploreRecipeTab.all:
        return 'All';
      case ExploreRecipeTab.popular:
        return 'Popular';
      case ExploreRecipeTab.recent:
        return 'Recent';
      case ExploreRecipeTab.following:
        return 'Following';
    }
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorSearchOption {
  final String name;
  final String avatarPath;
  final int popularityScore;

  const _CreatorSearchOption({
    required this.name,
    required this.avatarPath,
    required this.popularityScore,
  });
}

class _DiscoverSearchOption {
  final String title;
  final String category;

  const _DiscoverSearchOption({required this.title, required this.category});
}

class _ExploreSearchSheet extends StatefulWidget {
  final String initialQuery;
  final List<String> recentSearches;
  final List<_DiscoverSearchOption> discoveries;
  final List<_CreatorSearchOption> creators;
  final ValueChanged<String> onRemoveRecent;

  const _ExploreSearchSheet({
    required this.initialQuery,
    required this.recentSearches,
    required this.discoveries,
    required this.creators,
    required this.onRemoveRecent,
  });

  @override
  State<_ExploreSearchSheet> createState() => _ExploreSearchSheetState();
}

class _ExploreSearchSheetState extends State<_ExploreSearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    Navigator.of(context).pop(value.trim());
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search food, creator, category, ...',
                      suffixIcon: _controller.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (widget.discoveries.isNotEmpty) ...[
                    Text('Discover', style: textTheme.titleSmall),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.discoveries.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 58,
                          ),
                      itemBuilder: (context, index) {
                        final item = widget.discoveries[index];
                        return InkWell(
                          onTap: () => _submit(item.title),
                          borderRadius: BorderRadius.circular(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelMedium,
                                  ),
                                  Text(
                                    item.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.recentSearches.isNotEmpty) ...[
                    Text('Recent Searches', style: textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.recentSearches.map((search) {
                        return InputChip(
                          label: Text(search),
                          onPressed: () => _submit(search),
                          onDeleted: () {
                            widget.onRemoveRecent(search);
                            setState(() {});
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Creators', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (widget.creators.isEmpty)
                    Text(
                      'No creator recommendations yet.',
                      style: textTheme.bodySmall,
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.creators.length,
                        itemBuilder: (context, index) {
                          final creator = widget.creators[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _ExploreCreatorAvatar(
                              imagePath: creator.avatarPath,
                              radius: 18,
                              imageSize: 36,
                              iconSize: 22,
                            ),
                            title: Text(creator.name),
                            onTap: () => _submit(creator.name),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButtonSection extends StatelessWidget {
  final String title;
  final Set<ExploreSortOption> selected;
  final List<ExploreSortOption> values;
  final String Function(ExploreSortOption value) labelBuilder;
  final void Function(ExploreSortOption value, List<ExploreSortOption> group)
  onSelected;

  const _SortButtonSection({
    required this.title,
    required this.selected,
    required this.values,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            return ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: isSelected,
              onSelected: (_) => onSelected(value, values),
              selectedColor: AppColors.primary.withValues(alpha: 0.14),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecipeFilterSelection {
  final Set<ExploreSortOption> sortOptions;
  final Set<ExploreRecipeCategoryOption> recipeCategories;
  final Set<ExploreRecipeCategoryOption> ingredientCategories;
  final Set<String> mealCategories;
  final Set<ExplorePreparationTimeFilter> preparationTimes;
  final Set<ExploreRatingFilter> ratings;
  final Set<ExploreCommentsFilter> comments;
  final Set<ExploreViewsFilter> views;

  const _RecipeFilterSelection({
    required this.sortOptions,
    required this.recipeCategories,
    required this.ingredientCategories,
    required this.mealCategories,
    required this.preparationTimes,
    required this.ratings,
    required this.comments,
    required this.views,
  });
}

class _RecipeFilterDialog extends StatefulWidget {
  final List<ExploreRecipeCategoryOption> recipeCategories;
  final List<ExploreRecipeCategoryOption> ingredientCategories;
  final List<String> mealCategories;
  final _ExploreFilterTarget? initialTarget;
  final _RecipeFilterSelection initial;

  const _RecipeFilterDialog({
    required this.recipeCategories,
    required this.ingredientCategories,
    required this.mealCategories,
    this.initialTarget,
    required this.initial,
  });

  @override
  State<_RecipeFilterDialog> createState() => _RecipeFilterDialogState();
}

class _RecipeFilterDialogState extends State<_RecipeFilterDialog> {
  late Set<ExploreSortOption> _sortOptions;
  late Set<ExploreRecipeCategoryOption> _recipeCategories;
  late Set<ExploreRecipeCategoryOption> _ingredientCategories;
  late Set<String> _mealCategories;
  late Set<ExplorePreparationTimeFilter> _preparationTimes;
  late Set<ExploreRatingFilter> _ratings;
  late Set<ExploreCommentsFilter> _comments;
  late Set<ExploreViewsFilter> _views;
  final _mealKey = GlobalKey();
  final _recipeCategoryKey = GlobalKey();
  final _ingredientsKey = GlobalKey();
  final _preparationTimeKey = GlobalKey();
  final _commentsKey = GlobalKey();
  final _viewsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sortOptions = {...widget.initial.sortOptions};
    _recipeCategories = {...widget.initial.recipeCategories};
    _ingredientCategories = {...widget.initial.ingredientCategories};
    _mealCategories = {...widget.initial.mealCategories};
    _preparationTimes = {...widget.initial.preparationTimes};
    _ratings = {...widget.initial.ratings};
    _comments = {...widget.initial.comments};
    _views = {...widget.initial.views};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialTarget();
    });
  }

  void _scrollToInitialTarget() {
    final target = widget.initialTarget;
    if (target == null) return;
    final key = switch (target) {
      _ExploreFilterTarget.recipeCategory => _recipeCategoryKey,
      _ExploreFilterTarget.meal => _mealKey,
      _ExploreFilterTarget.ingredients => _ingredientsKey,
      _ExploreFilterTarget.preparationTime => _preparationTimeKey,
      _ExploreFilterTarget.comments => _commentsKey,
      _ExploreFilterTarget.views => _viewsKey,
    };
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'Sort and Filter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SortButtonSection(
                      title: 'Sort',
                      selected: _sortOptions,
                      values: ExploreSortOption.values,
                      labelBuilder: _sortLabel,
                      onSelected: _toggleSortOption,
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _mealKey,
                      child: _OptionChipSection<String>(
                        title: 'Meal Category',
                        values: widget.mealCategories,
                        selected: _mealCategories,
                        labelBuilder: (value) => value,
                        onSelected: _toggleMealCategory,
                      ),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _recipeCategoryKey,
                      child: _OptionChipSection<ExploreRecipeCategoryOption>(
                        title: 'Recipe Category',
                        values: widget.recipeCategories,
                        selected: _recipeCategories,
                        labelBuilder: (value) => value.name,
                        onSelected: _toggleRecipeCategory,
                      ),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _ingredientsKey,
                      child: _OptionChipSection<ExploreRecipeCategoryOption>(
                        title: 'Ingredient Category',
                        values: widget.ingredientCategories,
                        selected: _ingredientCategories,
                        labelBuilder: (value) => value.name,
                        onSelected: _toggleIngredientCategory,
                      ),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _preparationTimeKey,
                      child:
                          _MultiFilterButtonSection<ExplorePreparationTimeFilter>(
                            title: 'Preparation Time',
                            selected: _preparationTimes,
                            values: ExplorePreparationTimeFilter.values,
                            allValue: ExplorePreparationTimeFilter.all,
                            labelBuilder: _preparationTimeFilterLabel,
                            onSelected: (values) {
                              setState(() => _preparationTimes = values);
                            },
                          ),
                    ),
                    const SizedBox(height: 18),
                    _MultiFilterButtonSection<ExploreRatingFilter>(
                      title: 'Ratings',
                      selected: _ratings,
                      values: ExploreRatingFilter.values,
                      allValue: ExploreRatingFilter.all,
                      labelBuilder: _ratingFilterLabel,
                      onSelected: (values) => setState(() => _ratings = values),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _commentsKey,
                      child: _MultiFilterButtonSection<ExploreCommentsFilter>(
                        title: 'Comments',
                        selected: _comments,
                        values: ExploreCommentsFilter.values,
                        allValue: ExploreCommentsFilter.all,
                        labelBuilder: _commentsFilterLabel,
                        onSelected: (values) =>
                            setState(() => _comments = values),
                      ),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _viewsKey,
                      child: _MultiFilterButtonSection<ExploreViewsFilter>(
                        title: 'Views',
                        selected: _views,
                        values: ExploreViewsFilter.values,
                        allValue: ExploreViewsFilter.all,
                        labelBuilder: _viewsFilterLabel,
                        onSelected: (values) => setState(() => _views = values),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _sortOptions = {ExploreSortOption.alphabetAZ};
      _recipeCategories = {};
      _ingredientCategories = {};
      _mealCategories = {};
      _preparationTimes = {ExplorePreparationTimeFilter.all};
      _ratings = {ExploreRatingFilter.all};
      _comments = {ExploreCommentsFilter.all};
      _views = {ExploreViewsFilter.all};
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _RecipeFilterSelection(
        sortOptions: _sortOptions,
        recipeCategories: _recipeCategories,
        ingredientCategories: _ingredientCategories,
        mealCategories: _mealCategories,
        preparationTimes: _preparationTimes,
        ratings: _ratings,
        comments: _comments,
        views: _views,
      ),
    );
  }

  void _toggleSortOption(
    ExploreSortOption option,
    List<ExploreSortOption> group,
  ) {
    setState(() {
      if (_sortOptions.contains(option)) {
        _sortOptions.remove(option);
      } else {
        _sortOptions.removeAll(group);
        _sortOptions.add(option);
      }
      if (_sortOptions.isEmpty) _sortOptions.add(ExploreSortOption.alphabetAZ);
    });
  }

  void _toggleRecipeCategory(ExploreRecipeCategoryOption option) {
    setState(() => _toggleOption(_recipeCategories, option));
  }

  void _toggleIngredientCategory(ExploreRecipeCategoryOption option) {
    setState(() => _toggleOption(_ingredientCategories, option));
  }

  void _toggleMealCategory(String option) {
    setState(() => _toggleOption(_mealCategories, option));
  }

  void _toggleOption<T>(Set<T> values, T value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  static String _sortLabel(ExploreSortOption option) {
    switch (option) {
      case ExploreSortOption.alphabetAZ:
        return 'A-Z';
      case ExploreSortOption.alphabetZA:
        return 'Z-A';
      case ExploreSortOption.newest:
        return 'Newest';
      case ExploreSortOption.oldest:
        return 'Oldest';
      case ExploreSortOption.ratingHighLow:
        return 'Rating High-Low';
      case ExploreSortOption.ratingLowHigh:
        return 'Rating Low-High';
      case ExploreSortOption.viewsHighLow:
        return 'Views High-Low';
      case ExploreSortOption.viewsLowHigh:
        return 'Views Low-High';
    }
  }

  static String _preparationTimeFilterLabel(ExplorePreparationTimeFilter value) {
    switch (value) {
      case ExplorePreparationTimeFilter.all:
        return 'All';
      case ExplorePreparationTimeFilter.under15:
        return '<= 15 min';
      case ExplorePreparationTimeFilter.under30:
        return '<= 30 min';
      case ExplorePreparationTimeFilter.under60:
        return '<= 60 min';
      case ExplorePreparationTimeFilter.over60:
        return '> 60 min';
    }
  }

  static String _ratingFilterLabel(ExploreRatingFilter value) {
    switch (value) {
      case ExploreRatingFilter.all:
        return 'All';
      case ExploreRatingFilter.oneToTwo:
        return '1 - 2 star';
      case ExploreRatingFilter.twoToThree:
        return '2 - 3 star';
      case ExploreRatingFilter.threeToFour:
        return '3 - 4 star';
      case ExploreRatingFilter.fourToFive:
        return '4 - 5 star';
    }
  }

  static String _commentsFilterLabel(ExploreCommentsFilter value) {
    switch (value) {
      case ExploreCommentsFilter.all:
        return 'All';
      case ExploreCommentsFilter.under100:
        return '< 100';
      case ExploreCommentsFilter.over100:
        return '> 100';
      case ExploreCommentsFilter.between500And1000:
        return '500 - 1000';
    }
  }

  static String _viewsFilterLabel(ExploreViewsFilter value) {
    switch (value) {
      case ExploreViewsFilter.all:
        return 'All';
      case ExploreViewsFilter.under100:
        return '< 100';
      case ExploreViewsFilter.over100:
        return '> 100';
      case ExploreViewsFilter.between500And1000:
        return '500 - 1000';
    }
  }
}

class _OptionChipSection<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final Set<T> selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _OptionChipSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            'No options available',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final isSelected = selected.contains(value);
              return FilterChip(
                label: Text(labelBuilder(value)),
                selected: isSelected,
                onSelected: (_) => onSelected(value),
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                checkmarkColor: AppColors.primary,
                labelStyle: textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MultiFilterButtonSection<T> extends StatelessWidget {
  final String title;
  final Set<T> selected;
  final List<T> values;
  final T allValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<Set<T>> onSelected;

  const _MultiFilterButtonSection({
    required this.title,
    required this.selected,
    required this.values,
    required this.allValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            return FilterChip(
              label: Text(labelBuilder(value)),
              selected: isSelected,
              onSelected: (_) => onSelected(_nextSelection(value)),
              selectedColor: AppColors.primary.withValues(alpha: 0.14),
              checkmarkColor: AppColors.primary,
              labelStyle: textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Set<T> _nextSelection(T value) {
    if (value == allValue) return {allValue};
    final next = selected.where((item) => item != allValue).toSet();
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return next.isEmpty ? {allValue} : next;
  }
}

class _ExploreCreatorAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final double imageSize;
  final double iconSize;
  final bool hasBorder;

  const _ExploreCreatorAvatar({
    required this.imagePath,
    required this.radius,
    required this.imageSize,
    required this.iconSize,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: hasBorder ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: hasImage
            ? ClipOval(
                child: AppRemoteOrAssetImage(
                  imagePath: imagePath,
                  width: imageSize,
                  height: imageSize,
                ),
              )
            : Icon(Icons.person, color: AppColors.primary, size: iconSize),
      ),
    );
  }
}
