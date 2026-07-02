import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/admin_moderation_recipe.dart';
import '../../domain/usecases/clear_admin_recipe_ai_flag_usecase.dart';
import '../../domain/usecases/mark_admin_recipe_reviewed_usecase.dart';
import '../../domain/usecases/update_admin_recipe_visibility_usecase.dart';
import '../../domain/usecases/watch_admin_moderation_recipes_usecase.dart';

/// ViewModel for the admin recipe moderation page.
class AdminModerationViewModel extends ChangeNotifier {
  final WatchAdminModerationRecipesUseCase _watchRecipesUseCase;
  final UpdateAdminRecipeVisibilityUseCase _updateRecipeVisibilityUseCase;
  final MarkAdminRecipeReviewedUseCase _markRecipeReviewedUseCase;
  final ClearAdminRecipeAiFlagUseCase _clearRecipeAiFlagUseCase;

  List<AdminModerationRecipe> _recipes = const [];
  StreamSubscription? _recipesSubscription;
  AdminModerationSortOption _sortOption = AdminModerationSortOption.newest;
  AdminModerationReviewFilter _reviewFilter = AdminModerationReviewFilter.all;
  String _query = '';
  bool _isLoading = true;
  bool _isUpdatingVisibility = false;
  bool _isDisposed = false;
  String? _errorMessage;

  /// Creates an admin moderation view model.
  AdminModerationViewModel({
    required WatchAdminModerationRecipesUseCase watchRecipesUseCase,
    required UpdateAdminRecipeVisibilityUseCase updateRecipeVisibilityUseCase,
    required MarkAdminRecipeReviewedUseCase markRecipeReviewedUseCase,
    required ClearAdminRecipeAiFlagUseCase clearRecipeAiFlagUseCase,
  }) : _watchRecipesUseCase = watchRecipesUseCase,
       _updateRecipeVisibilityUseCase = updateRecipeVisibilityUseCase,
       _markRecipeReviewedUseCase = markRecipeReviewedUseCase,
       _clearRecipeAiFlagUseCase = clearRecipeAiFlagUseCase {
    _watchRecipes();
  }

  /// Current search query.
  String get query => _query;

  /// Current sort option.
  AdminModerationSortOption get sortOption => _sortOption;

  /// Current review filter.
  AdminModerationReviewFilter get reviewFilter => _reviewFilter;

  /// Whether the list is loading.
  bool get isLoading => _isLoading;

  /// Whether a visibility update is in progress.
  bool get isUpdatingVisibility => _isUpdatingVisibility;

  /// Error message.
  String? get errorMessage => _errorMessage;

  /// Total recipe count before search/filter is applied.
  int get totalRecipeCount => _recipes.length;

  /// Count of recipes currently flagged by AI.
  int get aiFlaggedRecipeCount =>
      _recipes.where((recipe) => recipe.aiReviewFlagged).length;

  /// Filtered and sorted recipes.
  List<AdminModerationRecipe> get visibleRecipes {
    Iterable<AdminModerationRecipe> results = _recipes;
    final normalizedQuery = _query.trim().toLowerCase();

    if (normalizedQuery.isNotEmpty) {
      results = results.where((recipe) {
        return recipe.title.toLowerCase().contains(normalizedQuery) ||
            recipe.creatorName.toLowerCase().contains(normalizedQuery);
      });
    }

    if (_reviewFilter != AdminModerationReviewFilter.all) {
      final targetStatus = switch (_reviewFilter) {
        AdminModerationReviewFilter.reviewed =>
          AdminModerationReviewStatus.reviewed,
        AdminModerationReviewFilter.hidden =>
          AdminModerationReviewStatus.hidden,
        AdminModerationReviewFilter.pending =>
          AdminModerationReviewStatus.pending,
        AdminModerationReviewFilter.all => AdminModerationReviewStatus.pending,
      };
      results = results.where((recipe) => recipe.reviewStatus == targetStatus);
    }

    final sorted = results.toList();
    sorted.sort((first, second) {
      switch (_sortOption) {
        case AdminModerationSortOption.newest:
          return second.updatedAt.compareTo(first.updatedAt);
        case AdminModerationSortOption.oldest:
          return first.updatedAt.compareTo(second.updatedAt);
        case AdminModerationSortOption.alphabetAZ:
          return first.title.toLowerCase().compareTo(
            second.title.toLowerCase(),
          );
        case AdminModerationSortOption.alphabetZA:
          return second.title.toLowerCase().compareTo(
            first.title.toLowerCase(),
          );
      }
    });
    return sorted;
  }

  /// Updates the search query.
  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notifyIfActive();
  }

  /// Updates the sort option.
  void updateSortOption(AdminModerationSortOption value) {
    if (_sortOption == value) return;
    _sortOption = value;
    _notifyIfActive();
  }

  /// Updates the review status filter.
  void updateReviewFilter(AdminModerationReviewFilter value) {
    if (_reviewFilter == value) return;
    _reviewFilter = value;
    _notifyIfActive();
  }

  /// Updates a recipe visibility.
  Future<bool> updateVisibility({
    required String recipeId,
    required bool isPublished,
    String? hiddenReason,
  }) async {
    _isUpdatingVisibility = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _updateRecipeVisibilityUseCase.execute(
      recipeId: recipeId,
      isPublished: isPublished,
      hiddenReason: hiddenReason,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isUpdatingVisibility = false;
    _notifyIfActive();
    return success;
  }

  /// Marks a recipe as reviewed.
  Future<bool> markRecipeReviewed(String recipeId) async {
    _isUpdatingVisibility = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _markRecipeReviewedUseCase.execute(recipeId);
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isUpdatingVisibility = false;
    _notifyIfActive();
    return success;
  }

  /// Clears AI flag metadata from a recipe.
  Future<bool> clearRecipeAiFlag(String recipeId) async {
    _isUpdatingVisibility = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _clearRecipeAiFlagUseCase.execute(recipeId);
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isUpdatingVisibility = false;
    _notifyIfActive();
    return success;
  }

  /// Refreshes the moderation recipe stream.
  Future<void> refresh() async {
    await _recipesSubscription?.cancel();
    if (_isDisposed) return;

    _isLoading = _recipes.isEmpty;
    _errorMessage = null;
    _notifyIfActive();
    _watchRecipes();
  }

  void _watchRecipes() {
    _recipesSubscription = _watchRecipesUseCase.execute().listen((result) {
      result.ifRight((recipes) {
        _recipes = recipes;
        _errorMessage = null;
      });
      result.ifLeft((failure) {
        _errorMessage = failure.message;
      });

      _isLoading = false;
      _notifyIfActive();
    });
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _recipesSubscription?.cancel();
    super.dispose();
  }
}
