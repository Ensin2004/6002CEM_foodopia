import 'dart:io';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../features/meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../features/recipe/domain/entities/add_recipe_basic_info.dart';
import '../../features/recipe/domain/entities/add_recipe_ingredient.dart';
import '../../features/recipe/domain/entities/add_recipe_instruction.dart';
import '../../features/settings/domain/entities/faq_item.dart';
import '../../features/settings/domain/entities/help_center_issue.dart';
import '../../features/settings/domain/entities/rating.dart';
import '../../features/settings/domain/entities/user_profile.dart';

/// Callback type for saving FAQ items.
typedef FaqSaveCallback =
    Future<bool> Function({
      required String question,
      required String answer,
      File? questionImageFile,
      File? answerImageFile,
    });

// ============================================================================
// AUTHENTICATION ROUTE ARGUMENTS
// ============================================================================

/// Marker for routes that do not need payload but are reached after auth.
class AuthenticatedRouteArgs {
  /// Creates a authenticated route args instance.
  const AuthenticatedRouteArgs();
}

/// Typed arguments for forgot password route.
class ForgotPasswordArgs {
  /// Initial email to pre-fill in the form.
  final String? initialEmail;

  /// Creates a new forgot password args instance.
  const ForgotPasswordArgs({this.initialEmail});
}

/// Typed arguments for forgot password sent route.
class ForgotPasswordSentArgs {
  /// Email address the reset link was sent to.
  final String email;

  /// Creates a new forgot password sent args instance.
  const ForgotPasswordSentArgs({required this.email});
}

// ============================================================================
// EXPLORE ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for explore recipe detail route.
class ExploreRecipeDetailArgs {
  /// ID of the recipe to display.
  final String recipeId;

  /// Optional meal plan selection data.
  final MealPlanSelectionArgs? mealPlanSelection;

  /// Whether the detail page is opened from admin moderation.
  final bool isAdminModeration;

  /// Current recipe publication state, if known.
  final bool isPublished;

  /// Creates a new explore recipe detail args instance.
  const ExploreRecipeDetailArgs({
    required this.recipeId,
    this.mealPlanSelection,
    this.isAdminModeration = false,
    this.isPublished = true,
  });
}

/// Typed arguments for explore creator detail route.
class ExploreCreatorDetailArgs {
  /// ID of the creator to display.
  final String creatorUid;

  /// Creates a new explore creator detail args instance.
  const ExploreCreatorDetailArgs({required this.creatorUid});
}

// ============================================================================
// LIBRARY ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for library recipe detail route.
class LibraryRecipeDetailArgs {
  /// ID of the recipe to display.
  final String recipeId;

  /// Whether the recipe is self-published.
  final bool isSelfPublished;

  /// Whether the recipe is published.
  final bool isPublished;

  /// Optional meal plan selection data.
  final MealPlanSelectionArgs? mealPlanSelection;

  /// Creates a new library recipe detail args instance.
  const LibraryRecipeDetailArgs({
    required this.recipeId,
    required this.isSelfPublished,
    required this.isPublished,
    this.mealPlanSelection,
  });
}

/// Typed arguments for library route.
class LibraryArgs {
  /// ID of the recipe to focus on.
  final String? focusedRecipeId;

  /// Whether the focused recipe is published.
  final bool? focusedRecipeIsPublished;

  /// Optional meal plan selection data.
  final MealPlanSelectionArgs? mealPlanSelection;

  /// Creates a new library args instance.
  const LibraryArgs({
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.mealPlanSelection,
  });
}

/// Typed arguments for library profile users route.
class LibraryProfileUsersArgs {
  /// Whether to show followers or following.
  final bool showFollowers;

  /// Owner UID for the profile.
  final String? ownerUid;

  /// Creates a new library profile users args instance.
  const LibraryProfileUsersArgs({required this.showFollowers, this.ownerUid});
}

// ============================================================================
// MEAL PLAN ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for the meal plan route.
class MealPlanArgs {
  /// Initial tab index for the meal plan.
  final int initialTabIndex;

  /// User ID.
  final String? userId;

  /// Creates a new meal plan args instance.
  const MealPlanArgs({this.initialTabIndex = 0, this.userId});
}

/// Typed arguments for add grocery list route.
class AddGroceryListArgs {
  /// User ID.
  final String? userId;

  /// Creates a new add grocery list args instance.
  const AddGroceryListArgs({this.userId});
}

/// Typed arguments for manage grocery list route.
class ManageGroceryListArgs {
  /// ID of the grocery list.
  final String listId;

  /// Creates a new manage grocery list args instance.
  const ManageGroceryListArgs({required this.listId});
}

/// Typed arguments for selecting an existing recipe into a meal plan.
class MealPlanSelectionArgs {
  /// User ID.
  final String userId;

  /// Selected date for the meal plan.
  final DateTime selectedDate;

  /// Meal category ID.
  final String mealCategoryId;

  /// Meal category name.
  final String mealCategoryName;

  /// Source of the selection.
  final String source;

  /// Existing recipe IDs to exclude.
  final List<String> existingRecipeIds;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Creates a new meal plan selection args instance.
  const MealPlanSelectionArgs({
    required this.userId,
    required this.selectedDate,
    required this.mealCategoryId,
    required this.mealCategoryName,
    required this.source,
    this.existingRecipeIds = const [],
    this.existingMealNames = const [],
    this.calorieBudget = const MealCalorieBudget.empty(),
  });
}

/// Typed arguments for add meal planning route.
class AddMealPlanArgs {
  /// User ID.
  final String? userId;

  /// Type of meal (e.g., Breakfast, Lunch, Dinner).
  final String mealType;

  /// Meal category ID.
  final String? mealCategoryId;

  /// Selected date.
  final DateTime? selectedDate;

  /// Existing recipe IDs to exclude.
  final List<String> existingRecipeIds;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Creates a new add meal plan args instance.
  const AddMealPlanArgs({
    this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.existingRecipeIds = const [],
    this.existingMealNames = const [],
    this.calorieBudget = const MealCalorieBudget.empty(),
  });
}

/// Typed arguments for generate AI meal route.
class GenerateAiMealArgs {
  /// User ID.
  final String? userId;

  /// Type of meal.
  final String mealType;

  /// Meal category ID.
  final String? mealCategoryId;

  /// Selected date.
  final DateTime? selectedDate;

  /// Initial generation request.
  final AddMealAiGenerationRequest? initialRequest;

  /// Whether to auto-generate.
  final bool autoGenerate;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  /// Creates a new generate AI meal args instance.
  const GenerateAiMealArgs({
    this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
    this.calorieBudget = const MealCalorieBudget.empty(),
    this.existingMealNames = const [],
  });
}

// ============================================================================
// RECIPE ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for the add recipe basic info route.
class AddRecipeBasicInfoArgs {
  /// Recipe ID for editing.
  final String? recipeId;

  /// Draft ID for video generation.
  final String? draftId;

  /// Whether to return to review.
  final bool returnToReview;

  /// AI recipe data.
  final AddMealAiRecipe? aiRecipe;

  /// AI generation request.
  final AddMealAiGenerationRequest? aiRequest;

  /// User ID.
  final String? userId;

  /// Initial image selected from upload-image flow.
  final File? initialImageFile;

  /// Initial recipe name generated from upload-image flow.
  final String? initialRecipeName;

  /// Initial recipe description generated from upload-image flow.
  final String? initialRecipeDescription;

  /// Ingredients generated from the initial image.
  final List<AddRecipeIngredient> initialGeneratedIngredients;

  /// Instructions generated from the initial image.
  final List<AddRecipeInstruction> initialGeneratedInstructions;

  /// Creates a new add recipe basic info args instance.
  const AddRecipeBasicInfoArgs({
    this.recipeId,
    this.draftId,
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.initialImageFile,
    this.initialRecipeName,
    this.initialRecipeDescription,
    this.initialGeneratedIngredients = const [],
    this.initialGeneratedInstructions = const [],
  });
}

/// Typed arguments for the add recipe ingredients route.
class AddRecipeIngredientsArgs {
  /// Recipe ID.
  final String recipeId;

  /// Visibility setting.
  final String visibility;

  /// Whether to return to review.
  final bool returnToReview;

  /// AI recipe data.
  final AddMealAiRecipe? aiRecipe;

  /// AI generation request.
  final AddMealAiGenerationRequest? aiRequest;

  /// User ID.
  final String? userId;

  /// AI draft basic info.
  final AddRecipeBasicInfo? aiDraftBasicInfo;

  /// Ingredients generated before this step.
  final List<AddRecipeIngredient> initialGeneratedIngredients;

  /// Instructions generated before this step.
  final List<AddRecipeInstruction> initialGeneratedInstructions;

  /// Creates a new add recipe ingredients args instance.
  const AddRecipeIngredientsArgs({
    required this.recipeId,
    this.visibility = 'private',
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.initialGeneratedIngredients = const [],
    this.initialGeneratedInstructions = const [],
  });
}

/// Typed arguments for the add recipe instructions route.
class AddRecipeInstructionsArgs {
  /// Recipe ID.
  final String recipeId;

  /// Visibility setting.
  final String visibility;

  /// Whether to return to review.
  final bool returnToReview;

  /// AI recipe data.
  final AddMealAiRecipe? aiRecipe;

  /// AI generation request.
  final AddMealAiGenerationRequest? aiRequest;

  /// User ID.
  final String? userId;

  /// AI draft basic info.
  final AddRecipeBasicInfo? aiDraftBasicInfo;

  /// AI draft ingredients.
  final List<AddRecipeIngredient> aiDraftIngredients;

  /// Instructions generated before this step.
  final List<AddRecipeInstruction> initialGeneratedInstructions;

  /// Creates a new add recipe instructions args instance.
  const AddRecipeInstructionsArgs({
    required this.recipeId,
    this.visibility = 'private',
    this.returnToReview = false,
    this.aiRecipe,
    this.aiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.initialGeneratedInstructions = const [],
  });
}

/// Typed arguments for the add recipe review route.
class AddRecipeReviewArgs {
  /// Recipe ID.
  final String recipeId;

  /// AI recipe data.
  final AddMealAiRecipe? aiRecipe;

  /// AI generation request.
  final AddMealAiGenerationRequest? aiRequest;

  /// User ID.
  final String? userId;

  /// AI draft basic info.
  final AddRecipeBasicInfo? aiDraftBasicInfo;

  /// AI draft ingredients.
  final List<AddRecipeIngredient> aiDraftIngredients;

  /// AI draft instructions.
  final List<AddRecipeInstruction> aiDraftInstructions;

  /// Whether the AI draft uses sections.
  final bool aiDraftUseSections;

  /// Creates a new add recipe review args instance.
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

// ============================================================================
// STATISTICS ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for statistics route.
class StatisticsArgs {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a new statistics args instance.
  const StatisticsArgs({required this.isAdmin});
}

/// Typed arguments for statistics detail routes.
class StatisticsDetailArgs {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a new statistics detail args instance.
  const StatisticsDetailArgs({this.isAdmin = false});
}

// ============================================================================
// HOME ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for user_home route.
class HomeArgs {
  /// Authenticated user.
  final UserEntity? user;

  /// User role.
  final String? role;

  /// Initial tab index.
  final int initialTabIndex;

  /// ID of the recipe to focus on.
  final String? focusedRecipeId;

  /// Whether the focused recipe is published.
  final bool? focusedRecipeIsPublished;

  /// Token for refreshing the library.
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

// ============================================================================
// SETTINGS ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for edit profile route.
class EditProfileArgs {
  /// User ID.
  final String uid;

  /// Creates a edit profile args instance.
  const EditProfileArgs({required this.uid});
}

/// Typed arguments for settings route.
class SettingsArgs {
  /// Authenticated user.
  final UserEntity user;

  /// Creates a settings args instance.
  const SettingsArgs({required this.user});
}

// ============================================================================
// ABOUT ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for about pages.
class AboutArgs {
  /// Document ID.
  final String documentId;

  /// Title of the page.
  final String title;

  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a about args instance.
  const AboutArgs({
    required this.documentId,
    required this.title,
    required this.isAdmin,
  });
}

// ============================================================================
// USER SETUP ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for the user setup flow after signup.
class UserSetupArgs {
  /// User ID.
  final String uid;

  /// Authenticated user.
  final UserEntity? user;

  /// User role.
  final String? role;

  /// Whether the setup is in settings mode.
  final bool isSettingsMode;

  /// Creates a new user setup args instance.
  const UserSetupArgs({
    required this.uid,
    this.user,
    this.role,
    this.isSettingsMode = false,
  });
}

// ============================================================================
// SUPPORT ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for FAQ list route.
class FaqArgs {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a faq args instance.
  const FaqArgs({required this.isAdmin});
}

/// Typed arguments for rating route.
class RateUsArgs {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a rate us args instance.
  const RateUsArgs({required this.isAdmin});
}

/// Typed arguments for rating detail route.
class RatingDetailArgs {
  /// Rating entity.
  final RatingEntity rating;

  /// User profile.
  final UserProfile? userProfile;

  /// Creates a rating detail args instance.
  const RatingDetailArgs({required this.rating, this.userProfile});
}

/// Typed arguments for help center route.
class HelpCenterArgs {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Creates a help center args instance.
  const HelpCenterArgs({required this.isAdmin});
}

/// Typed arguments for issue detail route.
class IssueDetailArgs {
  /// Help center issue.
  final HelpCenterIssue issue;

  /// User email.
  final String? userEmail;

  /// User name.
  final String? userName;

  /// Whether the user is an admin.
  final bool isAdmin;

  /// Callback when status changes.
  final void Function()? onStatusChanged;

  /// Creates a issue detail args instance.
  const IssueDetailArgs({
    required this.issue,
    this.userEmail,
    this.userName,
    this.isAdmin = false,
    this.onStatusChanged,
  });
}

/// Typed arguments for FAQ form route.
class FaqFormArgs {
  /// FAQ item for editing.
  final FaqItem? item;

  /// Save callback.
  final FaqSaveCallback onSave;

  /// Creates a faq form args instance.
  const FaqFormArgs({this.item, required this.onSave});
}

// ============================================================================
// IMAGE PREVIEW ROUTE ARGUMENTS
// ============================================================================

/// Typed arguments for image preview route.
class ImagePreviewArgs {
  /// URL of the image to preview.
  final String imageUrl;

  /// Creates a image preview args instance.
  const ImagePreviewArgs({required this.imageUrl});
}
