import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/view/forgot_password_screen.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/main/presentation/view/main_page.dart';
import '../../features/notifications/presentation/view/notifications_page.dart';
import '../../features/recipe/presentation/view/add_recipe_basic_info_page.dart';
import '../../features/recipe/presentation/view/add_recipe_ingredients_page.dart';
import '../../features/recipe/presentation/view/add_recipe_instructions_page.dart';
import '../../features/recipe/presentation/view/add_recipe_method_page.dart';
import '../../features/recipe/presentation/view/add_recipe_review_page.dart';
import '../../features/explore/presentation/view/explore_page.dart';
import '../../features/explore/presentation/view/explore_creator_detail_page.dart';
import '../../features/explore/presentation/view/explore_recipe_detail_page.dart';
import '../../features/library/presentation/view/library_page.dart';
import '../../features/library/presentation/view/library_profile_users_page.dart';
import '../../features/meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../features/meal_plan/presentation/view/add_grocery_list_page.dart';
import '../../features/meal_plan/presentation/view/manage_grocery_list_page.dart';
import '../../features/meal_plan/presentation/view/meal_plan_page.dart';
import '../../features/meal_plan/presentation/view/planning/add_meal_plan_page.dart';
import '../../features/meal_plan/presentation/view/planning/generate_ai_meal_page.dart';
import '../../features/statistics/presentation/view/statistics_page.dart';
import '../../features/statistics/presentation/view/admin_dietary_preference_page.dart';
import '../../features/statistics/presentation/view/admin_gender_page.dart';
import '../../features/statistics/presentation/view/admin_hub_rating_page.dart';
import '../../features/statistics/presentation/view/admin_meal_analytic_page.dart';
import '../../features/statistics/presentation/view/admin_nutrient_insight_page.dart';
import '../../features/statistics/presentation/view/admin_post_analytic_page.dart';
import '../../features/statistics/presentation/view/admin_usage_forecast_page.dart';
import '../../features/statistics/presentation/view/admin_user_usage_page.dart';
import '../../features/statistics/presentation/view/ai_lifestyle_insight_page.dart';
import '../../features/statistics/presentation/view/calories_intake_page.dart';
import '../../features/statistics/presentation/view/calories_posted_page.dart';
import '../../features/statistics/presentation/view/cooking_time_page.dart';
import '../../features/statistics/presentation/view/difficulty_meal_page.dart';
import '../../features/statistics/presentation/view/food_analytic_page.dart';
import '../../features/statistics/presentation/view/grocery_list_statistics_page.dart';
import '../../features/statistics/presentation/view/meal_plan_method_page.dart';
import '../../features/statistics/presentation/view/meal_planned_time_page.dart';
import '../../features/statistics/presentation/view/most_cooked_recipe_page.dart';
import '../../features/statistics/presentation/view/post_analytic_page.dart';
import '../../features/statistics/presentation/view/post_difficulty_page.dart';
import '../../features/statistics/presentation/view/posted_meal_time_page.dart';
import '../../features/statistics/presentation/view/recipe_performance_page.dart';
import '../../features/settings/presentation/view/settings_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_editor_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_viewer_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/change_password_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/edit_profile_page.dart';
import '../../features/settings/presentation/view/subfeatures/admin_age_groups_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_help_center_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_rate_us_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/faq_form_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/issue_detail_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/rating_detail_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/rate_us_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_help_center_page.dart';
import '../../features/user_setup/presentation/view/user_setup_pages.dart';
import 'router_args.dart';

/// Defines behavior for app router.
/// Centralized routing configuration for the entire application.
class AppRouter {
  // =========================================================================
  // ROUTE NAMES
  // =========================================================================

  /// Onboarding screen route.
  static const String onboarding = '/onboarding';

  /// Login screen route.
  static const String login = '/login';

  /// Signup screen route.
  static const String signup = '/signup';

  /// Forgot password screen route.
  static const String forgotPassword = '/forgot-password';

  /// Forgot password sent screen route.
  static const String forgotPasswordSent = '/forgot-password/sent';

  /// Home screen route.
  static const String home = '/user_home';

  /// Settings screen route.
  static const String settings = '/settings';

  /// Edit profile screen route.
  static const String editProfile = '/settings/edit-profile';

  /// Change password screen route.
  static const String changePassword = '/settings/change-password';

  /// Age groups admin screen route.
  static const String ageGroups = '/settings/age-groups';

  /// About screen route.
  static const String about = '/about';

  /// FAQ screen route.
  static const String faq = '/faq';

  /// Rate us screen route.
  static const String rateUs = '/rate-us';

  /// Rating detail screen route.
  static const String ratingDetail = '/rate-us/detail';

  /// Help center screen route.
  static const String helpCenter = '/help-center';

  /// Notifications screen route.
  static const String notifications = '/notifications';

  /// Add recipe screen route.
  static const String addRecipe = '/recipes/add';

  /// Add recipe basic info screen route.
  static const String addRecipeBasicInfo = '/recipes/add/basic-info';

  /// Add recipe ingredients screen route.
  static const String addRecipeIngredients = '/recipes/add/ingredients';

  /// Add recipe instructions screen route.
  static const String addRecipeInstructions = '/recipes/add/instructions';

  /// Add recipe review screen route.
  static const String addRecipeReview = '/recipes/add/review';

  /// Explore screen route.
  static const String explore = '/explore';

  /// Explore recipe detail screen route.
  static const String exploreRecipeDetail = '/explore/recipe';

  /// Library recipe detail screen route.
  static const String libraryRecipeDetail = '/library/recipe';

  /// Library profile users screen route.
  static const String libraryProfileUsers = '/library/profile-users';

  /// Explore creator detail screen route.
  static const String exploreCreatorDetail = '/explore/creator';

  /// Meal plan screen route.
  static const String mealPlan = '/meal-plan';

  /// Add meal plan screen route.
  static const String addMealPlan = '/meal-plan/planning/add-meal';

  /// Generate AI meal screen route.
  static const String generateAiMeal =
      '/meal-plan/planning/add-meal/generate-ai';

  /// Add grocery list screen route.
  static const String addGroceryList = '/meal-plan/grocery-list/add';

  /// Manage grocery list screen route.
  static const String manageGroceryList = '/meal-plan/grocery-list/manage';

  /// Library screen route.
  static const String library = '/library';

  /// Statistics screen route.
  static const String statistics = '/statistics';

  /// AI lifestyle insight screen route.
  static const String aiLifestyleInsight = '/statistics/ai-lifestyle-insight';

  /// Admin meal analytic screen route.
  static const String adminMealAnalytic = '/statistics/admin-meal-analytic';

  /// Admin post analytic screen route.
  static const String adminPostAnalytic = '/statistics/admin-post-analytic';

  /// Admin dietary preference screen route.
  static const String adminDietaryPreference =
      '/statistics/admin-dietary-preference';

  /// Admin gender screen route.
  static const String adminGender = '/statistics/admin-gender';

  /// Admin user usage screen route.
  static const String adminUserUsage = '/statistics/admin-user-usage';

  /// Admin usage forecast screen route.
  static const String adminUsageForecast = '/statistics/admin-usage-forecast';

  /// Admin nutrient insight screen route.
  static const String adminNutrientInsight =
      '/statistics/admin-nutrient-insight';

  /// Admin hub rating screen route.
  static const String adminHubRating = '/statistics/admin-hub-rating';

  /// Food analytic screen route.
  static const String foodAnalytic = '/statistics/food-analytic';

  /// Cooking time screen route.
  static const String cookingTime = '/statistics/cooking-time';

  /// Grocery list statistics screen route.
  static const String groceryListStatistics = '/statistics/grocery-list';

  /// Calories intake screen route.
  static const String caloriesIntake = '/statistics/calories-intake';

  /// Nutrient intake insight screen route.
  static const String nutrientIntakeInsight =
      '/statistics/nutrient-intake-insight';

  /// Difficulty meals screen route.
  static const String difficultyMeals = '/statistics/difficulty-meals';

  /// Meal plan methods screen route.
  static const String mealPlanMethods = '/statistics/meal-plan-methods';

  /// Meal planned time screen route.
  static const String mealPlannedTime = '/statistics/meal-planned-time';

  /// Post analytic screen route.
  static const String postAnalytic = '/statistics/post-analytic';

  /// Calories posted screen route.
  static const String caloriesPosted = '/statistics/calories-posted';

  /// Posted nutrient insight screen route.
  static const String postedNutrientInsight =
      '/statistics/posted-nutrient-insight';

  /// Posted meal time screen route.
  static const String postedMealTime = '/statistics/posted-meal-time';

  /// Recipe performance screen route.
  static const String recipePerformance = '/statistics/recipe-performance';

  /// Most cooked recipes screen route.
  static const String mostCookedRecipes = '/statistics/most-cooked-recipes';

  /// Post difficulty screen route.
  static const String postDifficulty = '/statistics/post-difficulty';

  /// Issue detail screen route.
  static const String issueDetail = '/help-center/issue';

  /// FAQ form screen route.
  static const String faqForm = '/faq/form';

  /// Image preview screen route.
  static const String imagePreview = '/image-preview';

  /// Setup diet screen route.
  static const String setupDiet = '/setup/diet';

  /// Setup allergies screen route.
  static const String setupAllergies = '/setup/allergies';

  /// Setup dislikes screen route.
  static const String setupDislikes = '/setup/dislikes';

  /// Setup calories screen route.
  static const String setupCalories = '/setup/calories';

  /// Setup notifications screen route.
  static const String setupNotifications = '/setup/notifications';

  /// Settings meal preferences screen route.
  static const String settingsMealPreferences = '/settings/meal-preferences';

  /// Settings allergies screen route.
  static const String settingsAllergies = '/settings/allergies';

  /// Settings dislikes screen route.
  static const String settingsDislikes = '/settings/dislikes';

  /// Settings target calories screen route.
  static const String settingsTargetCalories = '/settings/target-calories';

  // =========================================================================
  // ROUTER CREATION
  // =========================================================================

  /// Create router with app state (no direct Firebase dependency!)
  static GoRouter createRouter({
    required bool seenOnboarding,
    required bool isLoggedIn,
    required UserEntity? user,
  }) {
    /// Handles the go router operation.
    return GoRouter(
      initialLocation: _getInitialLocation(seenOnboarding, isLoggedIn),
      redirect: (context, state) {
        /// Handles the handle redirect operation.
        return _handleRedirect(
          state: state,
          seenOnboarding: seenOnboarding,
          isLoggedIn: isLoggedIn,
        );
      },
      routes: _buildRoutes(user), // Passes user to routes.
    );
  }

  // =========================================================================
  // INITIAL LOCATION
  // =========================================================================

  /// Handles the get initial location operation.
  static String _getInitialLocation(bool seenOnboarding, bool isLoggedIn) {
    // Show onboarding if not logged in.
    if (!isLoggedIn) return onboarding;

    // Show home if logged in.
    return home;
  }

  // =========================================================================
  // REDIRECT HANDLER
  // =========================================================================

  /// Handles the handle redirect operation.
  static String? _handleRedirect({
    required GoRouterState state,
    required bool seenOnboarding,
    required bool isLoggedIn,
  }) {
    // Get the current location.
    final location = state.matchedLocation;

    // Check if the current page is an auth page.
    final isAuthPage =
        location == login ||
        location == signup ||
        location == forgotPassword ||
        location == forgotPasswordSent;

    // Check if the current page is onboarding.
    final isOnboarding = location == onboarding;

    // Get the current user from Firebase.
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if the user is currently logged in.
    final isCurrentlyLoggedIn =
        currentUser != null && currentUser.emailVerified;

    // Logged out users always restart from onboarding.
    if (!seenOnboarding &&
        !isCurrentlyLoggedIn &&
        !isOnboarding &&
        !isAuthPage) {
      return onboarding;
    }

    // Not logged in → force login.
    if (!isCurrentlyLoggedIn && !isAuthPage && !isOnboarding) {
      return onboarding;
    }

    // Logged in → prevent auth pages.
    if (isCurrentlyLoggedIn && (isAuthPage || isOnboarding)) {
      return home;
    }

    return null;
  }

  // =========================================================================
  // QUERY PARAM HELPERS
  // =========================================================================

  /// Parses a boolean from a query parameter string.
  static bool? _boolQuery(String? value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    return null;
  }

  // =========================================================================
  // ROUTE BUILDING
  // =========================================================================

  /// Handles the build routes operation.
  static List<GoRoute> _buildRoutes(UserEntity? user) {
    return [
      // =====================================================================
      // AUTH ROUTES
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'onboarding',
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'login',
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'signup',
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // Forgot password.
      GoRoute(
        name: 'forgotPassword',
        path: forgotPassword,
        builder: (context, state) {
          final args = state.extra as ForgotPasswordArgs?;
          return ForgotPasswordScreen(args: args ?? const ForgotPasswordArgs());
        },
      ),

      // Forgot password sent.
      GoRoute(
        name: 'forgotPasswordSent',
        path: forgotPasswordSent,
        builder: (context, state) {
          final args = state.extra as ForgotPasswordSentArgs?;
          return ForgotPasswordSentScreen(
            args: args ?? const ForgotPasswordSentArgs(email: ''),
          );
        },
      ),

      // =====================================================================
      // USER SETUP ROUTES
      // =====================================================================

      // Diet setup.
      GoRoute(
        name: 'setupDiet',
        path: setupDiet,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDietPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),

      // Allergies setup.
      GoRoute(
        name: 'setupAllergies',
        path: setupAllergies,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupAllergiesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),

      // Dislikes setup.
      GoRoute(
        name: 'setupDislikes',
        path: setupDislikes,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDislikesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),

      // Calories setup.
      GoRoute(
        name: 'setupCalories',
        path: setupCalories,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupCaloriesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),

      // Notifications setup.
      GoRoute(
        name: 'setupNotifications',
        path: setupNotifications,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupNotificationPage(
            args: args ?? UserSetupArgs(uid: uid),
          );
        },
      ),

      // =====================================================================
      // SETTINGS - USER SETUP ROUTES
      // =====================================================================

      // Settings meal preferences.
      GoRoute(
        name: 'settingsMealPreferences',
        path: settingsMealPreferences,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDietPage(
            args: args ?? UserSetupArgs(uid: uid, isSettingsMode: true),
          );
        },
      ),

      // Settings allergies.
      GoRoute(
        name: 'settingsAllergies',
        path: settingsAllergies,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupAllergiesPage(
            args: args ?? UserSetupArgs(uid: uid, isSettingsMode: true),
          );
        },
      ),

      // Settings dislikes.
      GoRoute(
        name: 'settingsDislikes',
        path: settingsDislikes,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDislikesPage(
            args: args ?? UserSetupArgs(uid: uid, isSettingsMode: true),
          );
        },
      ),

      // Settings target calories.
      GoRoute(
        name: 'settingsTargetCalories',
        path: settingsTargetCalories,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupCaloriesPage(
            args: args ?? UserSetupArgs(uid: uid, isSettingsMode: true),
          );
        },
      ),

      // =====================================================================
      // HOME ROUTE
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'user_home',
        path: home,
        builder: (context, state) {
          // Extract arguments.
          final args = state.extra as HomeArgs?;

          // Parse tab index.
          final tabIndex =
              int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
              args?.initialTabIndex ??
              0;

          // Parse focused recipe ID.
          final focusedRecipeId =
              args?.focusedRecipeId ??
              state.uri.queryParameters['focusedRecipeId'];

          // Parse focused recipe published status.
          final focusedRecipeIsPublished =
              args?.focusedRecipeIsPublished ??
              _boolQuery(state.uri.queryParameters['focusedRecipeIsPublished']);

          // Parse library refresh token.
          final libraryRefreshToken =
              args?.libraryRefreshToken ??
              state.uri.queryParameters['createdAt'] ??
              state.uri.queryParameters['deletedAt'];

          // Handles null user gracefully.
          final userEntity = args?.user ?? user;

          // Redirect to login if no user.
          if (userEntity == null) {
            // If no user, redirect to login.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(login);
            });
            return const SizedBox.shrink();
          }

          /// Handles the main page operation.
          return MainPage(
            user: userEntity,
            role: args?.role ?? userEntity.role.name,
            initialIndex: tabIndex,
            focusedRecipeId: focusedRecipeId,
            focusedRecipeIsPublished: focusedRecipeIsPublished,
            libraryRefreshToken: libraryRefreshToken,
          );
        },
      ),

      // =====================================================================
      // SETTINGS ROUTES
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'settings',
        path: settings,
        builder: (context, state) {
          final args = state.extra as SettingsArgs?;
          final userEntity = args?.user ?? user;

          // Redirect to login if no user.
          if (userEntity == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(login);
            });
            return const SizedBox.shrink();
          }

          /// Handles the settings page operation.
          return SettingsPage(user: userEntity);
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'editProfile',
        path: editProfile,
        builder: (context, state) {
          final args = state.extra as EditProfileArgs;

          /// Handles the edit profile page operation.
          return EditProfilePage(uid: args.uid);
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'changePassword',
        path: changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),

      // Age groups admin.
      GoRoute(
        name: 'ageGroups',
        path: ageGroups,
        builder: (context, state) => const AdminAgeGroupsPage(),
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'about',
        path: about,
        builder: (context, state) {
          final args = state.extra as AboutArgs;
          return args.isAdmin
              ? AboutEditorPage(documentId: args.documentId, title: args.title)
              : AboutViewerPage(documentId: args.documentId, title: args.title);
        },
      ),

      // =====================================================================
      // SUPPORT ROUTES
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'faq',
        path: faq,
        builder: (context, state) {
          final args = state.extra as FaqArgs?;
          return args?.isAdmin == true
              ? const AdminFaqPage()
              : const UserFaqPage();
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'rateUs',
        path: rateUs,
        builder: (context, state) {
          final args = state.extra as RateUsArgs?;
          return args?.isAdmin == true
              ? const AdminRateUsPage()
              : const RateUsPage();
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'ratingDetail',
        path: ratingDetail,
        builder: (context, state) {
          final args = state.extra as RatingDetailArgs;
          return RatingDetailPage(
            rating: args.rating,
            userProfile: args.userProfile,
          );
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'helpCenter',
        path: helpCenter,
        builder: (context, state) {
          final args = state.extra as HelpCenterArgs?;
          return args?.isAdmin == true
              ? const AdminHelpCenterPage()
              : const UserHelpCenterPage();
        },
      ),

      // =====================================================================
      // NOTIFICATIONS
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'notifications',
        path: notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      // =====================================================================
      // RECIPE ROUTES
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'addRecipe',
        path: addRecipe,
        builder: (context, state) => const AddRecipePage(),
      ),

      // Add recipe basic info.
      GoRoute(
        name: 'addRecipeBasicInfo',
        path: addRecipeBasicInfo,
        builder: (context, state) {
          final args = state.extra as AddRecipeBasicInfoArgs?;
          return AddRecipeBasicInfoPage(
            key: ValueKey(
              args?.recipeId ?? args?.draftId ?? args?.aiRecipe?.id,
            ),
            recipeId: args?.recipeId,
            returnToReview: args?.returnToReview ?? false,
            initialAiRecipe: args?.aiRecipe,
            initialAiRequest: args?.aiRequest,
            userId: args?.userId,
            initialImageFile: args?.initialImageFile,
            initialRecipeName: args?.initialRecipeName,
            initialRecipeDescription: args?.initialRecipeDescription,
            initialGeneratedIngredients:
                args?.initialGeneratedIngredients ?? const [],
            initialGeneratedInstructions:
                args?.initialGeneratedInstructions ?? const [],
          );
        },
      ),

      // Add recipe ingredients.
      GoRoute(
        name: 'addRecipeIngredients',
        path: addRecipeIngredients,
        builder: (context, state) {
          final args = state.extra as AddRecipeIngredientsArgs;
          return AddRecipeIngredientsPage(
            recipeId: args.recipeId,
            initialVisibility: args.visibility,
            returnToReview: args.returnToReview,
            initialAiRecipe: args.aiRecipe,
            initialAiRequest: args.aiRequest,
            userId: args.userId,
            aiDraftBasicInfo: args.aiDraftBasicInfo,
            initialGeneratedIngredients: args.initialGeneratedIngredients,
            initialGeneratedInstructions: args.initialGeneratedInstructions,
          );
        },
      ),

      // Add recipe instructions.
      GoRoute(
        name: 'addRecipeInstructions',
        path: addRecipeInstructions,
        builder: (context, state) {
          final args = state.extra as AddRecipeInstructionsArgs;
          return AddRecipeInstructionsPage(
            recipeId: args.recipeId,
            initialVisibility: args.visibility,
            returnToReview: args.returnToReview,
            initialAiRecipe: args.aiRecipe,
            initialAiRequest: args.aiRequest,
            userId: args.userId,
            aiDraftBasicInfo: args.aiDraftBasicInfo,
            aiDraftIngredients: args.aiDraftIngredients,
            initialGeneratedInstructions: args.initialGeneratedInstructions,
          );
        },
      ),

      // Add recipe review.
      GoRoute(
        name: 'addRecipeReview',
        path: addRecipeReview,
        builder: (context, state) {
          final args = state.extra as AddRecipeReviewArgs;
          return AddRecipeReviewPage(
            recipeId: args.recipeId,
            initialAiRecipe: args.aiRecipe,
            initialAiRequest: args.aiRequest,
            userId: args.userId,
            aiDraftBasicInfo: args.aiDraftBasicInfo,
            aiDraftIngredients: args.aiDraftIngredients,
            aiDraftInstructions: args.aiDraftInstructions,
            aiDraftUseSections: args.aiDraftUseSections,
          );
        },
      ),

      // =====================================================================
      // EXPLORE ROUTES
      // =====================================================================

      // Explore page.
      GoRoute(
        name: 'explore',
        path: explore,
        builder: (context, state) {
          // Check for meal plan selection.
          final selection = state.extra is MealPlanSelectionArgs
              ? state.extra as MealPlanSelectionArgs
              : null;

          // Show explore with meal plan selection if available.
          if (selection != null) {
            return ExplorePage(showAppBar: true, mealPlanSelection: selection);
          }

          // Show explore as main page tab.
          final userEntity = user;
          if (userEntity == null) {
            return const ExplorePage();
          }

          return MainPage(
            user: userEntity,
            role: userEntity.role.name,
            initialIndex: 1,
          );
        },
      ),

      // Explore recipe detail.
      GoRoute(
        name: 'exploreRecipeDetail',
        path: exploreRecipeDetail,
        builder: (context, state) {
          final args = state.extra as ExploreRecipeDetailArgs?;
          return ExploreRecipeDetailPage(
            recipeId: args?.recipeId ?? '',
            mealPlanSelection: args?.mealPlanSelection,
            isAdminModeration: args?.isAdminModeration ?? false,
            isPublished: args?.isPublished ?? true,
          );
        },
      ),

      // Explore creator detail.
      GoRoute(
        name: 'exploreCreatorDetail',
        path: exploreCreatorDetail,
        builder: (context, state) {
          final args = state.extra as ExploreCreatorDetailArgs?;
          return ExploreCreatorDetailPage(creatorUid: args?.creatorUid ?? '');
        },
      ),

      // =====================================================================
      // LIBRARY ROUTES
      // =====================================================================

      // Library profile users.
      GoRoute(
        name: 'libraryProfileUsers',
        path: libraryProfileUsers,
        builder: (context, state) {
          final args = state.extra as LibraryProfileUsersArgs?;
          return LibraryProfileUsersPage(
            showFollowers: args?.showFollowers ?? true,
            ownerUid: args?.ownerUid,
          );
        },
      ),

      // =====================================================================
      // MEAL PLAN ROUTES
      // =====================================================================

      // Meal plan page.
      GoRoute(
        name: 'mealPlan',
        path: mealPlan,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is MealPlanArgs ? extra : null;

          // Show as main page tab if user exists.
          final userEntity = user;
          if (userEntity != null) {
            return MainPage(
              user: userEntity,
              role: userEntity.role.name,
              initialIndex: 3,
              initialMealPlanTabIndex: args?.initialTabIndex ?? 0,
            );
          }

          // Show standalone meal plan page.
          return MealPlanPage(
            initialTabIndex: args?.initialTabIndex ?? 0,
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      // Add meal plan.
      GoRoute(
        name: 'addMealPlan',
        path: addMealPlan,
        builder: (context, state) {
          final args = state.extra as AddMealPlanArgs?;
          return AddMealPlanPage(
            mealType: args?.mealType ?? 'Breakfast',
            mealCategoryId: args?.mealCategoryId ?? 'breakfast',
            selectedDate: args?.selectedDate ?? DateTime.now(),
            existingRecipeIds: args?.existingRecipeIds ?? const [],
            existingMealNames: args?.existingMealNames ?? const [],
            calorieBudget:
                args?.calorieBudget ?? const MealCalorieBudget.empty(),
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      // Generate AI meal.
      GoRoute(
        name: 'generateAiMeal',
        path: generateAiMeal,
        builder: (context, state) {
          final args = state.extra as GenerateAiMealArgs?;
          return GenerateAiMealPage(
            mealType: args?.mealType ?? 'Breakfast',
            mealCategoryId: args?.mealCategoryId,
            selectedDate: args?.selectedDate,
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
            initialRequest: args?.initialRequest,
            autoGenerate: args?.autoGenerate ?? false,
            calorieBudget:
                args?.calorieBudget ?? const MealCalorieBudget.empty(),
            existingMealNames: args?.existingMealNames ?? const [],
          );
        },
      ),

      // Add grocery list.
      GoRoute(
        name: 'addGroceryList',
        path: addGroceryList,
        builder: (context, state) {
          final args = state.extra as AddGroceryListArgs?;
          return AddGroceryListPage(
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      // Manage grocery list.
      GoRoute(
        name: 'manageGroceryList',
        path: manageGroceryList,
        builder: (context, state) {
          final args = state.extra as ManageGroceryListArgs?;
          return ManageGroceryListPage(
            listId: args?.listId ?? 'weekly_groceries',
          );
        },
      ),

      // =====================================================================
      // LIBRARY ROUTES
      // =====================================================================

      // Library page.
      GoRoute(
        name: 'library',
        path: library,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is LibraryArgs ? extra : null;
          final selection = extra is MealPlanSelectionArgs
              ? extra
              : args?.mealPlanSelection;

          return LibraryPage(
            showAppBar: true,
            focusedRecipeId: args?.focusedRecipeId,
            focusedRecipeIsPublished: args?.focusedRecipeIsPublished,
            mealPlanSelection: selection,
          );
        },
      ),

      // Library recipe detail.
      GoRoute(
        name: 'libraryRecipeDetail',
        path: libraryRecipeDetail,
        builder: (context, state) {
          final args = state.extra as LibraryRecipeDetailArgs?;
          return ExploreRecipeDetailPage(
            recipeId: args?.recipeId ?? '',
            showLibraryActions: args?.isSelfPublished ?? false,
            isPublished: args?.isPublished ?? true,
            initialIsModerationHidden: args?.isModerationHidden ?? false,
            initialModerationHiddenReason:
                args?.moderationHiddenReason ?? '',
            mealPlanSelection: args?.mealPlanSelection,
          );
        },
      ),

      // =====================================================================
      // STATISTICS ROUTES
      // =====================================================================

      // Statistics main.
      GoRoute(
        name: 'statistics',
        path: statistics,
        builder: (context, state) {
          final args = state.extra as StatisticsArgs?;
          return StatisticsPage(isAdmin: args?.isAdmin ?? false);
        },
      ),

      // Admin statistics routes.
      GoRoute(
        name: 'adminMealAnalytic',
        path: adminMealAnalytic,
        builder: (context, state) => const AdminMealAnalyticPage(),
      ),

      GoRoute(
        name: 'adminPostAnalytic',
        path: adminPostAnalytic,
        builder: (context, state) => const AdminPostAnalyticPage(),
      ),

      GoRoute(
        name: 'adminDietaryPreference',
        path: adminDietaryPreference,
        builder: (context, state) => const AdminDietaryPreferencePage(),
      ),

      GoRoute(
        name: 'adminGender',
        path: adminGender,
        builder: (context, state) => const AdminGenderPage(),
      ),

      GoRoute(
        name: 'adminUserUsage',
        path: adminUserUsage,
        builder: (context, state) => const AdminUserUsagePage(),
      ),

      GoRoute(
        name: 'adminUsageForecast',
        path: adminUsageForecast,
        builder: (context, state) => const AdminUsageForecastPage(),
      ),

      GoRoute(
        name: 'adminNutrientInsight',
        path: adminNutrientInsight,
        builder: (context, state) => const AdminNutrientInsightPage(),
      ),

      GoRoute(
        name: 'adminHubRating',
        path: adminHubRating,
        builder: (context, state) => const AdminHubRatingPage(),
      ),

      // User statistics routes.
      GoRoute(
        name: 'aiLifestyleInsight',
        path: aiLifestyleInsight,
        builder: (context, state) => const AiLifestyleInsightPage(),
      ),

      GoRoute(
        name: 'foodAnalytic',
        path: foodAnalytic,
        builder: (context, state) => const FoodAnalyticPage(),
      ),

      GoRoute(
        name: 'cookingTime',
        path: cookingTime,
        builder: (context, state) => const CookingTimePage(),
      ),

      GoRoute(
        name: 'groceryListStatistics',
        path: groceryListStatistics,
        builder: (context, state) => const GroceryListStatisticsPage(),
      ),

      GoRoute(
        name: 'caloriesIntake',
        path: caloriesIntake,
        builder: (context, state) => const CaloriesIntakePage(),
      ),

      GoRoute(
        name: 'nutrientIntakeInsight',
        path: nutrientIntakeInsight,
        builder: (context, state) =>
            const CaloriesIntakePage(showInsight: true),
      ),

      GoRoute(
        name: 'difficultyMeals',
        path: difficultyMeals,
        builder: (context, state) => const DifficultyMealPage(),
      ),

      GoRoute(
        name: 'mealPlanMethods',
        path: mealPlanMethods,
        builder: (context, state) => const MealPlanMethodPage(),
      ),

      GoRoute(
        name: 'postAnalytic',
        path: postAnalytic,
        builder: (context, state) => const PostAnalyticPage(),
      ),

      GoRoute(
        name: 'caloriesPosted',
        path: caloriesPosted,
        builder: (context, state) => const CaloriesPostedPage(),
      ),

      GoRoute(
        name: 'postedNutrientInsight',
        path: postedNutrientInsight,
        builder: (context, state) =>
            const CaloriesPostedPage(showInsight: true),
      ),

      GoRoute(
        name: 'postedMealTime',
        path: postedMealTime,
        builder: (context, state) => const PostedMealTimePage(),
      ),

      GoRoute(
        name: 'recipePerformance',
        path: recipePerformance,
        builder: (context, state) => const RecipePerformancePage(),
      ),

      GoRoute(
        name: 'mealPlannedTime',
        path: mealPlannedTime,
        builder: (context, state) => const MealPlannedTimePage(),
      ),

      GoRoute(
        name: 'mostCookedRecipes',
        path: mostCookedRecipes,
        builder: (context, state) => const MostCookedRecipePage(),
      ),

      GoRoute(
        name: 'postDifficulty',
        path: postDifficulty,
        builder: (context, state) => const PostDifficultyPage(),
      ),

      // =====================================================================
      // SUPPORT DETAIL ROUTES
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'issueDetail',
        path: issueDetail,
        builder: (context, state) {
          final args = state.extra as IssueDetailArgs;

          /// Handles the issue detail page operation.
          return IssueDetailPage(
            issue: args.issue,
            userEmail: args.userEmail,
            userName: args.userName,
            isAdmin: args.isAdmin,
            onStatusChanged: args.onStatusChanged,
          );
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'faqForm',
        path: faqForm,
        builder: (context, state) {
          final args = state.extra as FaqFormArgs;

          /// Handles the faq form page operation.
          return FaqFormPage(item: args.item, onSave: args.onSave);
        },
      ),

      // =====================================================================
      // IMAGE PREVIEW
      // =====================================================================

      /// Creates a go route instance.
      GoRoute(
        name: 'imagePreview',
        path: imagePreview,
        builder: (context, state) {
          final args = state.extra as ImagePreviewArgs;

          /// Handles the scaffold operation.
          return Scaffold(
            appBar: CustomAppBar(
              title: '',
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            body: Center(
              child: PhotoView(
                imageProvider: args.imageUrl.startsWith('http')
                    ? NetworkImage(args.imageUrl)
                    : FileImage(File(args.imageUrl)),
              ),
            ),
          );
        },
      ),
    ];
  }
}
