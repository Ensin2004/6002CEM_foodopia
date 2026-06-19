import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_recipes_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';
import '../../domain/usecases/watch_explore_recipes_usecase.dart';
import '../../../library/domain/usecases/toggle_library_recipe_favourite_usecase.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../../meal_plan/domain/usecases/get_meal_categories_usecase.dart';
import '../../../recipe/domain/usecases/get_add_recipe_ingredient_categories_usecase.dart';
import '../../../recipe/domain/usecases/get_add_recipe_setup_usecase.dart';

/// Sort options available for ordering recipe lists.
enum ExploreSortOption {
  alphabetAZ,
  alphabetZA,
  newest,
  oldest,
  ratingHighLow,
  ratingLowHigh,
  viewsHighLow,
  viewsLowHigh,
}

/// Rating range filters for recipe filtering.
enum ExploreRatingFilter { all, oneToTwo, twoToThree, threeToFour, fourToFive }

/// Comment count filters for recipe filtering.
enum ExploreCommentsFilter { all, under100, over100, between500And1000 }

/// View count filters for recipe filtering.
enum ExploreViewsFilter { all, under100, over100, between500And1000 }

/// Preparation time filters for recipe filtering.
enum ExplorePreparationTimeFilter { all, under15, under30, under60, over60 }

/// ViewModel that manages the state and business logic for the recipe exploration feature.
/// Handles recipe fetching, filtering, sorting, searching, and user interactions.
class ExploreViewModel extends ChangeNotifier {
  // Use cases for data operations.
  final GetExploreRecipesUseCase _getRecipesUseCase;
  final WatchExploreRecipesUseCase _watchRecipesUseCase;
  final GetAddRecipeSetupUseCase _getRecipeSetupUseCase;
  final GetAddRecipeIngredientCategoriesUseCase _getIngredientCategoriesUseCase;
  final GetMealCategoriesUseCase _getMealCategoriesUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;

  // Core state variables.
  List<ExploreRecipe> _recipes = const [];
  List<ExploreRecipeCategoryOption> _recipeCategoryOptions = const [];
  List<ExploreRecipeCategoryOption> _ingredientCategoryOptions = const [];
  List<AddMealCategoryOption> _mealCategoryOptions = const [];
  StreamSubscription<List<ExploreRecipe>>? _recipesSubscription;
  ExploreRecipeTab _selectedTab = ExploreRecipeTab.all;

  // Filter and sort state.
  Set<ExploreSortOption> _sortOptions = const {ExploreSortOption.alphabetAZ};
  Set<ExploreRecipeCategoryOption> _recipeCategoryFilters = const {};
  Set<ExploreRecipeCategoryOption> _ingredientCategoryFilters = const {};
  Set<String> _mealCategoryFilters = const {};
  Set<ExplorePreparationTimeFilter> _preparationTimeFilters = const {
    ExplorePreparationTimeFilter.all,
  };
  Set<ExploreRatingFilter> _ratingFilters = const {ExploreRatingFilter.all};
  Set<ExploreCommentsFilter> _commentsFilters = const {
    ExploreCommentsFilter.all,
  };
  Set<ExploreViewsFilter> _viewsFilters = const {ExploreViewsFilter.all};

  // UI state.
  String _query = '';
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  /// Constructor initializes the ViewModel with required use cases.
  /// Loads initial data and starts listening to recipe stream.
  ExploreViewModel({
    required GetExploreRecipesUseCase getRecipesUseCase,
    required WatchExploreRecipesUseCase watchRecipesUseCase,
    required GetAddRecipeSetupUseCase getRecipeSetupUseCase,
    required GetAddRecipeIngredientCategoriesUseCase
    getIngredientCategoriesUseCase,
    required GetMealCategoriesUseCase getMealCategoriesUseCase,
    required ToggleCreatorFollowUseCase toggleCreatorFollowUseCase,
    required ToggleLibraryRecipeFavouriteUseCase toggleFavouriteUseCase,
  }) : _getRecipesUseCase = getRecipesUseCase,
        _watchRecipesUseCase = watchRecipesUseCase,
        _getRecipeSetupUseCase = getRecipeSetupUseCase,
        _getIngredientCategoriesUseCase = getIngredientCategoriesUseCase,
        _getMealCategoriesUseCase = getMealCategoriesUseCase,
        _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase,
        _toggleFavouriteUseCase = toggleFavouriteUseCase {
    // Defer initial data loading to avoid blocking the UI.
    Future.microtask(loadRecipes);
    Future.microtask(loadRecipeCategories);
    Future.microtask(loadIngredientCategories);
    Future.microtask(loadMealCategories);
    _watchRecipes();
  }

  // Getters for all state properties.
  List<ExploreRecipe> get recipes => _recipes;
  ExploreRecipeTab get selectedTab => _selectedTab;
  Set<ExploreSortOption> get sortOptions => _sortOptions;
  Set<ExploreRecipeCategoryOption> get recipeCategoryFilters =>
      _recipeCategoryFilters;
  Set<ExploreRecipeCategoryOption> get ingredientCategoryFilters =>
      _ingredientCategoryFilters;
  Set<String> get mealCategoryFilters => _mealCategoryFilters;
  Set<ExplorePreparationTimeFilter> get preparationTimeFilters =>
      _preparationTimeFilters;
  Set<ExploreRatingFilter> get ratingFilters => _ratingFilters;
  Set<ExploreCommentsFilter> get commentsFilters => _commentsFilters;
  Set<ExploreViewsFilter> get viewsFilters => _viewsFilters;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns filtered and sorted recipes for the currently selected tab.
  List<ExploreRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  /// Filters and sorts recipes for a specific tab with search and filter application.
  List<ExploreRecipe> visibleRecipesFor(ExploreRecipeTab tab) {
    Iterable<ExploreRecipe> results = _recipes;

    // Apply following filter if the following tab is selected.
    if (tab == ExploreRecipeTab.following) {
      results = results.where((recipe) => recipe.isFollowingAuthor);
    }

    // Apply search query filtering with relevance scoring.
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      results = results.where(
            (recipe) => _searchScore(recipe, normalizedQuery) > 0.08,
      );
    }

    // Apply all active filters.
    results = results.where(_matchesFilters);

    // Sort results by relevance or selected sort options.
    final sorted = results.toList();
    if (normalizedQuery.isNotEmpty) {
      sorted.sort((first, second) {
        final relevance = _searchScore(
          second,
          normalizedQuery,
        ).compareTo(_searchScore(first, normalizedQuery));
        return relevance != 0
            ? relevance
            : _compareRecipesForTab(tab)(first, second);
      });
    } else {
      sorted.sort(_compareRecipesForTab(tab));
    }
    return sorted;
  }

  /// Calculates a search relevance score for a recipe against the query.
  /// Combines text matching and tag matching scores.
  double _searchScore(ExploreRecipe recipe, String query) {
    // Build searchable text from all recipe fields.
    final searchable = [
      recipe.title,
      ...recipe.otherNames,
      recipe.author,
      recipe.category,
      recipe.description,
      ...recipe.ingredientNames,
      ...recipe.ingredients.map((ingredient) => ingredient.name),
    ].join(' ').toLowerCase();
    final queryTerms = query
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 1)
        .toSet();
    // Calculate text relevance score.
    final textScore = searchable.contains(query)
        ? 1.0
        : (queryTerms.isEmpty
        ? 0.0
        : queryTerms.where(searchable.contains).length /
        queryTerms.length);
    // Calculate tag relevance score.
    final normalizedTags = recipe.tags.map((tag) => tag.toLowerCase()).toList();
    final tagMatches = queryTerms.where(
          (term) => normalizedTags.any(
            (tag) => tag.contains(term) || term.contains(tag),
      ),
    ).length;
    final tagScore = queryTerms.isEmpty ? 0.0 : tagMatches / queryTerms.length;
    // Weighted combination: tags contribute more to relevance.
    return (tagScore * 0.65) + (textScore * 0.35);
  }

  /// Determines if the following tab should show the empty state.
  bool get shouldShowFollowingEmpty =>
      shouldShowFollowingEmptyFor(_selectedTab);

  /// Checks if a specific tab should show the empty state for following.
  bool shouldShowFollowingEmptyFor(ExploreRecipeTab tab) =>
      !_isLoading &&
          _errorMessage == null &&
          tab == ExploreRecipeTab.following &&
          _recipes.where((recipe) => recipe.isFollowingAuthor).isEmpty;

  /// Builds a deduplicated list of followed creators from the recipe list.
  List<ExploreCreatorSummary> get followedCreators {
    final creators = <String, ExploreCreatorSummary>{};
    for (final recipe in _recipes.where((recipe) => recipe.isFollowingAuthor)) {
      creators[recipe.creatorUid] = ExploreCreatorSummary(
        uid: recipe.creatorUid,
        name: recipe.author,
        avatarPath: recipe.authorAvatarPath,
        followerCount: recipe.authorFollowerCount,
        isFollowing: true,
      );
    }
    final sorted = creators.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
  }

  /// Returns sorted list of recipe category options available for filtering.
  List<ExploreRecipeCategoryOption> get categoryOptions {
    final sorted = _recipeCategoryOptions.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
  }

  /// Suggests creators based on recipe engagement metrics.
  /// Scores creators by total views, comments, and ratings.
  List<ExploreCreatorSummary> get suggestedCreators {
    final creators = <String, _SuggestedCreatorAccumulator>{};
    for (final recipe in _recipes) {
      // Skip recipes from current user or already followed creators.
      if (recipe.isCreatedByCurrentUser ||
          recipe.isFollowingAuthor ||
          recipe.creatorUid.trim().isEmpty) {
        continue;
      }
      final existing = creators[recipe.creatorUid];
      creators[recipe.creatorUid] = _SuggestedCreatorAccumulator(
        summary: ExploreCreatorSummary(
          uid: recipe.creatorUid,
          name: recipe.author == 'You' ? 'Creator' : recipe.author,
          avatarPath: recipe.authorAvatarPath,
          followerCount: recipe.authorFollowerCount,
          isFollowing: false,
        ),
        score:
        (existing?.score ?? 0) +
            recipe.totalViews +
            recipe.commentCount +
            recipe.ratingCount,
      );
    }
    final sorted = creators.values.toList()
      ..sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);
        if (scoreComparison != 0) return scoreComparison;
        return first.summary.name.compareTo(second.summary.name);
      });
    return sorted.map((creator) => creator.summary).toList(growable: false);
  }

  /// Returns sorted list of ingredient category options available for filtering.
  List<ExploreRecipeCategoryOption> get ingredientCategoryOptions {
    final sorted = _ingredientCategoryOptions.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
  }

  /// Returns sorted list of meal category names available for filtering.
  List<String> get mealCategoryOptions {
    final sorted = _mealCategoryOptions
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((first, second) => first.compareTo(second));
    return sorted;
  }

  /// Loads meal categories from the use case.
  Future<void> loadMealCategories() async {
    final result = await _getMealCategoriesUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((categories) {
      _mealCategoryOptions = categories;
      _notifyIfActive();
    });
  }

  /// Loads recipe categories from the setup use case.
  Future<void> loadRecipeCategories() async {
    final result = await _getRecipeSetupUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((setup) {
      _recipeCategoryOptions = setup.categories
          .map(
            (category) => ExploreRecipeCategoryOption(
          id: category.id,
          name: category.name,
          isCustom: false,
        ),
      )
          .toList(growable: false);
      _notifyIfActive();
    });
  }

  /// Loads ingredient categories from the use case.
  Future<void> loadIngredientCategories() async {
    final result = await _getIngredientCategoriesUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((categories) {
      _ingredientCategoryOptions = categories
          .map(
            (category) => ExploreRecipeCategoryOption(
          id: category.id,
          name: category.name,
          isCustom: false,
        ),
      )
          .toList(growable: false);
      _notifyIfActive();
    });
  }

  /// Loads recipes from the use case.
  /// Sets loading state and handles success or failure.
  Future<void> loadRecipes() async {
    _isLoading = _recipes.isEmpty;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getRecipesUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((recipes) {
      _recipes = recipes;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  /// Selects a tab and updates the view.
  void selectTab(ExploreRecipeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  /// Updates the search query and refreshes the view.
  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notifyIfActive();
  }

  /// Starts listening to the real-time recipe stream from the use case.
  void _watchRecipes() {
    _recipesSubscription = _watchRecipesUseCase.execute().listen(
          (recipes) {
        _recipes = recipes;
        _isLoading = false;
        _errorMessage = null;
        _notifyIfActive();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        _notifyIfActive();
      },
    );
  }

  /// Updates the sort options and ensures at least one option is selected.
  void updateSortOptions(Set<ExploreSortOption> options) {
    final nextOptions = options.isEmpty
        ? const {ExploreSortOption.alphabetAZ}
        : Set<ExploreSortOption>.unmodifiable(options);
    if (setEquals(_sortOptions, nextOptions)) return;
    _sortOptions = nextOptions;
    _notifyIfActive();
  }

  /// Updates all filter sets with new values from the filter dialog.
  void updateFilters({
    required Set<ExploreRecipeCategoryOption> recipeCategories,
    required Set<ExploreRecipeCategoryOption> ingredientCategories,
    required Set<String> mealCategories,
    required Set<ExplorePreparationTimeFilter> preparationTimes,
    required Set<ExploreRatingFilter> ratings,
    required Set<ExploreCommentsFilter> comments,
    required Set<ExploreViewsFilter> views,
  }) {
    final nextRecipeCategories = Set<ExploreRecipeCategoryOption>.unmodifiable(
      recipeCategories,
    );
    final nextIngredientCategories =
    Set<ExploreRecipeCategoryOption>.unmodifiable(ingredientCategories);
    final nextMealCategories = Set<String>.unmodifiable(mealCategories);
    final nextPreparationTimes = _normalizeSet(
      preparationTimes,
      ExplorePreparationTimeFilter.all,
    );
    final nextRatings = _normalizeSet(ratings, ExploreRatingFilter.all);
    final nextComments = _normalizeSet(comments, ExploreCommentsFilter.all);
    final nextViews = _normalizeSet(views, ExploreViewsFilter.all);
    // Skip update if no changes detected.
    if (setEquals(_recipeCategoryFilters, nextRecipeCategories) &&
        setEquals(_ingredientCategoryFilters, nextIngredientCategories) &&
        setEquals(_mealCategoryFilters, nextMealCategories) &&
        setEquals(_preparationTimeFilters, nextPreparationTimes) &&
        setEquals(_ratingFilters, nextRatings) &&
        setEquals(_commentsFilters, nextComments) &&
        setEquals(_viewsFilters, nextViews)) {
      return;
    }
    _recipeCategoryFilters = nextRecipeCategories;
    _ingredientCategoryFilters = nextIngredientCategories;
    _mealCategoryFilters = nextMealCategories;
    _preparationTimeFilters = nextPreparationTimes;
    _ratingFilters = nextRatings;
    _commentsFilters = nextComments;
    _viewsFilters = nextViews;
    _notifyIfActive();
  }

  /// Normalizes a set by ensuring the 'all' value is used when the set is empty or contains 'all'.
  Set<T> _normalizeSet<T>(Set<T> values, T allValue) {
    if (values.isEmpty || values.contains(allValue)) {
      return Set<T>.unmodifiable({allValue});
    }
    return Set<T>.unmodifiable(values);
  }

  /// Toggles follow status for a creator with optimistic update.
  /// Reverts changes if the operation fails.
  Future<bool> toggleCreatorFollow(String creatorUid) async {
    if (creatorUid.trim().isEmpty) return false;
    final shouldFollow = !_recipes.any(
          (recipe) => recipe.creatorUid == creatorUid && recipe.isFollowingAuthor,
    );
    // Optimistically update the UI.
    final previousRecipes = _recipes;
    _recipes = _recipes.map((recipe) {
      if (recipe.creatorUid != creatorUid) return recipe;
      return _copyRecipe(recipe, isFollowingAuthor: shouldFollow);
    }).toList();
    _notifyIfActive();

    // Execute the actual follow operation.
    final result = await _toggleCreatorFollowUseCase.execute(
      creatorUid: creatorUid,
      follow: shouldFollow,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    // Revert on failure to maintain consistency.
    if (!success) {
      _recipes = previousRecipes;
      _notifyIfActive();
    }
    return success;
  }

  /// Toggles favourite status for a recipe with optimistic update.
  /// Reverts changes if the operation fails.
  Future<bool> toggleFavourite(String recipeId) async {
    final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (recipeIndex == -1) return false;
    final recipe = _recipes[recipeIndex];

    final nextFavourite = !recipe.isFavourite;
    // Optimistically update the UI.
    final previousRecipes = _recipes;
    _recipes = _recipes.map((recipe) {
      if (recipe.id != recipeId) return recipe;
      return _copyRecipe(recipe, isFavourite: nextFavourite);
    }).toList();
    _errorMessage = null;
    _notifyIfActive();

    // Execute the actual favourite toggle operation.
    final result = await _toggleFavouriteUseCase.execute(
      recipeId: recipeId,
      isFavourite: nextFavourite,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    // Revert on failure to maintain consistency.
    if (!success) {
      _recipes = previousRecipes;
      _notifyIfActive();
    }
    return success;
  }

  /// Checks if a recipe matches all currently active filters.
  bool _matchesFilters(ExploreRecipe recipe) {
    // Check recipe category filter.
    final recipeCategoryMatches =
        _recipeCategoryFilters.isEmpty ||
            _recipeCategoryFilters.any((category) {
              final ids = category.isCustom
                  ? recipe.customCategoryIds
                  : recipe.categoryIds;
              return ids.contains(category.id);
            });
    // Check ingredient category filter.
    final ingredientCategoryMatches =
        _ingredientCategoryFilters.isEmpty ||
            _ingredientCategoryFilters.any((category) {
              return recipe.ingredients.any((ingredient) {
                return ingredient.ingredientCategoryId == category.id ||
                    ingredient.ingredientCategoryName.toLowerCase() ==
                        category.name.toLowerCase();
              });
            });
    // Check meal category filter.
    final mealCategoryMatches =
        _mealCategoryFilters.isEmpty ||
            _mealCategoryFilters.any((meal) => _recipeMatchesMeal(recipe, meal));
    // Check preparation time filter.
    final preparationMatches =
        _preparationTimeFilters.contains(ExplorePreparationTimeFilter.all) ||
            _preparationTimeFilters.any(
                  (filter) => _matchesPreparationTime(recipe, filter),
            );
    // Check rating filter.
    final ratingMatches =
        _ratingFilters.contains(ExploreRatingFilter.all) ||
            _ratingFilters.any((filter) => _matchesRating(recipe, filter));
    // Check comments filter.
    final commentsMatches =
        _commentsFilters.contains(ExploreCommentsFilter.all) ||
            _commentsFilters.any((filter) => _matchesComments(recipe, filter));
    // Check views filter.
    final viewsMatches =
        _viewsFilters.contains(ExploreViewsFilter.all) ||
            _viewsFilters.any((filter) => _matchesViews(recipe, filter));
    return recipeCategoryMatches &&
        ingredientCategoryMatches &&
        mealCategoryMatches &&
        preparationMatches &&
        ratingMatches &&
        commentsMatches &&
        viewsMatches;
  }

  /// Determines if a recipe matches a meal category search term.
  bool _recipeMatchesMeal(ExploreRecipe recipe, String meal) {
    final normalizedMeal = meal.toLowerCase();
    final searchable = [
      recipe.title,
      recipe.category,
      ...recipe.tags,
      ...recipe.otherNames,
    ].join(' ').toLowerCase();
    return searchable.contains(normalizedMeal);
  }

  /// Checks if a recipe's preparation time matches the filter criteria.
  bool _matchesPreparationTime(
      ExploreRecipe recipe,
      ExplorePreparationTimeFilter filter,
      ) {
    final minutes = int.tryParse(
      RegExp(r'\d+').firstMatch(recipe.totalTime)?.group(0) ?? '',
    );
    if (minutes == null) return false;
    return switch (filter) {
      ExplorePreparationTimeFilter.all => true,
      ExplorePreparationTimeFilter.under15 => minutes <= 15,
      ExplorePreparationTimeFilter.under30 => minutes <= 30,
      ExplorePreparationTimeFilter.under60 => minutes <= 60,
      ExplorePreparationTimeFilter.over60 => minutes > 60,
    };
  }

  /// Checks if a recipe's rating falls within the filter range.
  bool _matchesRating(ExploreRecipe recipe, ExploreRatingFilter filter) {
    return switch (filter) {
      ExploreRatingFilter.all => true,
      ExploreRatingFilter.oneToTwo => recipe.rating >= 1 && recipe.rating < 2,
      ExploreRatingFilter.twoToThree => recipe.rating >= 2 && recipe.rating < 3,
      ExploreRatingFilter.threeToFour =>
      recipe.rating >= 3 && recipe.rating < 4,
      ExploreRatingFilter.fourToFive =>
      recipe.rating >= 4 && recipe.rating <= 5,
    };
  }

  /// Checks if a recipe's comment count matches the filter criteria.
  bool _matchesComments(ExploreRecipe recipe, ExploreCommentsFilter filter) {
    return switch (filter) {
      ExploreCommentsFilter.all => true,
      ExploreCommentsFilter.under100 => recipe.commentCount < 100,
      ExploreCommentsFilter.over100 => recipe.commentCount > 100,
      ExploreCommentsFilter.between500And1000 =>
      recipe.commentCount >= 500 && recipe.commentCount <= 1000,
    };
  }

  /// Checks if a recipe's view count matches the filter criteria.
  bool _matchesViews(ExploreRecipe recipe, ExploreViewsFilter filter) {
    return switch (filter) {
      ExploreViewsFilter.all => true,
      ExploreViewsFilter.under100 => recipe.totalViews < 100,
      ExploreViewsFilter.over100 => recipe.totalViews > 100,
      ExploreViewsFilter.between500And1000 =>
      recipe.totalViews >= 500 && recipe.totalViews <= 1000,
    };
  }

  /// Compares two recipes based on the active sort options.
  /// Applies sort options in priority order.
  int _compareRecipes(ExploreRecipe first, ExploreRecipe second) {
    for (final option in _sortPriority) {
      if (!_sortOptions.contains(option)) continue;
      final comparison = switch (option) {
        ExploreSortOption.alphabetAZ => first.title.toLowerCase().compareTo(
          second.title.toLowerCase(),
        ),
        ExploreSortOption.alphabetZA => second.title.toLowerCase().compareTo(
          first.title.toLowerCase(),
        ),
        ExploreSortOption.newest => second.publishedAt.compareTo(
          first.publishedAt,
        ),
        ExploreSortOption.oldest => first.publishedAt.compareTo(
          second.publishedAt,
        ),
        ExploreSortOption.ratingHighLow => second.rating.compareTo(
          first.rating,
        ),
        ExploreSortOption.ratingLowHigh => first.rating.compareTo(
          second.rating,
        ),
        ExploreSortOption.viewsHighLow => second.totalViews.compareTo(
          first.totalViews,
        ),
        ExploreSortOption.viewsLowHigh => first.totalViews.compareTo(
          second.totalViews,
        ),
      };
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  /// Returns the appropriate comparison function for a given tab.
  int Function(ExploreRecipe first, ExploreRecipe second) _compareRecipesForTab(
      ExploreRecipeTab tab,
      ) {
    switch (tab) {
      case ExploreRecipeTab.popular:
        return _comparePopularRecipes;
      case ExploreRecipeTab.recent:
        return _compareRecentRecipes;
      case ExploreRecipeTab.all:
      case ExploreRecipeTab.following:
        return _compareRecipes;
    }
  }

  /// Compares recipes by popularity: views first, then rating, then recency.
  int _comparePopularRecipes(ExploreRecipe first, ExploreRecipe second) {
    final viewsComparison = second.totalViews.compareTo(first.totalViews);
    if (viewsComparison != 0) return viewsComparison;

    final ratingComparison = second.rating.compareTo(first.rating);
    if (ratingComparison != 0) return ratingComparison;

    return second.publishedAt.compareTo(first.publishedAt);
  }

  /// Compares recipes by recency: newest first.
  int _compareRecentRecipes(ExploreRecipe first, ExploreRecipe second) {
    return second.publishedAt.compareTo(first.publishedAt);
  }

  // Priority order for applying sort options.
  static const _sortPriority = [
    ExploreSortOption.newest,
    ExploreSortOption.oldest,
    ExploreSortOption.ratingHighLow,
    ExploreSortOption.ratingLowHigh,
    ExploreSortOption.viewsHighLow,
    ExploreSortOption.viewsLowHigh,
    ExploreSortOption.alphabetAZ,
    ExploreSortOption.alphabetZA,
  ];

  /// Notifies listeners only if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  /// Creates a copy of a recipe with optional updated fields.
  ExploreRecipe _copyRecipe(
      ExploreRecipe recipe, {
        bool? isFollowingAuthor,
        bool? isFavourite,
      }) {
    return ExploreRecipe(
      id: recipe.id,
      creatorUid: recipe.creatorUid,
      title: recipe.title,
      author: recipe.author,
      publishedAtLabel: recipe.publishedAtLabel,
      authorAvatarPath: recipe.authorAvatarPath,
      authorFollowerCount: recipe.authorFollowerCount,
      imagePath: recipe.imagePath,
      imagePaths: recipe.imagePaths,
      description: recipe.description,
      otherNames: recipe.otherNames,
      category: recipe.category,
      categoryIds: recipe.categoryIds,
      customCategoryIds: recipe.customCategoryIds,
      tags: recipe.tags,
      ingredientNames: recipe.ingredientNames,
      allergenInfo: recipe.allergenInfo,
      totalTime: recipe.totalTime,
      difficulty: recipe.difficulty,
      servings: recipe.servings,
      rating: recipe.rating,
      ratingCount: recipe.ratingCount,
      commentCount: recipe.commentCount,
      totalViews: recipe.totalViews,
      publishedAt: recipe.publishedAt,
      isFollowingAuthor: isFollowingAuthor ?? recipe.isFollowingAuthor,
      isFavourite: isFavourite ?? recipe.isFavourite,
      isCreatedByCurrentUser: recipe.isCreatedByCurrentUser,
      ingredients: recipe.ingredients,
      instructionSections: recipe.instructionSections,
      nutrition: recipe.nutrition,
      community: recipe.community,
      relatedRecipes: recipe.relatedRecipes,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _recipesSubscription?.cancel();
    super.dispose();
  }
}

/// Internal accumulator for building suggested creator scores.
class _SuggestedCreatorAccumulator {
  final ExploreCreatorSummary summary;
  final int score;

  const _SuggestedCreatorAccumulator({
    required this.summary,
    required this.score,
  });
}