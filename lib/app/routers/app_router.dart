import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/main/presentation/view/main_page.dart';
import '../../features/notifications/presentation/view/notifications_page.dart';
import '../../features/recipe/presentation/view/add_recipe_basic_info_page.dart';
import '../../features/recipe/presentation/view/add_recipe_ingredients_page.dart';
import '../../features/recipe/presentation/view/add_recipe_instructions_page.dart';
import '../../features/recipe/presentation/view/add_recipe_method_page.dart';
import '../../features/explore/presentation/view/explore_page.dart';
import '../../features/explore/presentation/view/explore_creator_detail_page.dart';
import '../../features/explore/presentation/view/explore_recipe_detail_page.dart';
import '../../features/library/presentation/view/library_page.dart';
import '../../features/meal_plan/presentation/view/add_grocery_list_page.dart';
import '../../features/meal_plan/presentation/view/manage_grocery_list_page.dart';
import '../../features/meal_plan/presentation/view/meal_plan_page.dart';
import '../../features/meal_plan/presentation/view/planning/add_meal_plan_page.dart';
import '../../features/meal_plan/presentation/view/planning/generate_ai_meal_page.dart';
import '../../features/statistics/presentation/view/statistics_page.dart';
import '../../features/settings/presentation/view/settings_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_editor_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_viewer_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/change_password_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/edit_profile_page.dart';
import '../../features/settings/presentation/view/subfeatures/admin_age_groups_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_help_center_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/faq_form_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/issue_detail_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/rate_us_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_help_center_page.dart';
import '../../features/user_setup/presentation/view/user_setup_pages.dart';
import 'router_args.dart';

/// Defines behavior for app router.
class AppRouter {
  // Route names
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/user_home';
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String changePassword = '/settings/change-password';
  static const String ageGroups = '/settings/age-groups';
  static const String about = '/about';
  static const String faq = '/faq';
  static const String rateUs = '/rate-us';
  static const String helpCenter = '/help-center';
  static const String notifications = '/notifications';
  static const String addRecipe = '/recipes/add';
  static const String addRecipeBasicInfo = '/recipes/add/basic-info';
  static const String addRecipeIngredients = '/recipes/add/ingredients';
  static const String addRecipeInstructions = '/recipes/add/instructions';
  static const String explore = '/explore';
  static const String exploreRecipeDetail = '/explore/recipe';
  static const String exploreCreatorDetail = '/explore/creator';
  static const String mealPlan = '/meal-plan';
  static const String addMealPlan = '/meal-plan/planning/add-meal';
  static const String generateAiMeal =
      '/meal-plan/planning/add-meal/generate-ai';
  static const String addGroceryList = '/meal-plan/grocery-list/add';
  static const String manageGroceryList = '/meal-plan/grocery-list/manage';
  static const String library = '/library';
  static const String statistics = '/statistics';
  static const String issueDetail = '/help-center/issue';
  static const String faqForm = '/faq/form';
  static const String imagePreview = '/image-preview';
  static const String setupDiet = '/setup/diet';
  static const String setupAllergies = '/setup/allergies';
  static const String setupDislikes = '/setup/dislikes';
  static const String setupCalories = '/setup/calories';
  static const String setupNotifications = '/setup/notifications';
  static const String settingsMealPreferences = '/settings/meal-preferences';
  static const String settingsAllergies = '/settings/allergies';
  static const String settingsDislikes = '/settings/dislikes';
  static const String settingsTargetCalories = '/settings/target-calories';

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
      routes: _buildRoutes(user), // Passes user to routes
    );
  }

  /// Handles the get initial location operation.
  static String _getInitialLocation(bool seenOnboarding, bool isLoggedIn) {
    if (!isLoggedIn) return onboarding;
    return home;
  }

  /// Handles the handle redirect operation.
  static String? _handleRedirect({
    required GoRouterState state,
    required bool seenOnboarding,
    required bool isLoggedIn,
  }) {
    final location = state.matchedLocation;
    final isAuthPage = location == login || location == signup;
    final isOnboarding = location == onboarding;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentlyLoggedIn =
        currentUser != null && currentUser.emailVerified;

    // Logged out users always restart from onboarding. Login and signup remain
    // reachable from onboarding actions.
    if (!seenOnboarding &&
        !isCurrentlyLoggedIn &&
        !isOnboarding &&
        !isAuthPage) {
      return onboarding;
    }

    // Not logged in → force login
    if (!isCurrentlyLoggedIn && !isAuthPage && !isOnboarding) {
      return onboarding;
    }

    // Logged in → prevent auth pages
    if (isCurrentlyLoggedIn && (isAuthPage || isOnboarding)) {
      return home;
    }

    return null;
  }

  /// Handles the build routes operation.
  static List<GoRoute> _buildRoutes(UserEntity? user) {
    return [
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
      GoRoute(
        name: 'setupDiet',
        path: setupDiet,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDietPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),
      GoRoute(
        name: 'setupAllergies',
        path: setupAllergies,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupAllergiesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),
      GoRoute(
        name: 'setupDislikes',
        path: setupDislikes,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupDislikesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),
      GoRoute(
        name: 'setupCalories',
        path: setupCalories,
        builder: (context, state) {
          final args = state.extra as UserSetupArgs?;
          final uid = args?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
          return UserSetupCaloriesPage(args: args ?? UserSetupArgs(uid: uid));
        },
      ),
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

      /// Creates a go route instance.
      GoRoute(
        name: 'user_home',
        path: home,
        builder: (context, state) {
          final args = state.extra as HomeArgs?;
          // Handles null user gracefully
          final userEntity = args?.user ?? user;
          if (userEntity == null) {
            // If no user, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(login);
            });
            return const SizedBox.shrink();
          }

          /// Handles the main page operation.
          return MainPage(user: userEntity, role: args?.role ?? 'user');
        },
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'settings',
        path: settings,
        builder: (context, state) {
          final args = state.extra as SettingsArgs?;
          final userEntity = args?.user ?? user;
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
        builder: (context, state) => const RateUsPage(),
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

      /// Creates a go route instance.
      GoRoute(
        name: 'notifications',
        path: notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      /// Creates a go route instance.
      GoRoute(
        name: 'addRecipe',
        path: addRecipe,
        builder: (context, state) => const AddRecipePage(),
      ),

      // TODO - Cojean - Confirm with Ensin
      GoRoute(
        name: 'addRecipeBasicInfo',
        path: addRecipeBasicInfo,
        builder: (context, state) {
          final args = state.extra as AddRecipeBasicInfoArgs?;
          return AddRecipeBasicInfoPage(key: ValueKey(args?.draftId));
        },
      ),

      GoRoute(
        name: 'addRecipeIngredients',
        path: addRecipeIngredients,
        builder: (context, state) {
          final args = state.extra as AddRecipeIngredientsArgs;
          return AddRecipeIngredientsPage(recipeId: args.recipeId);
        },
      ),

      GoRoute(
        name: 'addRecipeInstructions',
        path: addRecipeInstructions,
        builder: (context, state) {
          final args = state.extra as AddRecipeInstructionsArgs;
          return AddRecipeInstructionsPage(recipeId: args.recipeId);
        },
      ),

      GoRoute(
        name: 'explore',
        path: explore,
        builder: (context, state) => const ExplorePage(),
      ),

      GoRoute(
        name: 'exploreRecipeDetail',
        path: exploreRecipeDetail,
        builder: (context, state) {
          final args = state.extra as ExploreRecipeDetailArgs?;
          return ExploreRecipeDetailPage(recipeId: args?.recipeId ?? '');
        },
      ),

      GoRoute(
        name: 'exploreCreatorDetail',
        path: exploreCreatorDetail,
        builder: (context, state) {
          final args = state.extra as ExploreCreatorDetailArgs?;
          return ExploreCreatorDetailPage(creatorUid: args?.creatorUid ?? '');
        },
      ),

      GoRoute(
        name: 'mealPlan',
        path: mealPlan,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is MealPlanArgs ? extra : null;
          return MealPlanPage(
            initialTabIndex: args?.initialTabIndex ?? 0,
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      GoRoute(
        name: 'addMealPlan',
        path: addMealPlan,
        builder: (context, state) {
          final args = state.extra as AddMealPlanArgs?;
          return AddMealPlanPage(
            mealType: args?.mealType ?? 'Breakfast',
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      GoRoute(
        name: 'generateAiMeal',
        path: generateAiMeal,
        builder: (context, state) {
          final args = state.extra as GenerateAiMealArgs?;
          return GenerateAiMealPage(
            mealType: args?.mealType ?? 'Breakfast',
            userId:
                args?.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      ),

      GoRoute(
        name: 'addGroceryList',
        path: addGroceryList,
        builder: (context, state) => const AddGroceryListPage(),
      ),

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

      GoRoute(
        name: 'library',
        path: library,
        builder: (context, state) => const LibraryPage(),
      ),

      GoRoute(
        name: 'statistics',
        path: statistics,
        builder: (context, state) {
          final args = state.extra as StatisticsArgs?;
          return StatisticsPage(isAdmin: args?.isAdmin ?? false);
        },
      ),

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
