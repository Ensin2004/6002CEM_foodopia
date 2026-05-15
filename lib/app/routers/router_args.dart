import 'dart:io';

import '../../features/auth/domain/entities/user_entity.dart';
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

// TODO - Cojean - Confirm with Ensin
/// Typed arguments for the add recipe basic info route.
class AddRecipeBasicInfoArgs {
  final String? draftId;

  const AddRecipeBasicInfoArgs({this.draftId});
}

/// Typed arguments for add meal planning route.
class AddMealPlanArgs {
  final String? userId;
  final String mealType;

  const AddMealPlanArgs({this.userId, required this.mealType});
}

/// Typed arguments for generate AI meal route.
class GenerateAiMealArgs {
  final String? userId;
  final String mealType;

  const GenerateAiMealArgs({this.userId, required this.mealType});
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

/// Typed arguments for user_home route
class HomeArgs {
  final UserEntity user;
  final String role;

  /// Creates a user_home args instance.
  const HomeArgs({required this.user, required this.role});
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
