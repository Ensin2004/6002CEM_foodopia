import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../../domain/usecases/get_library_followers_usecase.dart';
import '../../domain/usecases/get_library_following_usecase.dart';
import '../../domain/usecases/get_library_profile_usecase.dart';
import '../../domain/usecases/get_library_recipes_usecase.dart';
import '../../domain/usecases/toggle_library_recipe_favourite_usecase.dart';
import '../../domain/usecases/update_library_profile_usecase.dart';

// Coordinates library profile, recipe tabs, favourites, connection lists, and profile editing state.
class LibraryViewModel extends ChangeNotifier {
  final GetLibraryProfileUseCase _getProfileUseCase;
  final GetLibraryFollowersUseCase _getFollowersUseCase;
  final GetLibraryFollowingUseCase _getFollowingUseCase;
  final GetLibraryRecipesUseCase _getRecipesUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;
  final UpdateLibraryProfileUseCase _updateProfileUseCase;

  LibraryProfile? _profile;
  List<LibraryProfileUser> _followers = const [];
  List<LibraryProfileUser> _following = const [];
  List<LibraryRecipe> _recipes = const [];
  LibraryRecipeTab _selectedTab = LibraryRecipeTab.public;
  String _query = '';
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isDisposed = false;
  String? _errorMessage;

  LibraryViewModel({
    required GetLibraryProfileUseCase getProfileUseCase,
    required GetLibraryFollowersUseCase getFollowersUseCase,
    required GetLibraryFollowingUseCase getFollowingUseCase,
    required GetLibraryRecipesUseCase getRecipesUseCase,
    required ToggleLibraryRecipeFavouriteUseCase toggleFavouriteUseCase,
    required UpdateLibraryProfileUseCase updateProfileUseCase,
    LibraryRecipeTab initialTab = LibraryRecipeTab.public,
  }) : _getProfileUseCase = getProfileUseCase,
       _getFollowersUseCase = getFollowersUseCase,
       _getFollowingUseCase = getFollowingUseCase,
       _getRecipesUseCase = getRecipesUseCase,
       _toggleFavouriteUseCase = toggleFavouriteUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _selectedTab = initialTab {
    // Loads the library after construction so widgets can subscribe before notifications fire.
    Future.microtask(loadLibrary);
  }

  LibraryProfile? get profile => _profile;
  List<LibraryProfileUser> get followers => _followers;
  List<LibraryProfileUser> get following => _following;
  List<LibraryRecipe> get recipes => _recipes;
  LibraryRecipeTab get selectedTab => _selectedTab;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSavingProfile => _isSavingProfile;
  bool get isLoadingFollowers => _isLoadingFollowers;
  bool get isLoadingFollowing => _isLoadingFollowing;
  String? get errorMessage => _errorMessage;
  // Counts only recipes created by the current account for the profile statistics row.
  int get postCount =>
      _recipes.where((recipe) => recipe.isSelfPublished).length;

  // Returns recipes matching the active library tab and search query.
  List<LibraryRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  List<LibraryRecipe> visibleRecipesFor(LibraryRecipeTab tab) {
    // Starts from the full recipe list before applying tab-specific filters.
    Iterable<LibraryRecipe> results = _recipes;

    switch (tab) {
      case LibraryRecipeTab.public:
        // Public tab contains owned recipes already visible to the community.
        results = results.where(
          (recipe) => recipe.isSelfPublished && recipe.isPublished,
        );
        break;
      case LibraryRecipeTab.private:
        // Private tab contains owned drafts or hidden recipes.
        results = results.where(
          (recipe) => recipe.isSelfPublished && !recipe.isPublished,
        );
        break;
      case LibraryRecipeTab.favourites:
        // Favourites tab contains saved recipes from other supported favourite sources.
        results = results.where((recipe) => recipe.isFollowingAuthor);
        break;
    }

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      // Filters recipes by title, category, or description when search text is present.
      results = results.where(
        (recipe) =>
            recipe.title.toLowerCase().contains(normalizedQuery) ||
            recipe.category.toLowerCase().contains(normalizedQuery) ||
            recipe.description.toLowerCase().contains(normalizedQuery),
      );
    }

    return results.toList();
  }

  bool get shouldShowEmpty => shouldShowEmptyFor(_selectedTab);

  // Shows an empty state only after loading finishes without an error.
  bool shouldShowEmptyFor(LibraryRecipeTab tab) =>
      !_isLoading && _errorMessage == null && visibleRecipesFor(tab).isEmpty;

  Future<void> loadLibrary() async {
    // Uses the full-page loading state only during the first profile and recipe load.
    _isLoading = _recipes.isEmpty && _profile == null;
    _errorMessage = null;
    _notifyIfActive();

    // Loads profile and recipe data from separate use cases before updating listeners.
    final profileResult = await _getProfileUseCase.execute();
    final recipesResult = await _getRecipesUseCase.execute();
    if (_isDisposed) return;

    // Saves profile results or captures the profile failure message.
    profileResult.ifRight((profile) {
      _profile = profile;
    });
    profileResult.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Saves recipe results or captures the recipe failure message.
    recipesResult.ifRight((recipes) {
      _recipes = recipes;
    });
    recipesResult.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectTab(LibraryRecipeTab tab) {
    // Avoids unnecessary rebuilds when the selected tab has not changed.
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  void updateQuery(String value) {
    // Updates search text only when the value changes.
    if (_query == value) return;
    _query = value;
    _notifyIfActive();
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    // Tracks save progress while the profile update use case writes profile changes.
    _isSavingProfile = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _updateProfileUseCase.execute(
      name: name,
      bio: bio,
      imageFile: imageFile,
    );
    if (_isDisposed) return false;

    var success = false;
    result.ifRight((_) {
      success = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Refreshes profile data after a successful update so the header shows the latest values.
    if (success) {
      final profileResult = await _getProfileUseCase.execute();
      if (_isDisposed) return false;
      profileResult.ifRight((profile) {
        _profile = profile;
      });
      profileResult.ifLeft((failure) {
        _errorMessage = failure.message;
        success = false;
      });
    }

    _isSavingProfile = false;
    _notifyIfActive();
    return success;
  }

  Future<bool> loadFollowers() async {
    // Loads follower profiles for features that need the list inside the library view model.
    _isLoadingFollowers = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getFollowersUseCase.execute();
    if (_isDisposed) return false;

    var success = false;
    result.ifRight((followers) {
      _followers = followers;
      success = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoadingFollowers = false;
    _notifyIfActive();
    return success;
  }

  Future<bool> loadFollowing() async {
    // Loads followed profile data for features that need the list inside the library view model.
    _isLoadingFollowing = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getFollowingUseCase.execute();
    if (_isDisposed) return false;

    var success = false;
    result.ifRight((following) {
      _following = following;
      success = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoadingFollowing = false;
    _notifyIfActive();
    return success;
  }

  Future<bool> toggleFavourite(String recipeId) async {
    // Finds the recipe before applying an optimistic favourite update.
    final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (recipeIndex == -1) return false;

    // Updates the local recipe list first so the favourite icon responds immediately.
    final originalRecipe = _recipes[recipeIndex];
    final nextFavourite = !originalRecipe.isFollowingAuthor;
    _recipes = [
      for (final recipe in _recipes)
        if (recipe.id == recipeId)
          _copyRecipe(recipe, isFollowingAuthor: nextFavourite)
        else
          recipe,
    ];
    _errorMessage = null;
    _notifyIfActive();

    // Persists the favourite change through the domain use case.
    final result = await _toggleFavouriteUseCase.execute(
      recipeId: recipeId,
      isFavourite: nextFavourite,
    );
    if (_isDisposed) return false;

    var success = false;
    result.ifRight((_) {
      success = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Restores the original recipe state when saving the favourite change fails.
    if (!success) {
      _recipes = [
        for (final recipe in _recipes)
          if (recipe.id == recipeId) originalRecipe else recipe,
      ];
      _notifyIfActive();
    }

    return success;
  }

  LibraryRecipe _copyRecipe(LibraryRecipe recipe, {bool? isFollowingAuthor}) {
    // Rebuilds a recipe entity with an updated favourite flag while preserving all other fields.
    return LibraryRecipe(
      id: recipe.id,
      title: recipe.title,
      author: recipe.author,
      publishedAtLabel: recipe.publishedAtLabel,
      authorAvatarPath: recipe.authorAvatarPath,
      imagePath: recipe.imagePath,
      imagePaths: recipe.imagePaths,
      description: recipe.description,
      category: recipe.category,
      allergenInfo: recipe.allergenInfo,
      totalTime: recipe.totalTime,
      difficulty: recipe.difficulty,
      servings: recipe.servings,
      rating: recipe.rating,
      ratingCount: recipe.ratingCount,
      commentCount: recipe.commentCount,
      totalViews: recipe.totalViews,
      isSelfPublished: recipe.isSelfPublished,
      isFollowingAuthor: isFollowingAuthor ?? recipe.isFollowingAuthor,
      isPublished: recipe.isPublished,
      ingredients: recipe.ingredients,
      instructionSections: recipe.instructionSections,
      nutrition: recipe.nutrition,
      community: recipe.community,
      relatedRecipes: recipe.relatedRecipes,
      isModerationHidden: recipe.isModerationHidden,
    );
  }

  void _notifyIfActive() {
    // Prevents listener notifications after dispose.
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    // Marks the view model inactive before ChangeNotifier disposal.
    _isDisposed = true;
    super.dispose();
  }
}
