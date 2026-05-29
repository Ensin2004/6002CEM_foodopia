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
              onSortTap: () => _showSortSheet(context, viewModel),
              onFilterTap: () => _showFilterSheet(context, viewModel),
              onCategoryChanged: viewModel.updateCategoryFilter,
            ),
            Expanded(
              child: _ExploreContent(
                viewModel: viewModel,
                mealPlanSelection: widget.mealPlanSelection,
                onExploreNow: () => _selectTab(ExploreRecipeTab.all),
                onCommentTap: _showCommentsPopup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSortSheet(
    BuildContext context,
    ExploreViewModel viewModel,
  ) async {
    final selected = await showModalBottomSheet<Set<ExploreSortOption>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) =>
          _RecipeSortSheet(selected: viewModel.sortOptions),
    );
    if (selected != null) viewModel.updateSortOptions(selected);
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    ExploreViewModel viewModel,
  ) async {
    final selected = await showModalBottomSheet<_RecipeFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RecipeFilterSheet(
        initial: _RecipeFilterSelection(
          rating: viewModel.ratingFilter,
          comments: viewModel.commentsFilter,
          views: viewModel.viewsFilter,
        ),
      ),
    );
    if (selected != null) {
      viewModel.updateFilters(
        rating: selected.rating,
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
  final ExploreViewModel viewModel;
  final MealPlanSelectionArgs? mealPlanSelection;
  final VoidCallback onExploreNow;
  final ValueChanged<ExploreRecipe> onCommentTap;

  const _ExploreContent({
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

    if (viewModel.shouldShowFollowingEmpty) {
      return ExploreEmptyState(onExploreNow: onExploreNow);
    }

    if (viewModel.selectedTab == ExploreRecipeTab.following) {
      return _FollowingCreatorsList(
        creators: viewModel.followedCreators,
        onToggleFollow: viewModel.toggleCreatorFollow,
      );
    }

    final recipes = viewModel.visibleRecipes;
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

class _FollowingCreatorsList extends StatelessWidget {
  final List<ExploreCreatorSummary> creators;
  final ValueChanged<String> onToggleFollow;

  const _FollowingCreatorsList({
    required this.creators,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: creators.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final creator = creators[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: AppRemoteOrAssetAvatar(
            radius: 26,
            imagePath: creator.avatarPath,
          ),
          title: Text(
            creator.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            '${_compactCount(creator.followerCount)} Followers',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: FilledButton.icon(
            onPressed: () => onToggleFollow(creator.uid),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.check, size: 15),
            label: const Text(
              'Following',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          onTap: () {
            context.push(
              AppRouter.exploreCreatorDetail,
              extra: ExploreCreatorDetailArgs(creatorUid: creator.uid),
            );
          },
        );
      },
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
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;
  final ValueChanged<ExploreRecipeCategoryOption?> onCategoryChanged;

  const _ExploreFilters({
    required this.tabController,
    required this.viewModel,
    required this.onSearchChanged,
    required this.onSortTap,
    required this.onFilterTap,
    required this.onCategoryChanged,
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
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onSortTap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 25,
                      height: 30,
                    ),
                    icon: const Icon(
                      Icons.sort,
                      size: 25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: widget.onFilterTap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 25,
                      height: 30,
                    ),
                    icon: const Icon(
                      Icons.filter_alt,
                      size: 25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryDropdown(
                      selected: widget.viewModel.categoryFilter,
                      options: widget.viewModel.categoryOptions,
                      onChanged: widget.onCategoryChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  readOnly: true,
                  onTap: _openSearchMenu,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search food, brand, category, ...',
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close, size: 18),
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
                            leading: AppRemoteOrAssetAvatar(
                              radius: 18,
                              imagePath: creator.avatarPath,
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

class _CategoryDropdown extends StatelessWidget {
  final ExploreRecipeCategoryOption? selected;
  final List<ExploreRecipeCategoryOption> options;
  final ValueChanged<ExploreRecipeCategoryOption?> onChanged;

  const _CategoryDropdown({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      onSelected: (value) {
        if (value == 'all') {
          onChanged(null);
          return;
        }
        for (final option in options) {
          final key = '${option.isCustom ? 'custom' : 'standard'}:${option.id}';
          if (key == value) {
            onChanged(option);
            return;
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All')),
        ...options.map((option) {
          return PopupMenuItem(
            value: '${option.isCustom ? 'custom' : 'standard'}:${option.id}',
            child: Text(option.name),
          );
        }),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.name ?? 'All',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSortSheet extends StatefulWidget {
  final Set<ExploreSortOption> selected;

  const _RecipeSortSheet({required this.selected});

  @override
  State<_RecipeSortSheet> createState() => _RecipeSortSheetState();
}

class _RecipeSortSheetState extends State<_RecipeSortSheet> {
  late Set<ExploreSortOption> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
  }

  void _toggleSortOption(
    ExploreSortOption option,
    List<ExploreSortOption> group,
  ) {
    setState(() {
      if (_selected.contains(option)) {
        _selected.remove(option);
      } else {
        _selected.removeAll(group);
        _selected.add(option);
      }
      if (_selected.isEmpty) {
        _selected.add(ExploreSortOption.alphabetAZ);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Recipes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SortButtonSection(
              title: 'By Alphabet:',
              selected: _selected,
              values: const [
                ExploreSortOption.alphabetAZ,
                ExploreSortOption.alphabetZA,
              ],
              labelBuilder: _sortLabel,
              onSelected: _toggleSortOption,
            ),
            const SizedBox(height: 14),
            _SortButtonSection(
              title: 'By Date:',
              selected: _selected,
              values: const [
                ExploreSortOption.newest,
                ExploreSortOption.oldest,
              ],
              labelBuilder: _sortLabel,
              onSelected: _toggleSortOption,
            ),
            const SizedBox(height: 14),
            _SortButtonSection(
              title: 'By Rating:',
              selected: _selected,
              values: const [
                ExploreSortOption.ratingHighLow,
                ExploreSortOption.ratingLowHigh,
              ],
              labelBuilder: _sortLabel,
              onSelected: _toggleSortOption,
            ),
            const SizedBox(height: 14),
            _SortButtonSection(
              title: 'By Views:',
              selected: _selected,
              values: const [
                ExploreSortOption.viewsHighLow,
                ExploreSortOption.viewsLowHigh,
              ],
              labelBuilder: _sortLabel,
              onSelected: _toggleSortOption,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Apply Sort'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sortLabel(ExploreSortOption option) {
    switch (option) {
      case ExploreSortOption.alphabetAZ:
        return 'Alphabet: A-Z';
      case ExploreSortOption.alphabetZA:
        return 'Alphabet: Z-A';
      case ExploreSortOption.newest:
        return 'Date: Newest';
      case ExploreSortOption.oldest:
        return 'Date: Oldest';
      case ExploreSortOption.ratingHighLow:
        return 'Rating: High-Low';
      case ExploreSortOption.ratingLowHigh:
        return 'Rating: Low-High';
      case ExploreSortOption.viewsHighLow:
        return 'Views: High-Low';
      case ExploreSortOption.viewsLowHigh:
        return 'Views: Low-High';
    }
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
  final ExploreRatingFilter rating;
  final ExploreCommentsFilter comments;
  final ExploreViewsFilter views;

  const _RecipeFilterSelection({
    required this.rating,
    required this.comments,
    required this.views,
  });
}

class _RecipeFilterSheet extends StatefulWidget {
  final _RecipeFilterSelection initial;

  const _RecipeFilterSheet({required this.initial});

  @override
  State<_RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<_RecipeFilterSheet> {
  late ExploreRatingFilter _rating;
  late ExploreCommentsFilter _comments;
  late ExploreViewsFilter _views;

  @override
  void initState() {
    super.initState();
    _rating = widget.initial.rating;
    _comments = widget.initial.comments;
    _views = widget.initial.views;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Recipes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _FilterButtonSection<ExploreRatingFilter>(
                title: 'Ratings',
                selected: _rating,
                values: ExploreRatingFilter.values,
                labelBuilder: _ratingFilterLabel,
                onSelected: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 14),
              _FilterButtonSection<ExploreCommentsFilter>(
                title: 'Comments',
                selected: _comments,
                values: ExploreCommentsFilter.values,
                labelBuilder: _commentsFilterLabel,
                onSelected: (value) => setState(() => _comments = value),
              ),
              const SizedBox(height: 14),
              _FilterButtonSection<ExploreViewsFilter>(
                title: 'Views',
                selected: _views,
                values: ExploreViewsFilter.values,
                labelBuilder: _viewsFilterLabel,
                onSelected: (value) => setState(() => _views = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _RecipeFilterSelection(
                      rating: _rating,
                      comments: _comments,
                      views: _views,
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _FilterButtonSection<T> extends StatelessWidget {
  final String title;
  final T selected;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _FilterButtonSection({
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
            final isSelected = value == selected;
            return ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
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
