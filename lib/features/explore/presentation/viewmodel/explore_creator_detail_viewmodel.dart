import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../library/domain/usecases/toggle_library_recipe_favourite_usecase.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_creator_detail_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';

/// Tabs for filtering a creator's recipes: all, popular, or recent.
enum ExploreCreatorRecipeTab { all, popular, recent }

/// ViewModel that manages the state and business logic for the creator detail screen.
/// Handles fetching creator information, recipe lists, follow toggling, and favourite management.
class ExploreCreatorDetailViewModel extends ChangeNotifier {
  // Use cases for data operations.
  final GetExploreCreatorDetailUseCase _getCreatorDetailUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;
  final String creatorUid;

  // Core state.
  ExploreCreatorDetail? _creator;
  ExploreCreatorRecipeTab _selectedTab = ExploreCreatorRecipeTab.all;

  // UI state.
  bool _isLoading = true;
  bool _isUpdatingFollow = false;
  bool _isDisposed = false;
  String? _errorMessage;

  /// Constructor initializes the ViewModel with required use cases.
  /// Triggers immediate loading of creator data.
  ExploreCreatorDetailViewModel({
    required this.creatorUid,
    required GetExploreCreatorDetailUseCase getCreatorDetailUseCase,
    required ToggleCreatorFollowUseCase toggleCreatorFollowUseCase,
    required ToggleLibraryRecipeFavouriteUseCase toggleFavouriteUseCase,
  }) : _getCreatorDetailUseCase = getCreatorDetailUseCase,
        _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase,
        _toggleFavouriteUseCase = toggleFavouriteUseCase {
    // Defer loading to avoid blocking the UI initialization.
    Future.microtask(loadCreator);
  }

  // Getters for all state properties.
  ExploreCreatorDetail? get creator => _creator;
  ExploreCreatorRecipeTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  bool get isUpdatingFollow => _isUpdatingFollow;
  String? get errorMessage => _errorMessage;

  /// Returns recipes for the currently selected tab.
  List<ExploreRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  /// Filters and sorts recipes based on the selected tab.
  List<ExploreRecipe> visibleRecipesFor(ExploreCreatorRecipeTab tab) {
    final recipes = [...?_creator?.recipes];
    switch (tab) {
      case ExploreCreatorRecipeTab.all:
        return recipes;
      case ExploreCreatorRecipeTab.popular:
      // Sort by view count descending for popularity.
        recipes.sort(
              (first, second) => second.totalViews.compareTo(first.totalViews),
        );
        return recipes;
      case ExploreCreatorRecipeTab.recent:
      // Sort by publication date descending for recency.
        recipes.sort(
              (first, second) => second.publishedAt.compareTo(first.publishedAt),
        );
        return recipes;
    }
  }

  /// Loads the creator detail from the use case.
  /// Sets loading state and handles success or failure.
  Future<void> loadCreator() async {
    _isLoading = _creator == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getCreatorDetailUseCase.execute(creatorUid);
    if (_isDisposed) return;

    result.ifRight((creator) {
      _creator = creator;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  /// Selects a tab and updates the view.
  void selectTab(ExploreCreatorRecipeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  /// Toggles follow status for the creator with optimistic update.
  /// Reverts changes if the operation fails.
  Future<bool> toggleFollow() async {
    final creator = _creator;
    if (creator == null || _isUpdatingFollow) return false;

    final shouldFollow = !creator.isFollowing;
    // Optimistically update the follow state.
    _creator = _copyCreator(creator, isFollowing: shouldFollow);
    _isUpdatingFollow = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the actual follow operation.
    final result = await _toggleCreatorFollowUseCase.execute(
      creatorUid: creator.summary.uid,
      follow: shouldFollow,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    // Refresh on success or revert on failure.
    if (success) {
      await loadCreator();
    } else {
      _creator = creator;
    }

    _isUpdatingFollow = false;
    _notifyIfActive();
    return success;
  }

  /// Toggles favourite status for a recipe with optimistic update.
  /// Reverts changes if the operation fails.
  Future<bool> toggleFavourite(String recipeId) async {
    final creator = _creator;
    if (creator == null) return false;

    final recipeIndex = creator.recipes.indexWhere(
          (recipe) => recipe.id == recipeId,
    );
    if (recipeIndex == -1) return false;

    final recipe = creator.recipes[recipeIndex];
    final nextFavourite = !recipe.isFavourite;
    // Optimistically update the favourite state.
    _creator = _copyCreator(
      creator,
      recipes: creator.recipes.map((item) {
        if (item.id != recipeId) return item;
        return _copyRecipe(item, isFavourite: nextFavourite);
      }).toList(),
    );
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
      _creator = creator;
      _notifyIfActive();
    }
    return success;
  }

  /// Creates a copy of the creator detail with optional updated fields.
  ExploreCreatorDetail _copyCreator(
      ExploreCreatorDetail creator, {
        bool? isFollowing,
        List<ExploreRecipe>? recipes,
      }) {
    return ExploreCreatorDetail(
      summary: creator.summary,
      bio: creator.bio,
      postCount: creator.postCount,
      followingCount: creator.followingCount,
      isFollowing: isFollowing ?? creator.isFollowing,
      recipes: recipes ?? creator.recipes,
    );
  }

  /// Creates a copy of a recipe with optional updated fields.
  ExploreRecipe _copyRecipe(ExploreRecipe recipe, {bool? isFavourite}) {
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
      isFollowingAuthor: recipe.isFollowingAuthor,
      isFavourite: isFavourite ?? recipe.isFavourite,
      isCreatedByCurrentUser: recipe.isCreatedByCurrentUser,
      ingredients: recipe.ingredients,
      instructionSections: recipe.instructionSections,
      nutrition: recipe.nutrition,
      community: recipe.community,
      relatedRecipes: recipe.relatedRecipes,
    );
  }

  /// Notifies listeners only if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}