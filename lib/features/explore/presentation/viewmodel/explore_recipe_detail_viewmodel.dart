import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../admin_moderation/domain/usecases/update_admin_recipe_visibility_usecase.dart';
import '../../../admin_moderation/domain/usecases/mark_admin_recipe_reviewed_usecase.dart';
import '../../../library/domain/usecases/toggle_library_recipe_favourite_usecase.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../../meal_plan/domain/entities/meal_serving_amount.dart';
import '../../../meal_plan/domain/usecases/get_meal_categories_usecase.dart';
import '../../../meal_plan/domain/usecases/save_recipe_meal_plan_usecase.dart';
import '../../domain/entities/explore_recipe.dart';
import '../../domain/usecases/add_recipe_comment_usecase.dart';
import '../../domain/usecases/add_recipe_comment_reply_usecase.dart';
import '../../domain/usecases/add_recipe_reply_to_reply_usecase.dart';
import '../../domain/usecases/get_explore_recipe_detail_usecase.dart';
import '../../domain/usecases/increment_recipe_view_count_usecase.dart';
import '../../domain/usecases/submit_recipe_rating_usecase.dart';
import '../../domain/usecases/toggle_recipe_comment_like_usecase.dart';
import '../../domain/usecases/toggle_recipe_reply_like_usecase.dart';
import '../../domain/usecases/toggle_creator_follow_usecase.dart';
import '../../domain/usecases/update_recipe_visibility_usecase.dart';
import '../../domain/usecases/watch_explore_recipe_detail_usecase.dart';

/// Tabs available in the recipe detail view: recipe, nutrition, community.
enum ExploreRecipeDetailTab { recipe, nutrition, community }

/// Tabs for switching between ingredients and instructions view.
enum ExploreRecipeMethodTab { ingredients, instructions }

/// Unit system options for displaying recipe measurements.
enum ExploreRecipeUnitSystem { original, metric, imperial }

/// Tabs for switching between ratings and comments in the community section.
enum ExploreCommunityTab { ratings, comments }

/// Star rating filters for filtering reviews.
enum ExploreRatingStarFilter { all, one, two, three, four, five }

/// Date filter options for ordering community content.
enum ExploreCommunityDateFilter { all, latest, oldest }

/// ViewModel that manages the state and business logic for the recipe detail screen.
/// Handles recipe fetching, community interactions, ratings, comments, and meal planning.
class ExploreRecipeDetailViewModel extends ChangeNotifier {
  // Use cases for data operations.
  final GetExploreRecipeDetailUseCase _getRecipeDetailUseCase;
  final SubmitRecipeRatingUseCase _submitRecipeRatingUseCase;
  final AddRecipeCommentUseCase _addRecipeCommentUseCase;
  final IncrementRecipeViewCountUseCase _incrementRecipeViewCountUseCase;
  final ToggleRecipeCommentLikeUseCase _toggleRecipeCommentLikeUseCase;
  final AddRecipeCommentReplyUseCase _addRecipeCommentReplyUseCase;
  final ToggleRecipeReplyLikeUseCase _toggleRecipeReplyLikeUseCase;
  final AddRecipeReplyToReplyUseCase _addRecipeReplyToReplyUseCase;
  final WatchExploreRecipeDetailUseCase _watchRecipeDetailUseCase;
  final ToggleCreatorFollowUseCase _toggleCreatorFollowUseCase;
  final UpdateRecipeVisibilityUseCase _updateRecipeVisibilityUseCase;
  final UpdateAdminRecipeVisibilityUseCase? _updateAdminRecipeVisibilityUseCase;
  final MarkAdminRecipeReviewedUseCase? _markAdminRecipeReviewedUseCase;
  final ToggleLibraryRecipeFavouriteUseCase _toggleFavouriteUseCase;
  final SaveRecipeMealPlanUseCase? _saveRecipeMealPlanUseCase;
  final GetMealCategoriesUseCase? _getMealCategoriesUseCase;
  final String recipeId;
  final bool isAdminModeration;

  // Core state.
  ExploreRecipe? _recipe;
  List<AddMealCategoryOption> _mealCategories = const [];
  StreamSubscription<ExploreRecipe>? _recipeSubscription;

  // Tab and filter state.
  ExploreRecipeDetailTab _selectedTab = ExploreRecipeDetailTab.recipe;
  ExploreRecipeMethodTab _selectedMethodTab =
      ExploreRecipeMethodTab.ingredients;
  ExploreRecipeUnitSystem _selectedUnitSystem =
      ExploreRecipeUnitSystem.original;
  ExploreCommunityTab _selectedCommunityTab = ExploreCommunityTab.ratings;
  ExploreRatingStarFilter _ratingStarFilter = ExploreRatingStarFilter.all;
  ExploreCommunityDateFilter _ratingDateFilter = ExploreCommunityDateFilter.all;
  ExploreCommunityDateFilter _commentDateFilter =
      ExploreCommunityDateFilter.all;

  // Loading and operation states.
  bool _isLoading = true;
  bool _isSubmittingCommunityAction = false;
  bool _isUpdatingVisibility = false;
  bool _isSavingMealPlan = false;
  bool _isLoadingMealCategories = false;
  bool _isDisposed = false;

  // Like tracking for optimistic updates.
  final Map<String, bool> _pendingCommentLikeStates = {};
  final Map<String, bool> _pendingReplyLikeStates = {};
  final Set<String> _syncingCommentLikes = {};
  final Set<String> _syncingReplyLikes = {};

  // Error states.
  String? _errorMessage;
  String? _communityActionErrorMessage;
  String? _mealCategoryErrorMessage;

  /// Constructor initializes the ViewModel with required use cases.
  /// Starts watching the recipe detail stream and increments view count.
  ExploreRecipeDetailViewModel({
    required this.recipeId,
    required GetExploreRecipeDetailUseCase getRecipeDetailUseCase,
    required SubmitRecipeRatingUseCase submitRecipeRatingUseCase,
    required AddRecipeCommentUseCase addRecipeCommentUseCase,
    required IncrementRecipeViewCountUseCase incrementRecipeViewCountUseCase,
    required ToggleRecipeCommentLikeUseCase toggleRecipeCommentLikeUseCase,
    required AddRecipeCommentReplyUseCase addRecipeCommentReplyUseCase,
    required ToggleRecipeReplyLikeUseCase toggleRecipeReplyLikeUseCase,
    required AddRecipeReplyToReplyUseCase addRecipeReplyToReplyUseCase,
    required WatchExploreRecipeDetailUseCase watchRecipeDetailUseCase,
    required ToggleCreatorFollowUseCase toggleCreatorFollowUseCase,
    required UpdateRecipeVisibilityUseCase updateRecipeVisibilityUseCase,
    required ToggleLibraryRecipeFavouriteUseCase toggleFavouriteUseCase,
    UpdateAdminRecipeVisibilityUseCase? updateAdminRecipeVisibilityUseCase,
    MarkAdminRecipeReviewedUseCase? markAdminRecipeReviewedUseCase,
    SaveRecipeMealPlanUseCase? saveRecipeMealPlanUseCase,
    GetMealCategoriesUseCase? getMealCategoriesUseCase,
    this.isAdminModeration = false,
  }) : _getRecipeDetailUseCase = getRecipeDetailUseCase,
       _submitRecipeRatingUseCase = submitRecipeRatingUseCase,
       _addRecipeCommentUseCase = addRecipeCommentUseCase,
       _incrementRecipeViewCountUseCase = incrementRecipeViewCountUseCase,
       _toggleRecipeCommentLikeUseCase = toggleRecipeCommentLikeUseCase,
       _addRecipeCommentReplyUseCase = addRecipeCommentReplyUseCase,
       _toggleRecipeReplyLikeUseCase = toggleRecipeReplyLikeUseCase,
       _addRecipeReplyToReplyUseCase = addRecipeReplyToReplyUseCase,
       _watchRecipeDetailUseCase = watchRecipeDetailUseCase,
       _toggleCreatorFollowUseCase = toggleCreatorFollowUseCase,
       _updateRecipeVisibilityUseCase = updateRecipeVisibilityUseCase,
       _updateAdminRecipeVisibilityUseCase = updateAdminRecipeVisibilityUseCase,
       _markAdminRecipeReviewedUseCase = markAdminRecipeReviewedUseCase,
       _toggleFavouriteUseCase = toggleFavouriteUseCase,
       _saveRecipeMealPlanUseCase = saveRecipeMealPlanUseCase,
       _getMealCategoriesUseCase = getMealCategoriesUseCase {
    // Defer opening the recipe to avoid blocking the UI.
    Future.microtask(_openRecipe);
    _watchRecipeDetail();
  }

  // Getters for all state properties.
  ExploreRecipe? get recipe => _recipe;
  ExploreRecipeDetailTab get selectedTab => _selectedTab;
  ExploreRecipeMethodTab get selectedMethodTab => _selectedMethodTab;
  ExploreRecipeUnitSystem get selectedUnitSystem => _selectedUnitSystem;
  ExploreCommunityTab get selectedCommunityTab => _selectedCommunityTab;
  ExploreRatingStarFilter get ratingStarFilter => _ratingStarFilter;
  ExploreCommunityDateFilter get ratingDateFilter => _ratingDateFilter;
  ExploreCommunityDateFilter get commentDateFilter => _commentDateFilter;
  bool get isLoading => _isLoading;
  bool get isSubmittingCommunityAction => _isSubmittingCommunityAction;
  bool get isUpdatingVisibility => _isUpdatingVisibility;
  bool get isSavingMealPlan => _isSavingMealPlan;
  bool get isLoadingMealCategories => _isLoadingMealCategories;
  List<AddMealCategoryOption> get mealCategories => _mealCategories;
  String? get errorMessage => _errorMessage;
  String? get communityActionErrorMessage => _communityActionErrorMessage;
  String? get mealCategoryErrorMessage => _mealCategoryErrorMessage;

  /// Returns reviews filtered by star rating and sorted by date.
  List<ExploreReview> get visibleReviews {
    final source = _recipe?.community.reviews ?? const <ExploreReview>[];
    Iterable<ExploreReview> reviews = source;
    // Apply star rating filter.
    reviews = reviews.where((review) {
      final roundedRating = review.rating.round();
      return switch (_ratingStarFilter) {
        ExploreRatingStarFilter.all => true,
        ExploreRatingStarFilter.one => roundedRating == 1,
        ExploreRatingStarFilter.two => roundedRating == 2,
        ExploreRatingStarFilter.three => roundedRating == 3,
        ExploreRatingStarFilter.four => roundedRating == 4,
        ExploreRatingStarFilter.five => roundedRating == 5,
      };
    });
    // Apply date ordering.
    final sorted = reviews.toList();
    if (_ratingDateFilter == ExploreCommunityDateFilter.latest) {
      sorted.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
    } else if (_ratingDateFilter == ExploreCommunityDateFilter.oldest) {
      sorted.sort(
        (first, second) => first.createdAt.compareTo(second.createdAt),
      );
    }
    return sorted;
  }

  /// Returns comments filtered and sorted by date.
  List<ExploreComment> get visibleComments {
    final comments = [...?_recipe?.community.comments];
    if (_commentDateFilter == ExploreCommunityDateFilter.latest) {
      comments.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
    } else if (_commentDateFilter == ExploreCommunityDateFilter.oldest) {
      comments.sort(
        (first, second) => first.createdAt.compareTo(second.createdAt),
      );
    }
    return comments;
  }

  /// Opens the recipe by incrementing view count and loading detail data.
  Future<void> _openRecipe() async {
    await _incrementRecipeViewCountUseCase.execute(recipeId);
    await loadRecipe();
  }

  /// Starts listening to the real-time recipe detail stream.
  void _watchRecipeDetail() {
    _recipeSubscription = _watchRecipeDetailUseCase
        .execute(recipeId)
        .listen(
          (recipe) {
            // Resolve any pending like operations against the fresh data.
            _resolvePendingLikeStates(recipe);
            _recipe = _applyPendingLikeStates(recipe);
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

  /// Loads the recipe detail from the use case.
  Future<void> loadRecipe() async {
    _isLoading = _recipe == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getRecipeDetailUseCase.execute(recipeId);
    if (_isDisposed) return;

    result.ifRight((recipe) {
      _resolvePendingLikeStates(recipe);
      _recipe = _applyPendingLikeStates(recipe);
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  /// Selects a tab and updates the view.
  void selectTab(ExploreRecipeDetailTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _notifyIfActive();
  }

  /// Selects the method tab (ingredients or instructions).
  void selectMethodTab(ExploreRecipeMethodTab tab) {
    if (_selectedMethodTab == tab) return;
    _selectedMethodTab = tab;
    _notifyIfActive();
  }

  /// Selects the unit system for measurements.
  void selectUnitSystem(ExploreRecipeUnitSystem system) {
    if (_selectedUnitSystem == system) return;
    _selectedUnitSystem = system;
    _notifyIfActive();
  }

  /// Selects the community tab (ratings or comments).
  void selectCommunityTab(ExploreCommunityTab tab) {
    if (_selectedCommunityTab == tab) return;
    _selectedCommunityTab = tab;
    _notifyIfActive();
  }

  /// Updates rating filters for star rating and date ordering.
  void updateRatingFilters({
    required ExploreRatingStarFilter star,
    required ExploreCommunityDateFilter date,
  }) {
    if (_ratingStarFilter == star && _ratingDateFilter == date) return;
    _ratingStarFilter = star;
    _ratingDateFilter = date;
    _notifyIfActive();
  }

  /// Updates the comment date filter.
  void updateCommentDateFilter(ExploreCommunityDateFilter filter) {
    if (_commentDateFilter == filter) return;
    _commentDateFilter = filter;
    _notifyIfActive();
  }

  /// Submits a rating for the recipe with optimistic update.
  Future<bool> submitRating(double rating) async {
    if (isAdminModeration) {
      _communityActionErrorMessage = 'Admins cannot rate recipes.';
      _notifyIfActive();
      return false;
    }

    // Prevent rating own recipe.
    if (_recipe?.isCreatedByCurrentUser == true) {
      _communityActionErrorMessage = 'You cannot rate your own recipe.';
      _notifyIfActive();
      return false;
    }

    final previousRecipe = _recipe;
    _applyOptimisticRating(rating);
    _isSubmittingCommunityAction = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _submitRecipeRatingUseCase.execute(
      recipeId: recipeId,
      rating: rating,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });

    // Refresh on success or revert on failure.
    if (success) {
      await loadRecipe();
    } else {
      _recipe = previousRecipe;
    }

    _isSubmittingCommunityAction = false;
    _notifyIfActive();
    return success;
  }

  /// Adds a comment to the recipe with optimistic update.
  Future<bool> addComment(String content) async {
    if (isAdminModeration) {
      _communityActionErrorMessage = 'Admins cannot add comments.';
      _notifyIfActive();
      return false;
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return false;

    final previousRecipe = _recipe;
    _applyOptimisticComment(trimmedContent);
    _isSubmittingCommunityAction = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _addRecipeCommentUseCase.execute(
      recipeId: recipeId,
      content: trimmedContent,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });

    if (success) {
      await loadRecipe();
    } else {
      _recipe = previousRecipe;
    }

    _isSubmittingCommunityAction = false;
    _notifyIfActive();
    return success;
  }

  /// Toggles like on a comment with optimistic update.
  Future<bool> toggleCommentLike(String commentId) async {
    final recipe = _recipe;
    if (recipe == null) return false;

    final comment = _findComment(recipe.community.comments, commentId);
    if (comment == null) return false;

    final nextLiked = !comment.isLiked;
    // Store pending state and apply optimistically.
    _pendingCommentLikeStates[commentId] = nextLiked;
    _applyOptimisticCommentLike(commentId, isLiked: nextLiked);
    _communityActionErrorMessage = null;
    _notifyIfActive();

    // Sync with server in the background.
    if (!_syncingCommentLikes.contains(commentId)) {
      unawaited(_syncCommentLike(commentId));
    }

    return true;
  }

  /// Toggles like on a reply with optimistic update.
  Future<bool> toggleReplyLike(String replyPath) async {
    final recipe = _recipe;
    if (recipe == null) return false;

    final reply = _findReply(recipe.community.comments, replyPath);
    if (reply == null) return false;

    final nextLiked = !reply.isLiked;
    // Store pending state and apply optimistically.
    _pendingReplyLikeStates[replyPath] = nextLiked;
    _applyOptimisticReplyLike(replyPath, isLiked: nextLiked);
    _communityActionErrorMessage = null;
    _notifyIfActive();

    if (!_syncingReplyLikes.contains(replyPath)) {
      unawaited(_syncReplyLike(replyPath));
    }

    return true;
  }

  /// Synchronizes comment like state with the server.
  Future<void> _syncCommentLike(String commentId) async {
    _syncingCommentLikes.add(commentId);

    while (!_isDisposed && _pendingCommentLikeStates.containsKey(commentId)) {
      final requestedState = _pendingCommentLikeStates[commentId];
      final result = await _toggleRecipeCommentLikeUseCase.execute(
        recipeId: recipeId,
        commentId: commentId,
      );
      if (_isDisposed) break;

      final success = result.isRight();
      result.ifLeft((failure) {
        _communityActionErrorMessage = failure.message;
      });

      // On failure, remove pending state and refresh.
      if (!success) {
        _pendingCommentLikeStates.remove(commentId);
        await loadRecipe();
        break;
      }

      // Remove pending state if the server state matches the request.
      if (_pendingCommentLikeStates[commentId] == requestedState) {
        _pendingCommentLikeStates.remove(commentId);
      }
    }

    _syncingCommentLikes.remove(commentId);
    _notifyIfActive();
  }

  /// Synchronizes reply like state with the server.
  Future<void> _syncReplyLike(String replyPath) async {
    _syncingReplyLikes.add(replyPath);

    while (!_isDisposed && _pendingReplyLikeStates.containsKey(replyPath)) {
      final requestedState = _pendingReplyLikeStates[replyPath];
      final result = await _toggleRecipeReplyLikeUseCase.execute(
        replyPath: replyPath,
      );
      if (_isDisposed) break;

      final success = result.isRight();
      result.ifLeft((failure) {
        _communityActionErrorMessage = failure.message;
      });

      if (!success) {
        _pendingReplyLikeStates.remove(replyPath);
        await loadRecipe();
        break;
      }

      if (_pendingReplyLikeStates[replyPath] == requestedState) {
        _pendingReplyLikeStates.remove(replyPath);
      }
    }

    _syncingReplyLikes.remove(replyPath);
    _notifyIfActive();
  }

  /// Adds a reply to a comment with optimistic update.
  Future<bool> addCommentReply({
    required String commentId,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return false;

    final previousRecipe = _recipe;
    _applyOptimisticCommentReply(commentId: commentId, content: trimmedContent);
    _isSubmittingCommunityAction = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _addRecipeCommentReplyUseCase.execute(
      recipeId: recipeId,
      commentId: commentId,
      content: trimmedContent,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });
    if (success) {
      await loadRecipe();
    } else {
      _recipe = previousRecipe;
    }

    _isSubmittingCommunityAction = false;
    _notifyIfActive();
    return success;
  }

  /// Adds a reply to a nested reply with optimistic update.
  Future<bool> addReplyToReply({
    required String replyPath,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return false;

    final previousRecipe = _recipe;
    _applyOptimisticNestedReply(replyPath: replyPath, content: trimmedContent);
    _isSubmittingCommunityAction = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _addRecipeReplyToReplyUseCase.execute(
      replyPath: replyPath,
      content: trimmedContent,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });
    if (success) {
      await loadRecipe();
    } else {
      _recipe = previousRecipe;
    }

    _isSubmittingCommunityAction = false;
    _notifyIfActive();
    return success;
  }

  /// Toggles follow status for the recipe creator.
  Future<bool> toggleCreatorFollow() async {
    final recipe = _recipe;
    if (recipe == null || recipe.isCreatedByCurrentUser) return false;

    final shouldFollow = !recipe.isFollowingAuthor;
    final previousRecipe = recipe;
    // Optimistically update the follow state.
    _recipe = _copyRecipe(recipe, isFollowingAuthor: shouldFollow);
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _toggleCreatorFollowUseCase.execute(
      creatorUid: recipe.creatorUid,
      follow: shouldFollow,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });
    if (!success) {
      _recipe = previousRecipe;
    } else {
      await loadRecipe();
    }
    _notifyIfActive();
    return success;
  }

  /// Toggles favourite status for the recipe.
  Future<bool> toggleFavourite() async {
    final recipe = _recipe;
    if (recipe == null) return false;

    final nextFavourite = !recipe.isFavourite;
    final previousRecipe = recipe;
    // Optimistically update the favourite state.
    _recipe = _copyRecipe(recipe, isFavourite: nextFavourite);
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await _toggleFavouriteUseCase.execute(
      recipeId: recipe.id,
      isFavourite: nextFavourite,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });
    if (!success) {
      _recipe = previousRecipe;
    }
    _notifyIfActive();
    return success;
  }

  /// Updates the visibility (published status) of the recipe.
  Future<bool> updateVisibility({
    required bool isPublished,
    String? hiddenReason,
  }) async {
    _isUpdatingVisibility = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final adminUseCase = _updateAdminRecipeVisibilityUseCase;
    final result = isAdminModeration && adminUseCase != null
        ? await adminUseCase.execute(
            recipeId: recipeId,
            isPublished: isPublished,
            hiddenReason: hiddenReason,
          )
        : await _updateRecipeVisibilityUseCase.execute(
            recipeId: recipeId,
            isPublished: isPublished,
          );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });

    _isUpdatingVisibility = false;
    _notifyIfActive();
    return success;
  }

  /// Marks the recipe as reviewed from admin moderation.
  Future<bool> markAsReviewed() async {
    final useCase = _markAdminRecipeReviewedUseCase;
    if (!isAdminModeration || useCase == null) return false;

    _isUpdatingVisibility = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await useCase.execute(recipeId);
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });

    if (success) {
      await loadRecipe();
    }

    _isUpdatingVisibility = false;
    _notifyIfActive();
    return success;
  }

  /// Saves a recipe to the meal plan for a single date and meal category.
  Future<bool> saveToMealPlan({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required String source,
    required double servingCount,
  }) async {
    final recipe = _recipe;
    final useCase = _saveRecipeMealPlanUseCase;
    if (recipe == null || useCase == null || _isSavingMealPlan) return false;

    _isSavingMealPlan = true;
    _communityActionErrorMessage = null;
    _notifyIfActive();

    final result = await useCase.execute(
      userId: userId,
      date: date,
      mealCategory: mealCategory,
      recipe: AddMealAiRecipe(
        id: recipe.id,
        title: recipe.title,
        durationLabel: recipe.totalTime,
        difficultyLabel: recipe.difficulty,
        servingLabel: MealServingAmount.format(servingCount),
        imagePath: recipe.imagePath,
        description: recipe.description,
        reasons: const [],
        calories: MealServingAmount.scaledCalories(
          recipeCalories: recipe.nutrition.calories,
          recipeServings: recipe.servings,
          plannedServings: servingCount,
        ),
        categoryName: recipe.category,
      ),
      source: source,
      servingCount: servingCount,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) {
      _communityActionErrorMessage = failure.message;
    });
    _isSavingMealPlan = false;
    _notifyIfActive();
    return success;
  }

  /// Loads meal categories for the meal plan dialog.
  Future<bool> loadMealCategories() async {
    if (_mealCategories.isNotEmpty) return true;
    final useCase = _getMealCategoriesUseCase;
    if (useCase == null || _isLoadingMealCategories) {
      return _mealCategories.isNotEmpty;
    }

    _isLoadingMealCategories = true;
    _mealCategoryErrorMessage = null;
    _notifyIfActive();

    final result = await useCase.execute();
    if (_isDisposed) return false;

    result.ifRight((categories) {
      _mealCategories = categories.isEmpty
          ? RecipeDetailMealPlanDefaults.categories
          : categories;
    });
    result.ifLeft((failure) {
      _mealCategoryErrorMessage = failure.message;
      _mealCategories = RecipeDetailMealPlanDefaults.categories;
    });

    _isLoadingMealCategories = false;
    _notifyIfActive();
    return _mealCategories.isNotEmpty;
  }

  /// Saves a recipe to the meal plan for multiple dates and meal categories.
  /// Returns a result object with the number of successful saves.
  Future<RecipeDetailMealPlanSaveResult> saveToMealPlanDates({
    required String userId,
    required List<DateTime> dates,
    required List<AddMealCategoryOption> mealCategories,
    required String source,
    required double servingCount,
  }) async {
    var savedCount = 0;
    // Validate inputs.
    if (dates.isEmpty) {
      return const RecipeDetailMealPlanSaveResult(
        savedCount: 0,
        errorMessage: 'Select at least one date.',
      );
    }
    if (mealCategories.isEmpty) {
      return const RecipeDetailMealPlanSaveResult(
        savedCount: 0,
        errorMessage: 'Select at least one meal type.',
      );
    }

    // Save for each combination of date and meal category.
    for (final mealCategory in mealCategories) {
      for (final date in dates) {
        final success = await saveToMealPlan(
          userId: userId,
          date: date,
          mealCategory: mealCategory,
          source: source,
          servingCount: servingCount,
        );
        if (!success) {
          return RecipeDetailMealPlanSaveResult(
            savedCount: savedCount,
            errorMessage:
                _communityActionErrorMessage ?? 'Unable to add meal plan.',
          );
        }
        savedCount++;
      }
    }

    return RecipeDetailMealPlanSaveResult(savedCount: savedCount);
  }

  /// Optimistically applies a rating to the local recipe state.
  void _applyOptimisticRating(double rating) {
    final recipe = _recipe;
    if (recipe == null) return;

    final nextCount = recipe.hasRatedByCurrentUser
        ? recipe.ratingCount
        : recipe.ratingCount + 1;
    final nextAverage =
        ((recipe.rating * recipe.ratingCount) + rating) / nextCount;
    final review = ExploreReview(
      author: 'You',
      avatarPath: '',
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
      rating: rating,
    );
    final reviews = [review, ...recipe.community.reviews];

    _recipe = _copyRecipe(
      recipe,
      rating: nextAverage,
      ratingCount: nextCount,
      hasRatedByCurrentUser: true,
      community: _copyCommunity(
        recipe.community,
        ratingBreakdown: _ratingBreakdown(reviews),
        reviews: reviews,
      ),
    );
  }

  /// Optimistically applies a comment to the local recipe state.
  void _applyOptimisticComment(String content) {
    final recipe = _recipe;
    if (recipe == null) return;

    final comment = ExploreComment(
      id: 'local-comment-${DateTime.now().microsecondsSinceEpoch}',
      author: 'You',
      avatarPath: '',
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
      content: content,
      likes: 0,
      replies: const [],
    );

    _recipe = _copyRecipe(
      recipe,
      commentCount: recipe.commentCount + 1,
      community: _copyCommunity(
        recipe.community,
        comments: [comment, ...recipe.community.comments],
      ),
    );
  }

  /// Optimistically applies a comment like to the local recipe state.
  void _applyOptimisticCommentLike(String commentId, {required bool isLiked}) {
    final recipe = _recipe;
    if (recipe == null) return;

    final comments = recipe.community.comments.map((comment) {
      if (comment.id != commentId) return comment;
      return _copyComment(
        comment,
        isLiked: isLiked,
        likes: _adjustLikeCount(
          likes: comment.likes,
          wasLiked: comment.isLiked,
          isLiked: isLiked,
        ),
      );
    }).toList();

    _recipe = _copyRecipe(
      recipe,
      community: _copyCommunity(recipe.community, comments: comments),
    );
  }

  /// Optimistically applies a reply like to the local recipe state.
  void _applyOptimisticReplyLike(String replyPath, {required bool isLiked}) {
    final recipe = _recipe;
    if (recipe == null) return;

    final comments = recipe.community.comments.map((comment) {
      return _copyComment(
        comment,
        replies: _updateReplyLikes(comment.replies, replyPath, isLiked),
      );
    }).toList();

    _recipe = _copyRecipe(
      recipe,
      community: _copyCommunity(recipe.community, comments: comments),
    );
  }

  /// Optimistically applies a comment reply to the local recipe state.
  void _applyOptimisticCommentReply({
    required String commentId,
    required String content,
  }) {
    final recipe = _recipe;
    if (recipe == null) return;

    final reply = _localReply(content);
    final comments = recipe.community.comments.map((comment) {
      if (comment.id != commentId) return comment;
      return _copyComment(comment, replies: [...comment.replies, reply]);
    }).toList();

    _recipe = _copyRecipe(
      recipe,
      community: _copyCommunity(recipe.community, comments: comments),
    );
  }

  /// Optimistically applies a nested reply to the local recipe state.
  void _applyOptimisticNestedReply({
    required String replyPath,
    required String content,
  }) {
    final recipe = _recipe;
    if (recipe == null) return;

    final comments = recipe.community.comments.map((comment) {
      return _copyComment(
        comment,
        replies: _addNestedReply(
          comment.replies,
          replyPath,
          _localReply(content),
        ),
      );
    }).toList();

    _recipe = _copyRecipe(
      recipe,
      community: _copyCommunity(recipe.community, comments: comments),
    );
  }

  /// Updates reply like states recursively in the reply tree.
  List<ExploreCommentReply> _updateReplyLikes(
    List<ExploreCommentReply> replies,
    String replyPath,
    bool isLiked,
  ) {
    return replies.map((reply) {
      final childReplies = _updateReplyLikes(reply.replies, replyPath, isLiked);
      if (reply.documentPath != replyPath) {
        return _copyReply(reply, replies: childReplies);
      }
      return _copyReply(
        reply,
        replies: childReplies,
        isLiked: isLiked,
        likes: _adjustLikeCount(
          likes: reply.likes,
          wasLiked: reply.isLiked,
          isLiked: isLiked,
        ),
      );
    }).toList();
  }

  /// Applies all pending like states to a recipe.
  ExploreRecipe _applyPendingLikeStates(ExploreRecipe recipe) {
    if (_pendingCommentLikeStates.isEmpty && _pendingReplyLikeStates.isEmpty) {
      return recipe;
    }

    final comments = recipe.community.comments.map((comment) {
      var nextComment = comment;
      final pendingCommentLike = _pendingCommentLikeStates[comment.id];
      if (pendingCommentLike != null) {
        nextComment = _copyComment(
          nextComment,
          isLiked: pendingCommentLike,
          likes: _adjustLikeCount(
            likes: nextComment.likes,
            wasLiked: nextComment.isLiked,
            isLiked: pendingCommentLike,
          ),
        );
      }

      return _copyComment(
        nextComment,
        replies: _applyPendingReplyLikeStates(nextComment.replies),
      );
    }).toList();

    return _copyRecipe(
      recipe,
      community: _copyCommunity(recipe.community, comments: comments),
    );
  }

  /// Recursively applies pending reply like states.
  List<ExploreCommentReply> _applyPendingReplyLikeStates(
    List<ExploreCommentReply> replies,
  ) {
    return replies.map((reply) {
      var nextReply = reply;
      final pendingReplyLike = _pendingReplyLikeStates[reply.documentPath];
      if (pendingReplyLike != null) {
        nextReply = _copyReply(
          nextReply,
          isLiked: pendingReplyLike,
          likes: _adjustLikeCount(
            likes: nextReply.likes,
            wasLiked: nextReply.isLiked,
            isLiked: pendingReplyLike,
          ),
        );
      }

      return _copyReply(
        nextReply,
        replies: _applyPendingReplyLikeStates(nextReply.replies),
      );
    }).toList();
  }

  /// Removes pending like states that have been resolved on the server.
  void _resolvePendingLikeStates(ExploreRecipe recipe) {
    _pendingCommentLikeStates.removeWhere((commentId, isLiked) {
      final comment = _findComment(recipe.community.comments, commentId);
      return comment == null || comment.isLiked == isLiked;
    });

    _pendingReplyLikeStates.removeWhere((replyPath, isLiked) {
      final reply = _findReply(recipe.community.comments, replyPath);
      return reply == null || reply.isLiked == isLiked;
    });
  }

  /// Finds a comment by ID in the comment list.
  ExploreComment? _findComment(
    List<ExploreComment> comments,
    String commentId,
  ) {
    for (final comment in comments) {
      if (comment.id == commentId) return comment;
    }
    return null;
  }

  /// Finds a reply by document path in the comment tree.
  ExploreCommentReply? _findReply(
    List<ExploreComment> comments,
    String replyPath,
  ) {
    for (final comment in comments) {
      final reply = _findReplyInReplies(comment.replies, replyPath);
      if (reply != null) return reply;
    }
    return null;
  }

  /// Recursively finds a reply in the reply tree.
  ExploreCommentReply? _findReplyInReplies(
    List<ExploreCommentReply> replies,
    String replyPath,
  ) {
    for (final reply in replies) {
      if (reply.documentPath == replyPath) return reply;
      final nestedReply = _findReplyInReplies(reply.replies, replyPath);
      if (nestedReply != null) return nestedReply;
    }
    return null;
  }

  /// Adjusts the like count based on the like state change.
  int _adjustLikeCount({
    required int likes,
    required bool wasLiked,
    required bool isLiked,
  }) {
    if (wasLiked == isLiked) return likes;
    return (likes + (isLiked ? 1 : -1)).clamp(0, 1 << 31).toInt();
  }

  /// Adds a nested reply to the reply tree at the specified path.
  List<ExploreCommentReply> _addNestedReply(
    List<ExploreCommentReply> replies,
    String replyPath,
    ExploreCommentReply newReply,
  ) {
    return replies.map((reply) {
      if (reply.documentPath == replyPath) {
        return _copyReply(reply, replies: [...reply.replies, newReply]);
      }
      return _copyReply(
        reply,
        replies: _addNestedReply(reply.replies, replyPath, newReply),
      );
    }).toList();
  }

  /// Creates a local reply with a temporary ID.
  ExploreCommentReply _localReply(String content) {
    final id = 'local-reply-${DateTime.now().microsecondsSinceEpoch}';
    return ExploreCommentReply(
      id: id,
      documentPath: id,
      author: 'You',
      avatarPath: '',
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
      content: content,
      likes: 0,
      replies: const [],
    );
  }

  /// Calculates the rating breakdown from a list of reviews.
  List<ExploreRatingBreakdown> _ratingBreakdown(List<ExploreReview> reviews) {
    final counts = {for (var star = 1; star <= 5; star++) star: 0};
    for (final review in reviews) {
      final star = review.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return List.generate(5, (index) {
      final stars = 5 - index;
      return ExploreRatingBreakdown(stars: stars, count: counts[stars] ?? 0);
    });
  }

  /// Creates a copy of a recipe with optional updated fields.
  ExploreRecipe _copyRecipe(
    ExploreRecipe recipe, {
    double? rating,
    int? ratingCount,
    int? commentCount,
    bool? isFollowingAuthor,
    bool? isFavourite,
    bool? hasRatedByCurrentUser,
    ExploreCommunity? community,
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
      tags: recipe.tags,
      ingredientNames: recipe.ingredientNames,
      allergenInfo: recipe.allergenInfo,
      totalTime: recipe.totalTime,
      difficulty: recipe.difficulty,
      servings: recipe.servings,
      rating: rating ?? recipe.rating,
      ratingCount: ratingCount ?? recipe.ratingCount,
      commentCount: commentCount ?? recipe.commentCount,
      totalViews: recipe.totalViews,
      publishedAt: recipe.publishedAt,
      isFollowingAuthor: isFollowingAuthor ?? recipe.isFollowingAuthor,
      isFavourite: isFavourite ?? recipe.isFavourite,
      isCreatedByCurrentUser: recipe.isCreatedByCurrentUser,
      hasRatedByCurrentUser:
          hasRatedByCurrentUser ?? recipe.hasRatedByCurrentUser,
      isModerationHidden: recipe.isModerationHidden,
      moderationHiddenReason: recipe.moderationHiddenReason,
      ingredients: recipe.ingredients,
      instructionSections: recipe.instructionSections,
      nutrition: recipe.nutrition,
      community: community ?? recipe.community,
      relatedRecipes: recipe.relatedRecipes,
    );
  }

  /// Creates a copy of a community object with optional updated fields.
  ExploreCommunity _copyCommunity(
    ExploreCommunity community, {
    List<ExploreRatingBreakdown>? ratingBreakdown,
    List<ExploreReview>? reviews,
    List<ExploreComment>? comments,
  }) {
    return ExploreCommunity(
      authorBio: community.authorBio,
      ratingBreakdown: ratingBreakdown ?? community.ratingBreakdown,
      reviews: reviews ?? community.reviews,
      comments: comments ?? community.comments,
    );
  }

  /// Creates a copy of a comment with optional updated fields.
  ExploreComment _copyComment(
    ExploreComment comment, {
    int? likes,
    bool? isLiked,
    List<ExploreCommentReply>? replies,
  }) {
    return ExploreComment(
      id: comment.id,
      author: comment.author,
      avatarPath: comment.avatarPath,
      timeAgo: comment.timeAgo,
      createdAt: comment.createdAt,
      content: comment.content,
      likes: likes ?? comment.likes,
      isLiked: isLiked ?? comment.isLiked,
      replies: replies ?? comment.replies,
    );
  }

  /// Creates a copy of a reply with optional updated fields.
  ExploreCommentReply _copyReply(
    ExploreCommentReply reply, {
    int? likes,
    bool? isLiked,
    List<ExploreCommentReply>? replies,
  }) {
    return ExploreCommentReply(
      id: reply.id,
      documentPath: reply.documentPath,
      author: reply.author,
      avatarPath: reply.avatarPath,
      timeAgo: reply.timeAgo,
      createdAt: reply.createdAt,
      content: reply.content,
      likes: likes ?? reply.likes,
      isLiked: isLiked ?? reply.isLiked,
      replies: replies ?? reply.replies,
    );
  }

  /// Notifies listeners only if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _recipeSubscription?.cancel();
    super.dispose();
  }
}

/// Result object for meal plan save operations.
/// Contains the number of successfully saved entries and any error message.
class RecipeDetailMealPlanSaveResult {
  final int savedCount;
  final String? errorMessage;

  const RecipeDetailMealPlanSaveResult({
    required this.savedCount,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Default meal categories used when the server does not provide any.
class RecipeDetailMealPlanDefaults {
  static const categories = [
    AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
    AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
    AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
    AddMealCategoryOption(id: 'snack', name: 'Snack'),
  ];

  const RecipeDetailMealPlanDefaults._();
}
