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
  int get postCount =>
      _recipes.where((recipe) => recipe.isSelfPublished).length;

  List<LibraryRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  List<LibraryRecipe> visibleRecipesFor(LibraryRecipeTab tab) {
    Iterable<LibraryRecipe> results = _recipes;

    switch (tab) {
      case LibraryRecipeTab.public:
        results = results.where(
          (recipe) => recipe.isSelfPublished && recipe.isPublished,
        );
        break;
      case LibraryRecipeTab.private:
        results = results.where(
          (recipe) => recipe.isSelfPublished && !recipe.isPublished,
        );
        break;
      case LibraryRecipeTab.favourites:
        results = results.where((recipe) => recipe.isFollowingAuthor);
        break;
    }

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
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

  bool shouldShowEmptyFor(LibraryRecipeTab tab) =>
      !_isLoading && _errorMessage == null && visibleRecipesFor(tab).isEmpty;

  Future<void> loadLibrary() async {
    _isLoading = _recipes.isEmpty && _profile == null;
    _errorMessage = null;
    _notifyIfActive();

    final profileResult = await _getProfileUseCase.execute();
    final recipesResult = await _getRecipesUseCase.execute();
    if (_isDisposed) return;

    profileResult.ifRight((profile) {
      _profile = profile;
    });
    profileResult.ifLeft((failure) {
      _errorMessage = failure.message;
    });

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
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notifyIfActive();
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
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
    final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (recipeIndex == -1) return false;

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
    );
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
