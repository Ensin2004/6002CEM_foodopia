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

enum ExploreRatingFilter { all, oneToTwo, twoToThree, threeToFour, fourToFive }

enum ExploreCommentsFilter { all, under100, over100, between500And1000 }

enum ExploreViewsFilter { all, under100, over100, between500And1000 }

enum ExplorePreparationTimeFilter { all, under15, under30, under60, over60 }

class ExploreViewModel extends ChangeNotifier {
  final GetExploreRecipesUseCase _getRecipesUseCase;
  final WatchExploreRecipesUseCase _watchRecipesUseCase;
  final GetAddRecipeSetupUseCase _getRecipeSetupUseCase;
  final GetAddRecipeIngredientCategoriesUseCase _getIngredientCategoriesUseCase;
  final GetMealCategoriesUseCase _getMealCategoriesUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;

  List<ExploreRecipe> _recipes = const [];
  List<ExploreRecipeCategoryOption> _recipeCategoryOptions = const [];
  List<ExploreRecipeCategoryOption> _ingredientCategoryOptions = const [];
  List<AddMealCategoryOption> _mealCategoryOptions = const [];
  StreamSubscription<List<ExploreRecipe>>? _recipesSubscription;
  ExploreRecipeTab _selectedTab = ExploreRecipeTab.all;
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
  String _query = '';
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

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
    Future.microtask(loadRecipes);
    Future.microtask(loadRecipeCategories);
    Future.microtask(loadIngredientCategories);
    Future.microtask(loadMealCategories);
    _watchRecipes();
  }

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

  List<ExploreRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  List<ExploreRecipe> visibleRecipesFor(ExploreRecipeTab tab) {
    Iterable<ExploreRecipe> results = _recipes;

    if (tab == ExploreRecipeTab.following) {
      results = results.where((recipe) => recipe.isFollowingAuthor);
    }

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      results = results.where(
        (recipe) => _searchScore(recipe, normalizedQuery) > 0.08,
      );
    }

    results = results.where(_matchesFilters);

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

  double _searchScore(ExploreRecipe recipe, String query) {
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
    final textScore = searchable.contains(query)
        ? 1.0
        : (queryTerms.isEmpty
              ? 0.0
              : queryTerms.where(searchable.contains).length /
                    queryTerms.length);
    final normalizedTags = recipe.tags.map((tag) => tag.toLowerCase()).toList();
    final tagMatches = queryTerms.where(
      (term) => normalizedTags.any(
        (tag) => tag.contains(term) || term.contains(tag),
      ),
    ).length;
    final tagScore = queryTerms.isEmpty ? 0.0 : tagMatches / queryTerms.length;
    return (tagScore * 0.65) + (textScore * 0.35);
  }

  bool get shouldShowFollowingEmpty =>
      shouldShowFollowingEmptyFor(_selectedTab);

  bool shouldShowFollowingEmptyFor(ExploreRecipeTab tab) =>
      !_isLoading &&
      _errorMessage == null &&
      tab == ExploreRecipeTab.following &&
      _recipes.where((recipe) => recipe.isFollowingAuthor).isEmpty;

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

  List<ExploreRecipeCategoryOption> get categoryOptions {
    final sorted = _recipeCategoryOptions.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
  }

  List<ExploreCreatorSummary> get suggestedCreators {
    final creators = <String, _SuggestedCreatorAccumulator>{};
    for (final recipe in _recipes) {
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

  List<ExploreRecipeCategoryOption> get ingredientCategoryOptions {
    final sorted = _ingredientCategoryOptions.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
  }

  List<String> get mealCategoryOptions {
    final sorted = _mealCategoryOptions
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((first, second) => first.compareTo(second));
    return sorted;
  }

  Future<void> loadMealCategories() async {
    final result = await _getMealCategoriesUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((categories) {
      _mealCategoryOptions = categories;
      _notifyIfActive();
    });
  }

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

  void selectTab(ExploreRecipeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notifyIfActive();
  }

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

  void updateSortOptions(Set<ExploreSortOption> options) {
    final nextOptions = options.isEmpty
        ? const {ExploreSortOption.alphabetAZ}
        : Set<ExploreSortOption>.unmodifiable(options);
    if (setEquals(_sortOptions, nextOptions)) return;
    _sortOptions = nextOptions;
    _notifyIfActive();
  }

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

  Set<T> _normalizeSet<T>(Set<T> values, T allValue) {
    if (values.isEmpty || values.contains(allValue)) {
      return Set<T>.unmodifiable({allValue});
    }
    return Set<T>.unmodifiable(values);
  }

  Future<bool> toggleCreatorFollow(String creatorUid) async {
    if (creatorUid.trim().isEmpty) return false;
    final shouldFollow = !_recipes.any(
      (recipe) => recipe.creatorUid == creatorUid && recipe.isFollowingAuthor,
    );
    final previousRecipes = _recipes;
    _recipes = _recipes.map((recipe) {
      if (recipe.creatorUid != creatorUid) return recipe;
      return _copyRecipe(recipe, isFollowingAuthor: shouldFollow);
    }).toList();
    _notifyIfActive();

    final result = await _toggleCreatorFollowUseCase.execute(
      creatorUid: creatorUid,
      follow: shouldFollow,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    if (!success) {
      _recipes = previousRecipes;
      _notifyIfActive();
    }
    return success;
  }

  Future<bool> toggleFavourite(String recipeId) async {
    final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (recipeIndex == -1) return false;
    final recipe = _recipes[recipeIndex];

    final nextFavourite = !recipe.isFavourite;
    final previousRecipes = _recipes;
    _recipes = _recipes.map((recipe) {
      if (recipe.id != recipeId) return recipe;
      return _copyRecipe(recipe, isFavourite: nextFavourite);
    }).toList();
    _errorMessage = null;
    _notifyIfActive();

    final result = await _toggleFavouriteUseCase.execute(
      recipeId: recipeId,
      isFavourite: nextFavourite,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    if (!success) {
      _recipes = previousRecipes;
      _notifyIfActive();
    }
    return success;
  }

  bool _matchesFilters(ExploreRecipe recipe) {
    final recipeCategoryMatches =
        _recipeCategoryFilters.isEmpty ||
        _recipeCategoryFilters.any((category) {
          final ids = category.isCustom
              ? recipe.customCategoryIds
              : recipe.categoryIds;
          return ids.contains(category.id);
        });
    final ingredientCategoryMatches =
        _ingredientCategoryFilters.isEmpty ||
        _ingredientCategoryFilters.any((category) {
          return recipe.ingredients.any((ingredient) {
            return ingredient.ingredientCategoryId == category.id ||
                ingredient.ingredientCategoryName.toLowerCase() ==
                    category.name.toLowerCase();
          });
        });
    final mealCategoryMatches =
        _mealCategoryFilters.isEmpty ||
        _mealCategoryFilters.any((meal) => _recipeMatchesMeal(recipe, meal));
    final preparationMatches =
        _preparationTimeFilters.contains(ExplorePreparationTimeFilter.all) ||
        _preparationTimeFilters.any(
          (filter) => _matchesPreparationTime(recipe, filter),
        );
    final ratingMatches =
        _ratingFilters.contains(ExploreRatingFilter.all) ||
        _ratingFilters.any((filter) => _matchesRating(recipe, filter));
    final commentsMatches =
        _commentsFilters.contains(ExploreCommentsFilter.all) ||
        _commentsFilters.any((filter) => _matchesComments(recipe, filter));
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

  bool _matchesComments(ExploreRecipe recipe, ExploreCommentsFilter filter) {
    return switch (filter) {
      ExploreCommentsFilter.all => true,
      ExploreCommentsFilter.under100 => recipe.commentCount < 100,
      ExploreCommentsFilter.over100 => recipe.commentCount > 100,
      ExploreCommentsFilter.between500And1000 =>
        recipe.commentCount >= 500 && recipe.commentCount <= 1000,
    };
  }

  bool _matchesViews(ExploreRecipe recipe, ExploreViewsFilter filter) {
    return switch (filter) {
      ExploreViewsFilter.all => true,
      ExploreViewsFilter.under100 => recipe.totalViews < 100,
      ExploreViewsFilter.over100 => recipe.totalViews > 100,
      ExploreViewsFilter.between500And1000 =>
        recipe.totalViews >= 500 && recipe.totalViews <= 1000,
    };
  }

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

  int _comparePopularRecipes(ExploreRecipe first, ExploreRecipe second) {
    final viewsComparison = second.totalViews.compareTo(first.totalViews);
    if (viewsComparison != 0) return viewsComparison;

    final ratingComparison = second.rating.compareTo(first.rating);
    if (ratingComparison != 0) return ratingComparison;

    return second.publishedAt.compareTo(first.publishedAt);
  }

  int _compareRecentRecipes(ExploreRecipe first, ExploreRecipe second) {
    return second.publishedAt.compareTo(first.publishedAt);
  }

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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

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

class _SuggestedCreatorAccumulator {
  final ExploreCreatorSummary summary;
  final int score;

  const _SuggestedCreatorAccumulator({
    required this.summary,
    required this.score,
  });
}
