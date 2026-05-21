import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../../domain/usecases/get_library_profile_usecase.dart';
import '../../domain/usecases/get_library_recipes_usecase.dart';
import '../../domain/usecases/update_library_profile_usecase.dart';

class LibraryViewModel extends ChangeNotifier {
  final GetLibraryProfileUseCase _getProfileUseCase;
  final GetLibraryRecipesUseCase _getRecipesUseCase;
  final UpdateLibraryProfileUseCase _updateProfileUseCase;

  LibraryProfile? _profile;
  List<LibraryRecipe> _recipes = const [];
  LibraryRecipeTab _selectedTab = LibraryRecipeTab.public;
  String _query = '';
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isDisposed = false;
  String? _errorMessage;

  LibraryViewModel({
    required GetLibraryProfileUseCase getProfileUseCase,
    required GetLibraryRecipesUseCase getRecipesUseCase,
    required UpdateLibraryProfileUseCase updateProfileUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _getRecipesUseCase = getRecipesUseCase,
       _updateProfileUseCase = updateProfileUseCase {
    Future.microtask(loadLibrary);
  }

  LibraryProfile? get profile => _profile;
  List<LibraryRecipe> get recipes => _recipes;
  LibraryRecipeTab get selectedTab => _selectedTab;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSavingProfile => _isSavingProfile;
  String? get errorMessage => _errorMessage;
  int get postCount =>
      _recipes.where((recipe) => recipe.isSelfPublished).length;

  List<LibraryRecipe> get visibleRecipes {
    Iterable<LibraryRecipe> results = _recipes;

    switch (_selectedTab) {
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
        results = results.where(
          (recipe) => !recipe.isSelfPublished && recipe.isFollowingAuthor,
        );
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

  bool get shouldShowEmpty =>
      !_isLoading && _errorMessage == null && visibleRecipes.isEmpty;

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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
