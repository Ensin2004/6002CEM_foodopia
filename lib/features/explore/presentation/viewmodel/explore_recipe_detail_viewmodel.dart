import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_recipe_detail_usecase.dart';

enum ExploreRecipeDetailTab { recipe, nutrition, community }

enum ExploreRecipeMethodTab { ingredients, instructions }

enum ExploreCommunityTab { ratings, comments }

class ExploreRecipeDetailViewModel extends ChangeNotifier {
  final GetExploreRecipeDetailUseCase _getRecipeDetailUseCase;
  final String recipeId;

  ExploreRecipe? _recipe;
  ExploreRecipeDetailTab _selectedTab = ExploreRecipeDetailTab.recipe;
  ExploreRecipeMethodTab _selectedMethodTab =
      ExploreRecipeMethodTab.ingredients;
  ExploreCommunityTab _selectedCommunityTab = ExploreCommunityTab.ratings;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  ExploreRecipeDetailViewModel({
    required this.recipeId,
    required GetExploreRecipeDetailUseCase getRecipeDetailUseCase,
  }) : _getRecipeDetailUseCase = getRecipeDetailUseCase {
    Future.microtask(loadRecipe);
  }

  ExploreRecipe? get recipe => _recipe;
  ExploreRecipeDetailTab get selectedTab => _selectedTab;
  ExploreRecipeMethodTab get selectedMethodTab => _selectedMethodTab;
  ExploreCommunityTab get selectedCommunityTab => _selectedCommunityTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecipe() async {
    _isLoading = _recipe == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getRecipeDetailUseCase.execute(recipeId);
    if (_isDisposed) return;

    result.ifRight((recipe) {
      _recipe = recipe;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectTab(ExploreRecipeDetailTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  void selectMethodTab(ExploreRecipeMethodTab tab) {
    if (_selectedMethodTab == tab) return;
    _selectedMethodTab = tab;
    _notifyIfActive();
  }

  void selectCommunityTab(ExploreCommunityTab tab) {
    if (_selectedCommunityTab == tab) return;
    _selectedCommunityTab = tab;
    _notifyIfActive();
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
