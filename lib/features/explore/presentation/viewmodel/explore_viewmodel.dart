import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_recipes_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';
import '../../domain/usecases/watch_explore_recipes_usecase.dart';

enum ExploreSortOption {
  none,
  alphabetAZ,
  alphabetZA,
  newest,
  oldest,
  ratingHighLow,
  ratingLowHigh,
  viewsHighLow,
  viewsLowHigh,
}

enum ExploreRatingFilter { all, one, two, three, four, five }

enum ExploreCommentsFilter { all, under100, over100, between500And1000 }

enum ExploreViewsFilter { all, under100, over100, between500And1000 }

class ExploreViewModel extends ChangeNotifier {
  final GetExploreRecipesUseCase _getRecipesUseCase;
  final WatchExploreRecipesUseCase _watchRecipesUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;

  List<ExploreRecipe> _recipes = const [];
  StreamSubscription<List<ExploreRecipe>>? _recipesSubscription;
  ExploreRecipeTab _selectedTab = ExploreRecipeTab.all;
  ExploreSortOption _sortOption = ExploreSortOption.none;
  ExploreRatingFilter _ratingFilter = ExploreRatingFilter.all;
  ExploreCommentsFilter _commentsFilter = ExploreCommentsFilter.all;
  ExploreViewsFilter _viewsFilter = ExploreViewsFilter.all;
  ExploreRecipeCategoryOption? _categoryFilter;
  String _query = '';
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  ExploreViewModel({
    required GetExploreRecipesUseCase getRecipesUseCase,
    required WatchExploreRecipesUseCase watchRecipesUseCase,
    required ToggleCreatorFollowUseCase toggleCreatorFollowUseCase,
  }) : _getRecipesUseCase = getRecipesUseCase,
       _watchRecipesUseCase = watchRecipesUseCase,
       _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase {
    Future.microtask(loadRecipes);
    _watchRecipes();
  }

  List<ExploreRecipe> get recipes => _recipes;
  ExploreRecipeTab get selectedTab => _selectedTab;
  ExploreSortOption get sortOption => _sortOption;
  ExploreRatingFilter get ratingFilter => _ratingFilter;
  ExploreCommentsFilter get commentsFilter => _commentsFilter;
  ExploreViewsFilter get viewsFilter => _viewsFilter;
  ExploreRecipeCategoryOption? get categoryFilter => _categoryFilter;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ExploreRecipe> get visibleRecipes {
    Iterable<ExploreRecipe> results = _recipes;

    if (_selectedTab == ExploreRecipeTab.following) {
      results = results.where((recipe) => recipe.isFollowingAuthor);
    } else if (_selectedTab == ExploreRecipeTab.recent) {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final nextWeekStart = weekStart.add(const Duration(days: 7));
      results = results.where(
        (recipe) =>
            !recipe.publishedAt.isBefore(weekStart) &&
            recipe.publishedAt.isBefore(nextWeekStart),
      );
    }

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      results = results.where(
        (recipe) =>
            recipe.title.toLowerCase().contains(normalizedQuery) ||
            recipe.otherNames.any(
              (name) => name.toLowerCase().contains(normalizedQuery),
            ) ||
            recipe.author.toLowerCase().contains(normalizedQuery) ||
            recipe.category.toLowerCase().contains(normalizedQuery) ||
            recipe.description.toLowerCase().contains(normalizedQuery),
      );
    }

    results = results.where(_matchesFilters);
    final category = _categoryFilter;
    if (category != null) {
      results = results.where((recipe) {
        final ids = category.isCustom
            ? recipe.customCategoryIds
            : recipe.categoryIds;
        return ids.contains(category.id);
      });
    }

    final sorted = results.toList();
    if (_selectedTab == ExploreRecipeTab.popular) {
      sorted.sort(
        (first, second) => second.totalViews.compareTo(first.totalViews),
      );
    } else {
      sorted.sort(_compareRecipes);
    }
    return sorted;
  }

  bool get shouldShowFollowingEmpty =>
      !_isLoading &&
      _errorMessage == null &&
      _selectedTab == ExploreRecipeTab.following &&
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
    final options = <String, ExploreRecipeCategoryOption>{};
    for (final recipe in _recipes) {
      final names = recipe.category
          .split(',')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      for (var index = 0; index < recipe.categoryIds.length; index++) {
        final id = recipe.categoryIds[index];
        options['standard:$id'] = ExploreRecipeCategoryOption(
          id: id,
          name: index < names.length ? names[index] : id,
          isCustom: false,
        );
      }
      for (var index = 0; index < recipe.customCategoryIds.length; index++) {
        final id = recipe.customCategoryIds[index];
        final nameIndex = recipe.categoryIds.length + index;
        options['custom:$id'] = ExploreRecipeCategoryOption(
          id: id,
          name: nameIndex < names.length ? names[nameIndex] : id,
          isCustom: true,
        );
      }
    }
    final sorted = options.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return sorted;
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

  void updateSortOption(ExploreSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _notifyIfActive();
  }

  void updateFilters({
    required ExploreRatingFilter rating,
    required ExploreCommentsFilter comments,
    required ExploreViewsFilter views,
  }) {
    if (_ratingFilter == rating &&
        _commentsFilter == comments &&
        _viewsFilter == views) {
      return;
    }
    _ratingFilter = rating;
    _commentsFilter = comments;
    _viewsFilter = views;
    _notifyIfActive();
  }

  void updateCategoryFilter(ExploreRecipeCategoryOption? option) {
    _categoryFilter = option;
    _notifyIfActive();
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

  bool _matchesFilters(ExploreRecipe recipe) {
    final roundedRating = recipe.rating.round();
    final ratingMatches = switch (_ratingFilter) {
      ExploreRatingFilter.all => true,
      ExploreRatingFilter.one => roundedRating == 1,
      ExploreRatingFilter.two => roundedRating == 2,
      ExploreRatingFilter.three => roundedRating == 3,
      ExploreRatingFilter.four => roundedRating == 4,
      ExploreRatingFilter.five => roundedRating == 5,
    };
    final commentsMatches = switch (_commentsFilter) {
      ExploreCommentsFilter.all => true,
      ExploreCommentsFilter.under100 => recipe.commentCount < 100,
      ExploreCommentsFilter.over100 => recipe.commentCount > 100,
      ExploreCommentsFilter.between500And1000 =>
        recipe.commentCount >= 500 && recipe.commentCount <= 1000,
    };
    final viewsMatches = switch (_viewsFilter) {
      ExploreViewsFilter.all => true,
      ExploreViewsFilter.under100 => recipe.totalViews < 100,
      ExploreViewsFilter.over100 => recipe.totalViews > 100,
      ExploreViewsFilter.between500And1000 =>
        recipe.totalViews >= 500 && recipe.totalViews <= 1000,
    };
    return ratingMatches && commentsMatches && viewsMatches;
  }

  int _compareRecipes(ExploreRecipe first, ExploreRecipe second) {
    return switch (_sortOption) {
      ExploreSortOption.none => 0,
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
      ExploreSortOption.ratingHighLow => second.rating.compareTo(first.rating),
      ExploreSortOption.ratingLowHigh => first.rating.compareTo(second.rating),
      ExploreSortOption.viewsHighLow => second.totalViews.compareTo(
        first.totalViews,
      ),
      ExploreSortOption.viewsLowHigh => first.totalViews.compareTo(
        second.totalViews,
      ),
    };
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  ExploreRecipe _copyRecipe(
    ExploreRecipe recipe, {
    required bool isFollowingAuthor,
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
      allergenInfo: recipe.allergenInfo,
      totalTime: recipe.totalTime,
      difficulty: recipe.difficulty,
      rating: recipe.rating,
      ratingCount: recipe.ratingCount,
      commentCount: recipe.commentCount,
      totalViews: recipe.totalViews,
      publishedAt: recipe.publishedAt,
      isFollowingAuthor: isFollowingAuthor,
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
