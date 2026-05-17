import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_recipes_usecase.dart';

class ExploreViewModel extends ChangeNotifier {
  final GetExploreRecipesUseCase _getRecipesUseCase;

  List<ExploreRecipe> _recipes = const [];
  ExploreRecipeTab _selectedTab = ExploreRecipeTab.all;
  String _query = '';
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  ExploreViewModel({required GetExploreRecipesUseCase getRecipesUseCase})
    : _getRecipesUseCase = getRecipesUseCase {
    Future.microtask(loadRecipes);
  }

  List<ExploreRecipe> get recipes => _recipes;
  ExploreRecipeTab get selectedTab => _selectedTab;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ExploreRecipe> get visibleRecipes {
    Iterable<ExploreRecipe> results = _recipes;

    if (_selectedTab == ExploreRecipeTab.following) {
      results = results.where((recipe) => recipe.isFollowingAuthor);
    } else if (_selectedTab == ExploreRecipeTab.popular) {
      results = results.where((recipe) => recipe.rating >= 4.5);
    } else if (_selectedTab == ExploreRecipeTab.recent) {
      results = results.toList().reversed;
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

  bool get shouldShowFollowingEmpty =>
      !_isLoading &&
      _errorMessage == null &&
      _selectedTab == ExploreRecipeTab.following &&
      _recipes.where((recipe) => recipe.isFollowingAuthor).isEmpty;

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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
