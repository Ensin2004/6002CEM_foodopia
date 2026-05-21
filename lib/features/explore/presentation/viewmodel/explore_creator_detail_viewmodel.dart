import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/get_explore_creator_detail_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';

enum ExploreCreatorRecipeTab { all, popular, recent }

class ExploreCreatorDetailViewModel extends ChangeNotifier {
  final GetExploreCreatorDetailUseCase _getCreatorDetailUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
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
  }) : _getCreatorDetailUseCase = getCreatorDetailUseCase,
       _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase {
    Future.microtask(loadCreator);
  }

  ExploreCreatorDetail? get creator => _creator;
  ExploreCreatorRecipeTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  bool get isUpdatingFollow => _isUpdatingFollow;
  String? get errorMessage => _errorMessage;

  List<ExploreRecipe> get visibleRecipes {
    final recipes = [...?_creator?.recipes];
    switch (_selectedTab) {
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

  ExploreCreatorDetail _copyCreator(
    ExploreCreatorDetail creator, {
    bool? isFollowing,
  }) {
    return ExploreCreatorDetail(
      summary: creator.summary,
      bio: creator.bio,
      postCount: creator.postCount,
      followingCount: creator.followingCount,
      isFollowing: isFollowing ?? creator.isFollowing,
      recipes: creator.recipes,
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
