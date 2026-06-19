import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_viewmodel.dart';
import 'explore_creator_avatar.dart';

// Enumerates filterable recipe attributes for sorting and refinement
enum ExploreFilterTarget {
  recipeCategory,
  meal,
  ingredients,
  preparationTime,
  comments,
  views,
}

class ExploreFilters extends StatefulWidget {
  final TabController tabController;
  final ExploreViewModel viewModel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ExploreFilterTarget?> onFilterTap;

  const ExploreFilters({
    super.key,
    required this.tabController,
    required this.viewModel,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<ExploreFilters> createState() => ExploreFiltersState();
}

class ExploreFiltersState extends State<ExploreFilters> {
  final _searchController = TextEditingController();
  final _recentSearches = <String>[];

  @override
  void didUpdateWidget(covariant ExploreFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronizes search field with external view model query changes
    if (_searchController.text != widget.viewModel.query) {
      _searchController.text = widget.viewModel.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Displays a full-screen search sheet and processes the selected query
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
        // Limits stored search history to six entries
        if (_recentSearches.length > 6) {
          _recentSearches.removeRange(6, _recentSearches.length);
        }
      });
    }
  }

  // Removes a specific search term from the history list
  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.removeWhere(
            (item) => item.toLowerCase() == search.toLowerCase(),
      );
    });
  }

  // Builds a sorted list of creator search suggestions based on popularity
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
    // Returns top five most popular creators
    return sorted.take(5).toList();
  }

  // Builds a list of recent recipe suggestions for discovery
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
                          // Clear button only appears when search text exists
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
                    // Filter pills for each recipe attribute category
                    _FilterPill(
                      icon: Icons.restaurant_menu,
                      label: 'Recipe Category',
                      onTap: () => widget.onFilterTap(
                        ExploreFilterTarget.recipeCategory,
                      ),
                    ),
                    _FilterPill(
                      icon: Icons.breakfast_dining,
                      label: 'Meal',
                      onTap: () => widget.onFilterTap(ExploreFilterTarget.meal),
                    ),
                    _FilterPill(
                      icon: Icons.eco,
                      label: 'Ingredients',
                      onTap: () =>
                          widget.onFilterTap(ExploreFilterTarget.ingredients),
                    ),
                    _FilterPill(
                      icon: Icons.timer_outlined,
                      label: 'Preparation Time',
                      onTap: () => widget.onFilterTap(
                        ExploreFilterTarget.preparationTime,
                      ),
                    ),
                    _FilterPill(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comments',
                      onTap: () =>
                          widget.onFilterTap(ExploreFilterTarget.comments),
                    ),
                    _FilterPill(
                      icon: Icons.visibility_outlined,
                      label: 'Views',
                      onTap: () =>
                          widget.onFilterTap(ExploreFilterTarget.views),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Tab bar for switching between recipe discovery modes
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

  // Converts recipe tab enum to display label string
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

// Interactive pill button for filter selection with icon and label
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

// Data model for creator search option with popularity scoring
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

// Data model for discovery search option with title and category
class _DiscoverSearchOption {
  final String title;
  final String category;

  const _DiscoverSearchOption({required this.title, required this.category});
}

// Full-screen search sheet displaying recent searches, discoveries, and creators
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

  // Closes the sheet and returns the trimmed search value
  void _submit(String value) {
    Navigator.of(context).pop(value.trim());
  }

  // Clears the search text field
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
                  // Discover section with grid of recipe suggestions
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
                  // Recent searches displayed as removable chips
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
                  // Creator recommendations section with avatars
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
                            leading: ExploreCreatorAvatar(
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

// Reusable sort button section for filter dialog
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

// Immutable data class holding all filter selection states
class RecipeFilterSelection {
  final Set<ExploreSortOption> sortOptions;
  final Set<ExploreRecipeCategoryOption> recipeCategories;
  final Set<ExploreRecipeCategoryOption> ingredientCategories;
  final Set<String> mealCategories;
  final Set<ExplorePreparationTimeFilter> preparationTimes;
  final Set<ExploreRatingFilter> ratings;
  final Set<ExploreCommentsFilter> comments;
  final Set<ExploreViewsFilter> views;

  const RecipeFilterSelection({
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

// Full-screen dialog for sorting and filtering recipes
class RecipeFilterDialog extends StatefulWidget {
  final List<ExploreRecipeCategoryOption> recipeCategories;
  final List<ExploreRecipeCategoryOption> ingredientCategories;
  final List<String> mealCategories;
  final ExploreFilterTarget? initialTarget;
  final RecipeFilterSelection initial;

  const RecipeFilterDialog({
    super.key,
    required this.recipeCategories,
    required this.ingredientCategories,
    required this.mealCategories,
    this.initialTarget,
    required this.initial,
  });

  @override
  State<RecipeFilterDialog> createState() => RecipeFilterDialogState();
}

class RecipeFilterDialogState extends State<RecipeFilterDialog> {
  // Mutable copies of filter selections for local state management
  late Set<ExploreSortOption> _sortOptions;
  late Set<ExploreRecipeCategoryOption> _recipeCategories;
  late Set<ExploreRecipeCategoryOption> _ingredientCategories;
  late Set<String> _mealCategories;
  late Set<ExplorePreparationTimeFilter> _preparationTimes;
  late Set<ExploreRatingFilter> _ratings;
  late Set<ExploreCommentsFilter> _comments;
  late Set<ExploreViewsFilter> _views;

  // Keys for scrolling to specific filter sections
  final _mealKey = GlobalKey();
  final _recipeCategoryKey = GlobalKey();
  final _ingredientsKey = GlobalKey();
  final _preparationTimeKey = GlobalKey();
  final _commentsKey = GlobalKey();
  final _viewsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initializes state from widget's initial filter selection
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

  // Scrolls to the initially selected filter target after build completes
  void _scrollToInitialTarget() {
    final target = widget.initialTarget;
    if (target == null) return;
    final key = switch (target) {
      ExploreFilterTarget.recipeCategory => _recipeCategoryKey,
      ExploreFilterTarget.meal => _mealKey,
      ExploreFilterTarget.ingredients => _ingredientsKey,
      ExploreFilterTarget.preparationTime => _preparationTimeKey,
      ExploreFilterTarget.comments => _commentsKey,
      ExploreFilterTarget.views => _viewsKey,
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
            // Header with close, title, and reset button
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
                    // Sort options section
                    _SortButtonSection(
                      title: 'Sort',
                      selected: _sortOptions,
                      values: ExploreSortOption.values,
                      labelBuilder: _sortLabel,
                      onSelected: _toggleSortOption,
                    ),
                    const SizedBox(height: 18),
                    // Meal category filter section
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
                    // Recipe category filter section
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
                    // Ingredient category filter section
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
                    // Preparation time filter section
                    KeyedSubtree(
                      key: _preparationTimeKey,
                      child:
                      _MultiFilterButtonSection<
                          ExplorePreparationTimeFilter
                      >(
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
                    // Ratings filter section
                    _MultiFilterButtonSection<ExploreRatingFilter>(
                      title: 'Ratings',
                      selected: _ratings,
                      values: ExploreRatingFilter.values,
                      allValue: ExploreRatingFilter.all,
                      labelBuilder: _ratingFilterLabel,
                      onSelected: (values) => setState(() => _ratings = values),
                    ),
                    const SizedBox(height: 18),
                    // Comments filter section
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
                    // Views filter section
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
            // Apply button at bottom
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

  // Resets all filters to their default states
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

  // Closes dialog and returns the current filter selection
  void _apply() {
    Navigator.of(context).pop(
      RecipeFilterSelection(
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

  // Toggles sort option with mutual exclusivity within its group
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
      // Ensures at least one sort option remains selected
      if (_sortOptions.isEmpty) _sortOptions.add(ExploreSortOption.alphabetAZ);
    });
  }

  // Toggles recipe category selection
  void _toggleRecipeCategory(ExploreRecipeCategoryOption option) {
    setState(() => _toggleOption(_recipeCategories, option));
  }

  // Toggles ingredient category selection
  void _toggleIngredientCategory(ExploreRecipeCategoryOption option) {
    setState(() => _toggleOption(_ingredientCategories, option));
  }

  // Toggles meal category selection
  void _toggleMealCategory(String option) {
    setState(() => _toggleOption(_mealCategories, option));
  }

  // Generic toggle method for any set-based filter
  void _toggleOption<T>(Set<T> values, T value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  // Converts sort option enum to display label
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

  // Converts preparation time filter enum to display label
  static String _preparationTimeFilterLabel(
      ExplorePreparationTimeFilter value,
      ) {
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

  // Converts rating filter enum to display label
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

  // Converts comments filter enum to display label
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

  // Converts views filter enum to display label
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

// Reusable section displaying filter chips for single-select or multi-select options
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

// Multi-select filter section with automatic "All" handling
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

  // Calculates the next selection state for a multi-select chip
  // Ensures "All" is selected when no other options are chosen
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