import 'dart:io';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../features/recipe/domain/entities/add_recipe_basic_info.dart';
import '../../features/recipe/domain/entities/add_recipe_ingredient.dart';
import '../../features/recipe/domain/entities/add_recipe_instruction.dart';
import '../../features/settings/domain/entities/faq_item.dart';
import '../../features/settings/domain/entities/help_center_issue.dart';

typedef FaqSaveCallback =
    Future<bool> Function({
      required String question,
      required String answer,
      File? questionImageFile,
      File? answerImageFile,
    });

/// Marker for routes that do not need payload but are reached after auth.
class AuthenticatedRouteArgs {
  /// Creates a authenticated route args instance.
  const AuthenticatedRouteArgs();
}

/// Typed arguments for explore recipe detail route.
class ExploreRecipeDetailArgs {
  final String recipeId;
  final MealPlanSelectionArgs? mealPlanSelection;

  const ExploreRecipeDetailArgs({
    required this.recipeId,
    this.mealPlanSelection,
  });
}

/// Typed arguments for library recipe detail route.
class LibraryRecipeDetailArgs {
  final String recipeId;
  final bool isSelfPublished;
  final bool isPublished;
  final MealPlanSelectionArgs? mealPlanSelection;

  const LibraryRecipeDetailArgs({
    required this.recipeId,
    required this.isSelfPublished,
    required this.isPublished,
    this.mealPlanSelection,
  });
}

/// Typed arguments for library route.
class LibraryArgs {
  final String? focusedRecipeId;
  final bool? focusedRecipeIsPublished;
  final MealPlanSelectionArgs? mealPlanSelection;

  const LibraryArgs({
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.mealPlanSelection,
  });
}

/// Typed arguments for explore creator detail route.
class ExploreCreatorDetailArgs {
  final String creatorUid;

  const ExploreCreatorDetailArgs({required this.creatorUid});
}

/// Typed arguments for the meal plan route.
class MealPlanArgs {
  final int initialTabIndex;
  final String? userId;

  const MealPlanArgs({this.initialTabIndex = 0, this.userId});
}

/// Typed arguments for add grocery list route.
class AddGroceryListArgs {
  final String? userId;

  const AddGroceryListArgs({this.userId});
}

/// Typed arguments for the add recipe basic info route.
class AddRecipeBasicInfoArgs {
  final String? recipeId;
  final String? draftId;
  final bool returnToReview;
  final AddMealAiRecipe? aiRecipe;
  final AddMealAiGenerationRequest? aiRequest;
  final String? userId;

  const AddRecipeBasicInfoArgs({
    this.recipeId,
    this.draftId,
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
  });
}

/// Typed arguments for the add recipe ingredients route.
class AddRecipeIngredientsArgs {
  final String recipeId;
  final String visibility;
  final bool returnToReview;
  final AddMealAiRecipe? aiRecipe;
  final AddMealAiGenerationRequest? aiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;

  const AddRecipeIngredientsArgs({
    required this.recipeId,
    this.visibility = 'private',
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.aiDraftBasicInfo,
  });
}

/// Typed arguments for the add recipe instructions route.
class AddRecipeInstructionsArgs {
  final String recipeId;
  final String visibility;
  final bool returnToReview;
  final AddMealAiRecipe? aiRecipe;
  final AddMealAiGenerationRequest? aiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;

  const AddRecipeInstructionsArgs({
    required this.recipeId,
    this.visibility = 'private',
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
  });
}

/// Typed arguments for the add recipe review route.
class AddRecipeReviewArgs {
  final String recipeId;
  final AddMealAiRecipe? aiRecipe;
  final AddMealAiGenerationRequest? aiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> aiDraftInstructions;
  final bool aiDraftUseSections;

  const AddRecipeReviewArgs({
    required this.recipeId,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.aiDraftInstructions = const [],
    this.aiDraftUseSections = false,
  });
}

/// Typed arguments for add meal planning route.
class AddMealPlanArgs {
  final String? userId;
  final String mealType;
  final String? mealCategoryId;
  final DateTime? selectedDate;
  final List<String> existingRecipeIds;

  const AddMealPlanArgs({
    this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.existingRecipeIds = const [],
  });
}

/// Typed arguments for selecting an existing recipe into a meal plan.
class MealPlanSelectionArgs {
  final String userId;
  final DateTime selectedDate;
  final String mealCategoryId;
  final String mealCategoryName;
  final String source;
  final List<String> existingRecipeIds;

  const MealPlanSelectionArgs({
    required this.userId,
    required this.selectedDate,
    required this.mealCategoryId,
    required this.mealCategoryName,
    required this.source,
    this.existingRecipeIds = const [],
  });
}

/// Typed arguments for generate AI meal route.
class GenerateAiMealArgs {
  final String? userId;
  final String mealType;
  final String? mealCategoryId;
  final DateTime? selectedDate;
  final AddMealAiGenerationRequest? initialRequest;
  final bool autoGenerate;

  const GenerateAiMealArgs({
    this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
  });
}

/// Typed arguments for manage grocery list route.
class ManageGroceryListArgs {
  final String listId;

  const ManageGroceryListArgs({required this.listId});
}

/// Typed arguments for statistics route.
class StatisticsArgs {
  final bool isAdmin;

  const StatisticsArgs({required this.isAdmin});
}

/// Typed arguments for statistics detail routes.
class StatisticsDetailArgs {
  final bool isAdmin;

  const StatisticsDetailArgs({this.isAdmin = false});
}

/// Typed arguments for user_home route
class HomeArgs {
  final UserEntity? user;
  final String? role;
  final int initialTabIndex;
  final String? focusedRecipeId;
  final bool? focusedRecipeIsPublished;
  final String? libraryRefreshToken;

  /// Creates a user_home args instance.
  const HomeArgs({
    this.user,
    this.role,
    this.initialTabIndex = 0,
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.libraryRefreshToken,
  });
}

/// Typed arguments for edit profile route
class EditProfileArgs {
  final String uid;

  /// Creates a edit profile args instance.
  const EditProfileArgs({required this.uid});
}

/// Typed arguments for about pages
class AboutArgs {
  final String documentId;
  final String title;
  final bool isAdmin;

  /// Creates a about args instance.
  const AboutArgs({
    required this.documentId,
    required this.title,
    required this.isAdmin,
  });
}

/// Typed arguments for settings route
class SettingsArgs {
  final UserEntity user;

  /// Creates a settings args instance.
  const SettingsArgs({required this.user});
}

/// Typed arguments for the user setup flow after signup.
class UserSetupArgs {
  final String uid;
  final UserEntity? user;
  final String? role;
  final bool isSettingsMode;

  const UserSetupArgs({
    required this.uid,
    this.user,
    this.role,
    this.isSettingsMode = false,
  });
}

/// Typed arguments for FAQ list route
class FaqArgs {
  final bool isAdmin;

  /// Creates a faq args instance.
  const FaqArgs({required this.isAdmin});
}

/// Typed arguments for help center route
class HelpCenterArgs {
  final bool isAdmin;

  /// Creates a help center args instance.
  const HelpCenterArgs({required this.isAdmin});
}

/// Typed arguments for issue detail route
class IssueDetailArgs {
  final HelpCenterIssue issue;
  final String? userEmail;
  final bool isAdmin;

  /// Handles the function operation.
  final void Function()? onStatusChanged;

  /// Creates a issue detail args instance.
  const IssueDetailArgs({
    required this.issue,
    this.userEmail,
    this.isAdmin = false,
    this.onStatusChanged,
  });
}

/// Typed arguments for FAQ form route
class FaqFormArgs {
  final FaqItem? item;
  final FaqSaveCallback onSave;

  /// Creates a faq form args instance.
  const FaqFormArgs({this.item, required this.onSave});
}

/// Typed arguments for image preview route
class ImagePreviewArgs {
  final String imageUrl;

  /// Creates a image preview args instance.
  const ImagePreviewArgs({required this.imageUrl});
}
