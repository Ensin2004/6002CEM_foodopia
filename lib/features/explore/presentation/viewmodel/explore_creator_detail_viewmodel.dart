import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../library/domain/usecases/toggle_library_recipe_favourite_usecase.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_creator_detail_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';

enum ExploreCreatorRecipeTab { all, popular, recent }

class ExploreCreatorDetailViewModel extends ChangeNotifier {
  final GetExploreCreatorDetailUseCase _getCreatorDetailUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;
  final String creatorUid;

  ExploreCreatorDetail? _creator;
  ExploreCreatorRecipeTab _selectedTab = ExploreCreatorRecipeTab.all;
  bool _isLoading = true;
  bool _isUpdatingFollow = false;
  bool _isDisposed = false;
  String? _errorMessage;

  ExploreCreatorDetailViewModel({
    required this.creatorUid,
    required GetExploreCreatorDetailUseCase getCreatorDetailUseCase,
    required ToggleCreatorFollowUseCase toggleCreatorFollowUseCase,
    required ToggleLibraryRecipeFavouriteUseCase toggleFavouriteUseCase,
  }) : _getCreatorDetailUseCase = getCreatorDetailUseCase,
       _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase,
       _toggleFavouriteUseCase = toggleFavouriteUseCase {
    Future.microtask(loadCreator);
  }

  ExploreCreatorDetail? get creator => _creator;
  ExploreCreatorRecipeTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  bool get isUpdatingFollow => _isUpdatingFollow;
  String? get errorMessage => _errorMessage;

  List<ExploreRecipe> get visibleRecipes => visibleRecipesFor(_selectedTab);

  List<ExploreRecipe> visibleRecipesFor(ExploreCreatorRecipeTab tab) {
    final recipes = [...?_creator?.recipes];
    switch (tab) {
      case ExploreCreatorRecipeTab.all:
        return recipes;
      case ExploreCreatorRecipeTab.popular:
        recipes.sort(
          (first, second) => second.totalViews.compareTo(first.totalViews),
        );
        return recipes;
      case ExploreCreatorRecipeTab.recent:
        recipes.sort(
          (first, second) => second.publishedAt.compareTo(first.publishedAt),
        );
        return recipes;
    }
  }

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

  void selectTab(ExploreCreatorRecipeTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  Future<bool> toggleFollow() async {
    final creator = _creator;
    if (creator == null || _isUpdatingFollow) return false;

    final shouldFollow = !creator.isFollowing;
    _creator = _copyCreator(creator, isFollowing: shouldFollow);
    _isUpdatingFollow = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _toggleCreatorFollowUseCase.execute(
      creatorUid: creator.summary.uid,
      follow: shouldFollow,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });
    if (success) {
      await loadCreator();
    } else {
      _creator = creator;
    }

    _isUpdatingFollow = false;
    _notifyIfActive();
    return success;
  }

  Future<bool> toggleFavourite(String recipeId) async {
    final creator = _creator;
    if (creator == null) return false;

    final recipeIndex = creator.recipes.indexWhere(
      (recipe) => recipe.id == recipeId,
    );
    if (recipeIndex == -1) return false;

    final recipe = creator.recipes[recipeIndex];
    final nextFavourite = !recipe.isFavourite;
    _creator = _copyCreator(
      creator,
      recipes: creator.recipes.map((item) {
        if (item.id != recipeId) return item;
        return _copyRecipe(item, isFavourite: nextFavourite);
      }).toList(),
    );
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
      _creator = creator;
      _notifyIfActive();
    }
    return success;
  }

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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
