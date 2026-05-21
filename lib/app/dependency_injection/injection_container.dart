// Configures the injection container application module.
// DEPENDENCY INJECTION CONTAINER
// ============================================================================
// This file manages all dependencies for the app using GetIt.
//
// WHAT IS DEPENDENCY INJECTION?
// - A central "warehouse" that stores all the tools (classes) the app needs
// - Any part of the app can request a tool from this warehouse
// - Makes testing easier and code more maintainable
//
// HOW TO USE:
// 1. To get a dependency: final myClass = sl<MyClassName>();
// 2. To add a new dependency: register it in the appropriate section below
//
// TYPES OF REGISTRATION:
// - registerLazySingleton: One instance created when first requested (shared globally)
// - registerFactory: New instance created every time it's requested
// - registerSingleton: One instance created immediately (rarely used)
// ============================================================================

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// DATA LAYER IMPORTS
// ============================================================================
// Core
import '../../core/services/network_info.dart';
import '../../core/services/food_search_service.dart';
import '../../core/services/open_meteo_weather_service.dart';

// Auth Feature - Data Layer
import '../../features/admin_home/data/datasources/admin_home_mock_datasource.dart';
import '../../features/admin_home/data/repositories/admin_home_repository_impl.dart';
import '../../features/admin_manage/data/datasources/admin_manage_remote_datasource.dart';
import '../../features/admin_manage/data/repositories/admin_manage_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/explore/data/datasources/explore_remote_datasource.dart';
import '../../features/explore/data/repositories/explore_repository_impl.dart';
import '../../features/explore/domain/repositories/explore_repository.dart';
import '../../features/explore/domain/usecases/add_recipe_comment_usecase.dart';
import '../../features/explore/domain/usecases/add_recipe_comment_reply_usecase.dart';
import '../../features/explore/domain/usecases/add_recipe_reply_to_reply_usecase.dart';
import '../../features/explore/domain/usecases/get_explore_recipe_detail_usecase.dart';
import '../../features/explore/domain/usecases/get_explore_creator_detail_usecase.dart';
import '../../features/explore/domain/usecases/get_explore_recipes_usecase.dart';
import '../../features/explore/domain/usecases/increment_recipe_view_count_usecase.dart';
import '../../features/explore/domain/usecases/submit_recipe_rating_usecase.dart';
import '../../features/explore/domain/usecases/toggle_recipe_comment_like_usecase.dart';
import '../../features/explore/domain/usecases/toggle_recipe_reply_like_usecase.dart';
import '../../features/explore/domain/usecases/toggle_creator_follow_usecase.dart';
import '../../features/explore/domain/usecases/watch_explore_recipes_usecase.dart';
import '../../features/explore/domain/usecases/watch_explore_recipe_detail_usecase.dart';
import '../../features/meal_plan/data/datasources/meal_plan_mock_datasource.dart';
import '../../features/meal_plan/data/datasources/meal_plan_preferences_datasource.dart';
import '../../features/meal_plan/data/datasources/meal_plan_weather_datasource.dart';
import '../../features/meal_plan/data/repositories/meal_plan_repository_impl.dart';
import '../../features/meal_plan/domain/repositories/meal_plan_repository.dart';
import '../../features/meal_plan/domain/usecases/get_add_grocery_list_plan_usecase.dart';
import '../../features/meal_plan/domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../features/meal_plan/domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../features/meal_plan/domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../features/meal_plan/domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../features/meal_plan/domain/usecases/get_meal_plan_weather_usecase.dart';
import '../../features/recipe/data/datasources/add_recipe_remote_datasource.dart';
import '../../features/recipe/data/repositories/add_recipe_repository_impl.dart';
import '../../features/recipe/domain/repositories/add_recipe_repository.dart';
import '../../features/recipe/domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../features/recipe/domain/usecases/get_add_recipe_food_nutrients_usecase.dart';
import '../../features/recipe/domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../features/recipe/domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../features/recipe/domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../features/recipe/domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../../features/recipe/domain/usecases/search_add_recipe_foods_usecase.dart';
import '../../features/statistics/data/datasources/statistics_mock_datasource.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_statistics_dashboard_usecase.dart';
import '../../features/user_home/data/datasources/user_home_mock_datasource.dart';
import '../../features/user_home/data/datasources/user_home_weather_datasource.dart';
import '../../features/user_home/data/repositories/user_home_repository_impl.dart';
import '../../features/user_home/domain/repositories/user_home_repository.dart';
import '../../features/user_home/domain/usecases/get_user_home_dashboard_usecase.dart';
import '../../features/user_home/domain/usecases/get_user_home_weather_usecase.dart';
import '../../features/user_setup/data/datasources/user_setup_remote_datasource.dart';
import '../../features/user_setup/data/repositories/user_setup_repository_impl.dart';

// Main Feature - Data Layer
import '../../features/main/data/datasources/main_remote_datasource.dart';
import '../../features/main/data/repositories/main_repository_impl.dart';

// Settings Feature - Data Layer
import '../../features/settings/data/datasources/faq_remote_datasource.dart';
import '../../features/settings/data/datasources/help_center_remote_datasource.dart';
import '../../features/settings/data/datasources/rating_remote_datasource.dart';
import '../../features/settings/data/repositories/faq_repository_impl.dart';
import '../../features/settings/data/repositories/help_center_repository_impl.dart';
import '../../features/settings/data/repositories/rating_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';

// Profile Feature - Data Layer
import '../../features/settings/data/datasources/profile_remote_datasource.dart';
import '../../features/settings/data/repositories/profile_repository_impl.dart';

// Password Feature - Data Layer
import '../../features/settings/data/datasources/password_remote_datasource.dart';
import '../../features/settings/data/repositories/password_repository_impl.dart';

// About Feature - Data Layer
import '../../features/settings/data/datasources/about_remote_datasource.dart';
import '../../features/settings/data/repositories/about_repository_impl.dart';

// ============================================================================
// DOMAIN LAYER IMPORTS
// ============================================================================
// Auth Feature - Domain Layer
import '../../features/admin_home/domain/repositories/admin_home_repository.dart';
import '../../features/admin_home/domain/usecases/get_admin_home_dashboard_usecase.dart';
import '../../features/admin_manage/domain/repositories/admin_manage_repository.dart';
import '../../features/admin_manage/domain/usecases/delete_admin_manage_item_usecase.dart';
import '../../features/admin_manage/domain/usecases/get_admin_manage_items_usecase.dart';
import '../../features/admin_manage/domain/usecases/reorder_admin_manage_items_usecase.dart';
import '../../features/admin_manage/domain/usecases/save_admin_manage_item_usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/auth/domain/usecases/get_age_groups_usecase.dart';
import '../../features/auth/domain/usecases/verify_email_usecase.dart';
import '../../features/user_setup/domain/repositories/user_setup_repository.dart';
import '../../features/user_setup/domain/usecases/get_user_setup_options_usecase.dart';
import '../../features/user_setup/domain/usecases/get_user_setup_preferences_usecase.dart';
import '../../features/user_setup/domain/usecases/get_user_setup_status_usecase.dart';
import '../../features/user_setup/domain/usecases/save_user_setup_preferences_usecase.dart';
import '../../features/user_setup/domain/usecases/search_user_setup_foods_usecase.dart';

// Main Feature - Domain Layer
import '../../features/main/domain/repositories/main_repository.dart';

// Settings Feature - Domain Layer
import '../../features/settings/domain/repositories/faq_repository.dart';
import '../../features/settings/domain/repositories/help_center_repository.dart';
import '../../features/settings/domain/repositories/rating_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

// Profile Feature - Domain Layer
import '../../features/settings/domain/repositories/profile_repository.dart';
import '../../features/settings/domain/usecases/about/save_about_content_usecase.dart';
import '../../features/settings/domain/usecases/account/get_user_email_usecase.dart';
import '../../features/settings/domain/usecases/account/get_user_profile_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/add_faq_item_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/delete_faq_item_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/update_faq_item_usecase.dart';
import '../../features/settings/domain/usecases/support/help_center/get_admin_issues_usecase.dart';
import '../../features/settings/domain/usecases/support/help_center/get_user_issues_usecase.dart';
import '../../features/settings/domain/usecases/support/help_center/submit_issue_usecase.dart';
import '../../features/settings/domain/usecases/support/help_center/update_issue_status_usecase.dart';
import '../../features/settings/domain/usecases/support/help_center/upload_issue_image_usecase.dart';
import '../../features/settings/domain/usecases/support/rating/delete_rating_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/get_admin_faq_items_usecase.dart';
import '../../features/settings/domain/usecases/support/rating/get_all_ratings_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/get_user_faq_items_usecase.dart';
import '../../features/settings/domain/usecases/support/rating/get_user_rating_usecase.dart';
import '../../features/settings/domain/usecases/support/rating/save_rating_usecase.dart';
import '../../features/settings/domain/usecases/support/faq/upload_faq_image_usecase.dart';
import '../../features/settings/domain/usecases/account/update_user_age_group_usecase.dart';
import '../../features/settings/domain/usecases/account/update_user_name_usecase.dart';
import '../../features/settings/domain/usecases/account/update_user_gender_usecase.dart';
import '../../features/settings/domain/usecases/account/update_profile_image_usecase.dart';

// Password Feature - Domain Layer
import '../../features/settings/domain/repositories/password_repository.dart';
import '../../features/settings/domain/usecases/account/change_password_usecase.dart';

// About Feature - Domain Layer
import '../../features/settings/domain/repositories/about_repository.dart';
import '../../features/settings/domain/usecases/about/get_about_content_usecase.dart';

// ============================================================================
// PRESENTATION LAYER IMPORTS
// ============================================================================
// Auth Feature - Presentation Layer
import '../../features/admin_manage/presentation/viewmodel/admin_manage_viewmodel.dart';
import '../../features/auth/presentation/viewmodel/login_viewmodel.dart';
import '../../features/auth/presentation/viewmodel/signup_viewmodel.dart';

// Onboarding Feature - Presentation Layer
import '../../features/onboarding/presentation/viewmodel/onboarding_viewmodel.dart';

// Main Feature - Presentation Layer
import '../../features/main/presentation/viewmodel/main_viewmodel.dart';
import '../../features/settings/domain/usecases/support/rating/upload_rating_image_usecase.dart';

final sl = GetIt.instance;

// ============================================================================
// INITIALIZATION
// ============================================================================
/// Call this function once when the app starts (in main.dart)
/// It registers all dependencies before the app runs
Future<void> initDependencies() async {
  // 1. Initialize external services (Firebase, SharedPreferences, etc.)
  await _initExternal();

  // 2. Initialize core utilities (Network, etc.)
  _initCore();

  // 3. Initialize feature-specific dependencies
  _initAuthFeature(); // Authentication feature
  _initOnboardingFeature(); // Onboarding feature
  _initMainFeature(); // Main feature
  _initSettingsFeature(); // Settings feature
  _initProfileFeature(); // Profile/Edit Profile feature
  _initPasswordFeature(); // Password/Change Password feature
  _initAboutFeature(); // About feature (About Us, Terms, Privacy)
  _initHelpCenterFeature();
  _initRatingFeature();
  _initFaqFeature();
  _initAdminManageFeature();
  _initAdminHomeFeature();
  _initUserHomeFeature();
  _initMealPlanFeature();
  _initUserSetupFeature();
  _initRecipeFeature();
  _initStatisticsFeature();
  _initExploreFeature();

  // Add new features here as the app grows
  // _initMealPlanFeature();
}

void _initRecipeFeature() {
  sl.registerLazySingleton(
    () => AddRecipeRemoteDataSource(
      firestore: sl(),
      auth: sl(),
      foodSearchService: sl(),
    ),
  );
  sl.registerLazySingleton<AddRecipeRepository>(
    () => AddRecipeRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAddRecipeSetupUseCase(sl()));
  sl.registerLazySingleton(() => GetAddRecipeIngredientUnitsUseCase(sl()));
  sl.registerLazySingleton(() => SearchAddRecipeFoodsUseCase(sl()));
  sl.registerLazySingleton(() => GetAddRecipeFoodNutrientsUseCase(sl()));
  sl.registerLazySingleton(() => SaveAddRecipeBasicInfoUseCase(sl()));
  sl.registerLazySingleton(() => SaveAddRecipeIngredientsUseCase(sl()));
  sl.registerLazySingleton(() => SaveAddRecipeInstructionsUseCase(sl()));
}

void _initStatisticsFeature() {
  sl.registerLazySingleton(() => StatisticsMockDataSource());

  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(mockDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetStatisticsDashboardUseCase(sl()));
}

void _initExploreFeature() {
  sl.registerLazySingleton(
    () => ExploreRemoteDataSource(firestore: sl(), auth: sl()),
  );

  sl.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetExploreRecipesUseCase(sl()));
  sl.registerLazySingleton(() => GetExploreRecipeDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetExploreCreatorDetailUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRecipeRatingUseCase(sl()));
  sl.registerLazySingleton(() => AddRecipeCommentUseCase(sl()));
  sl.registerLazySingleton(() => IncrementRecipeViewCountUseCase(sl()));
  sl.registerLazySingleton(() => ToggleRecipeCommentLikeUseCase(sl()));
  sl.registerLazySingleton(() => AddRecipeCommentReplyUseCase(sl()));
  sl.registerLazySingleton(() => WatchExploreRecipesUseCase(sl()));
  sl.registerLazySingleton(() => WatchExploreRecipeDetailUseCase(sl()));
  sl.registerLazySingleton(() => ToggleRecipeReplyLikeUseCase(sl()));
  sl.registerLazySingleton(() => AddRecipeReplyToReplyUseCase(sl()));
  sl.registerLazySingleton(() => ToggleCreatorFollowUseCase(sl()));
}

void _initMealPlanFeature() {
  sl.registerLazySingleton(() => MealPlanMockDataSource());
  sl.registerLazySingleton(
    () => MealPlanPreferencesDataSource(firestore: sl()),
  );
  sl.registerLazySingleton(
    () => MealPlanWeatherDataSource(weatherService: sl()),
  );

  sl.registerLazySingleton<MealPlanRepository>(
    () => MealPlanRepositoryImpl(
      mockDataSource: sl(),
      weatherDataSource: sl(),
      preferencesDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetMealPlanDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetMealPlanWeatherUseCase(sl()));
  sl.registerLazySingleton(() => GetMealPlanPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => GetAddGroceryListPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetAddMealAiPlanUseCase(sl()));
  sl.registerLazySingleton(() => GetManageGroceryListDetailUseCase(sl()));
}

void _initUserSetupFeature() {
  sl.registerLazySingleton(
    () => UserSetupRemoteDataSource(firestore: sl(), foodSearchService: sl()),
  );

  sl.registerLazySingleton<UserSetupRepository>(
    () => UserSetupRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetUserSetupOptionsUseCase(sl()));
  sl.registerLazySingleton(() => SearchUserSetupFoodsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserSetupPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => SaveUserSetupPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => GetUserSetupStatusUseCase(sl()));
}

void _initUserHomeFeature() {
  sl.registerLazySingleton(() => UserHomeMockDataSource());
  sl.registerLazySingleton(
    () => UserHomeWeatherDataSource(weatherService: sl()),
  );

  sl.registerLazySingleton<UserHomeRepository>(
    () => UserHomeRepositoryImpl(mockDataSource: sl(), weatherDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetUserHomeDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetUserHomeWeatherUseCase(sl()));
}

void _initAdminHomeFeature() {
  sl.registerLazySingleton(() => AdminHomeMockDataSource());

  sl.registerLazySingleton<AdminHomeRepository>(
    () => AdminHomeRepositoryImpl(mockDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetAdminHomeDashboardUseCase(sl()));
}

void _initAdminManageFeature() {
  sl.registerLazySingleton(() => AdminManageRemoteDataSource(firestore: sl()));

  sl.registerLazySingleton<AdminManageRepository>(
    () => AdminManageRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetAdminManageItemsUseCase(sl()));
  sl.registerLazySingleton(() => SaveAdminManageItemUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAdminManageItemUseCase(sl()));
  sl.registerLazySingleton(() => ReorderAdminManageItemsUseCase(sl()));

  sl.registerFactory(
    () => AdminManageViewModel(
      getItemsUseCase: sl(),
      saveItemUseCase: sl(),
      deleteItemUseCase: sl(),
      reorderItemsUseCase: sl(),
    ),
  );
}

// ============================================================================
// EXTERNAL DEPENDENCIES
// ============================================================================
/// Registers external services and SDKs
/// These are typically provided by third-party packages
Future<void> _initExternal() async {
  // --------------------------------------------------------------------------
  // FIREBASE SERVICES
  // --------------------------------------------------------------------------
  // Used for: Authentication, Database, Push Notifications
  sl.registerLazySingleton(() => FirebaseAuth.instance); // User auth
  sl.registerLazySingleton(() => FirebaseFirestore.instance); // Cloud database
  sl.registerLazySingleton(
    () => FirebaseMessaging.instance,
  ); // Push notifications
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FoodSearchService(client: sl()));
  sl.registerLazySingleton(() => OpenMeteoWeatherService(client: sl()));

  // --------------------------------------------------------------------------
  // CONNECTIVITY
  // --------------------------------------------------------------------------
  // Used for: Checking internet connection status
  sl.registerLazySingleton(() => Connectivity());
}

// ============================================================================
// CORE DEPENDENCIES
// ============================================================================
/// Registers core utilities used across multiple features
void _initCore() {
  // --------------------------------------------------------------------------
  // NETWORK INFO
  // --------------------------------------------------------------------------
  // Used for: Checking if device has internet connection
  // Dependencies: Connectivity
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
}

// ============================================================================
// AUTHENTICATION FEATURE
// ============================================================================
/// Registers all dependencies for the Authentication feature
///
/// LAYER STRUCTURE:
/// Presentation → Domain → Data → External
///
/// DEPENDENCY FLOW:
/// LoginScreen → LoginViewModel → LoginUseCase → AuthRepository → AuthRemoteDataSource → Firebase
void _initAuthFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Making actual API calls to Firebase
  // Depends on: Firebase services
  sl.registerLazySingleton(
    () => AuthRemoteDataSource(auth: sl(), firestore: sl(), fcm: sl()),
  );

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Converting data between domain and data sources
  // Implements: AuthRepository interface
  // Depends on: AuthRemoteDataSource
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. USE CASES (Business Logic Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Implementing specific business rules
  // Each use case does ONE thing (Single Responsibility Principle)
  // Depends on: AuthRepository

  // Login - Handles user login logic
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Signup - Handles user registration logic
  sl.registerLazySingleton(() => SignupUseCase(sl()));

  // Get Age Groups - Fetches configurable age groups from Firestore
  sl.registerLazySingleton(() => GetAgeGroupsUseCase(sl()));

  // Verify Email - Checks if user's email is verified
  sl.registerLazySingleton(() => VerifyEmailUseCase(sl()));

  // --------------------------------------------------------------------------
  // 4. VIEWMODELS (UI State Management Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Managing UI state and coordinating use cases
  // Uses registerFactory (new instance per screen) NOT registerLazySingleton
  // Reason: Each screen needs its own fresh ViewModel instance
  // Depends on: Use Cases and Repositories

  // Login ViewModel - Manages login screen state
  sl.registerFactory(
    () => LoginViewModel(loginUseCase: sl(), authRepository: sl()),
  );

  // Signup ViewModel - Manages signup screen state
  sl.registerFactory(
    () => SignupViewModel(
      signupUseCase: sl(),
      getAgeGroupsUseCase: sl(),
      authRepository: sl(),
    ),
  );
}

// ============================================================================
// ONBOARDING FEATURE
// ============================================================================
/// Registers all dependencies for the Onboarding feature
///
/// Note: Onboarding is a simpler feature (Presentation-only)
/// It doesn't have Domain/Data layers because:
/// 1. No API calls needed
/// 2. Only uses local storage (SharedPreferences)
/// 3. Simple business logic
///
/// For complex features, add all three layers (Domain, Data, Presentation)
void _initOnboardingFeature() {
  // --------------------------------------------------------------------------
  // VIEWMODELS (UI State Management Layer)
  // --------------------------------------------------------------------------
  // Onboarding ViewModel - Manages onboarding screen state
  // Uses registerFactory (new instance per screen)
  sl.registerFactory(() => OnboardingViewModel());
}

// ============================================================================
// MAIN FEATURE
// ============================================================================
/// Registers all dependencies for the Main feature
///
/// This feature handles the main app shell (app bar, bottom nav, user profile)
void _initMainFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Making Firestore calls for user profile data
  sl.registerLazySingleton(() => MainRemoteDataSource(firestore: sl()));

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Converting data between domain and data sources
  // Implements: MainRepository interface
  sl.registerLazySingleton<MainRepository>(
    () => MainRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. VIEWMODELS (UI State Management Layer)
  // --------------------------------------------------------------------------
  // Main ViewModel - Manages main page state (tab index, profile image, etc.)
  // Uses registerFactory because each main page needs its own instance
  // Note: user parameter will be passed from the screen, not from DI
  sl.registerFactory(
    () => MainViewModel(
      user: sl(), // This will be overridden when creating
      repository: sl(),
    ),
  );
}

// ============================================================================
// SETTINGS FEATURE
// ============================================================================
/// Registers all dependencies for the Settings feature
///
/// This feature handles user/admin settings, preferences, and notifications
void _initSettingsFeature() {
  // --------------------------------------------------------------------------
  // 1. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Implements: SettingsRepository interface
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());

  // --------------------------------------------------------------------------
  // NOTE: SettingsViewModel is NOT registered here because:
  // - It requires a UserEntity parameter that changes per user
  // - It is created directly in the SettingsPage with the user parameter
  // - This follows the rule: Don't register dependencies that have runtime parameters
  // --------------------------------------------------------------------------
}

// ============================================================================
// PROFILE FEATURE (Edit Profile)
// ============================================================================
/// Registers all dependencies for the Profile/Edit Profile feature
///
/// This feature handles:
/// - Fetching user profile data
/// - Updating user name, gender, and profile picture
/// - Cloudinary image upload for profile pictures
void _initProfileFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Making Firestore and Firebase Auth calls for profile data
  // Also handles Cloudinary image upload
  sl.registerLazySingleton(
    () => ProfileRemoteDataSource(firestore: sl(), auth: sl()),
  );

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Converting data between domain and data sources
  // Implements: ProfileRepository interface
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. USE CASES (Business Logic Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Implementing specific business rules
  // Each use case does ONE thing (Single Responsibility Principle)
  // Depends on: ProfileRepository

  // Get User Profile - Fetches user profile data
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));

  // Update User Name - Updates user's display name
  sl.registerLazySingleton(() => UpdateUserNameUseCase(sl()));

  // Update User Gender - Updates user's gender
  sl.registerLazySingleton(() => UpdateUserGenderUseCase(sl()));

  // Update User Age Group - Updates user's selected age group
  sl.registerLazySingleton(() => UpdateUserAgeGroupUseCase(sl()));

  // Update Profile Image - Uploads and updates profile picture
  sl.registerLazySingleton(() => UpdateProfileImageUseCase(sl()));

  // --------------------------------------------------------------------------
  // NOTE: EditProfileViewModel is NOT registered here because:
  // - It requires a uid parameter that changes per user
  // - It is created directly in the EditProfilePage with the uid parameter
  // - This follows the rule: Don't register dependencies that have runtime parameters
  // --------------------------------------------------------------------------
}

// ============================================================================
// PASSWORD FEATURE (Change Password)
// ============================================================================
/// Registers all dependencies for the Change Password feature
///
/// This feature handles:
/// - Re-authenticating user with current password
/// - Updating password in Firebase Auth
/// - Password strength validation
void _initPasswordFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Making Firebase Auth calls for password changes
  // Handles re-authentication and password update
  sl.registerLazySingleton(() => PasswordRemoteDataSource(auth: sl()));

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Converting data between domain and data sources
  // Implements: PasswordRepository interface
  sl.registerLazySingleton<PasswordRepository>(
    () => PasswordRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. USE CASES (Business Logic Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Implementing specific business rules
  // Each use case does ONE thing (Single Responsibility Principle)
  // Depends on: PasswordRepository

  // Change Password - Handles password change logic with validation
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));

  // --------------------------------------------------------------------------
  // NOTE: ChangePasswordViewModel is NOT registered here because:
  // - It uses ChangePasswordUseCase which is registered above
  // - It is created directly in the ChangePasswordPage
  // - This follows the rule: ViewModels are created per screen, not as singletons
  // --------------------------------------------------------------------------
}

// ============================================================================
// ABOUT FEATURE (About Us, Terms, Privacy)
// ============================================================================
/// Registers all dependencies for the About feature
///
/// This feature handles:
/// - Fetching about content (About Us, Terms & Conditions, Privacy Policy)
/// - Saving/Updating about content (Admin only) - creates document if not exists
/// - Reading about content (User view)
void _initAboutFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Making Firestore calls for about content
  sl.registerLazySingleton(() => AboutRemoteDataSource(firestore: sl()));

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Converting data between domain and data sources
  // Implements: AboutRepository interface
  sl.registerLazySingleton<AboutRepository>(
    () => AboutRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. USE CASES (Business Logic Layer)
  // --------------------------------------------------------------------------
  // Responsible for: Implementing specific business rules
  // Each use case does ONE thing (Single Responsibility Principle)
  // Depends on: AboutRepository

  // Get About Content - Fetches about content from Firestore
  sl.registerLazySingleton(() => GetAboutContentUseCase(sl()));

  // Save About Content - Saves/Updates about content in Firestore (creates if not exists)
  sl.registerLazySingleton(
    () => SaveAboutContentUseCase(sl()),
  ); // Changed from Update to Save

  // --------------------------------------------------------------------------
  // NOTE: AboutViewerViewModel and AboutEditorViewModel are NOT registered here because:
  // - Requires documentId and title parameters that change per page
  // - Created directly in the AboutViewerPage and AboutEditorPage
  // - This follows the rule: Don't register dependencies that have runtime parameters
  // --------------------------------------------------------------------------
}

// ============================================================================
// HELP CENTER FEATURE
// ============================================================================
/// Registers all dependencies for the Help Center feature
///
/// This feature handles:
/// - Users submitting support issues
/// - Admins viewing and replying to issues
/// - Image uploads for issues
void _initHelpCenterFeature() {
  // --------------------------------------------------------------------------
  // 1. DATA SOURCES (External Communication Layer)
  // --------------------------------------------------------------------------
  sl.registerLazySingleton(() => HelpCenterRemoteDataSource(firestore: sl()));

  // --------------------------------------------------------------------------
  // 2. REPOSITORIES (Data Abstraction Layer)
  // --------------------------------------------------------------------------
  sl.registerLazySingleton<HelpCenterRepository>(
    () => HelpCenterRepositoryImpl(remoteDataSource: sl()),
  );

  // --------------------------------------------------------------------------
  // 3. USE CASES (Business Logic Layer)
  // --------------------------------------------------------------------------
  sl.registerLazySingleton(() => GetUserIssuesUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminIssuesUseCase(sl()));
  sl.registerLazySingleton(() => SubmitIssueUseCase(sl()));
  sl.registerLazySingleton(() => UpdateIssueStatusUseCase(sl()));
  sl.registerLazySingleton(() => UploadIssueImageUseCase(sl()));
  sl.registerLazySingleton(() => GetUserEmailUseCase(sl()));
}

/// Handles the init rating feature operation.
void _initRatingFeature() {
  // Data Source
  sl.registerLazySingleton(() => RatingRemoteDataSource(firestore: sl()));

  // Repository
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetUserRatingUseCase(sl()));
  sl.registerLazySingleton(() => GetAllRatingsUseCase(sl()));
  sl.registerLazySingleton(() => SaveRatingUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRatingUseCase(sl()));
  sl.registerLazySingleton(() => UploadRatingImageUseCase(sl()));
}

/// Handles the init faq feature operation.
void _initFaqFeature() {
  // Data Source
  sl.registerLazySingleton(() => FaqRemoteDataSource(firestore: sl()));

  // Repository
  sl.registerLazySingleton<FaqRepository>(
    () => FaqRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetUserFaqItemsUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminFaqItemsUseCase(sl()));
  sl.registerLazySingleton(() => AddFaqItemUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFaqItemUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFaqItemUseCase(sl()));
  sl.registerLazySingleton(() => UploadFaqImageUseCase(sl()));
}

// ============================================================================
// FUTURE FEATURES - TEMPLATES
// ============================================================================
/// When adding new features, follow these templates:

/*
// ============================================================================
// RECIPE FEATURE (Example of full Clean Architecture)
// ============================================================================
void _initRecipeFeature() {
  // -------------------- DATA LAYER --------------------
  // Data Sources
  sl.registerLazySingleton(() => RecipeRemoteDataSource(
    firestore: sl(),
  ));

  // Repositories
  sl.registerLazySingleton<RecipeRepository>(() => RecipeRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ));

  // -------------------- DOMAIN LAYER --------------------
  // Use Cases
  sl.registerLazySingleton(() => GetRecipesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecipeDetailsUseCase(sl()));
  sl.registerLazySingleton(() => SaveRecipeUseCase(sl()));

  // -------------------- PRESENTATION LAYER --------------------
  // ViewModels
  sl.registerFactory(() => RecipeListViewModel(
    getRecipesUseCase: sl(),
  ));
  sl.registerFactory(() => RecipeDetailViewModel(
    getRecipeDetailsUseCase: sl(),
    saveRecipeUseCase: sl(),
  ));
}

// ============================================================================
// SIMPLE FEATURE (Presentation-only, like Onboarding)
// ============================================================================
void _initSimpleFeature() {
  // ViewModels only
  sl.registerFactory(() => SimpleViewModel());
}
*/

// ============================================================================
// HELPER FUNCTIONS FOR TEAM MEMBERS
// ============================================================================

/// Use this in the screens to get ViewModels:
/// Example: final viewModel = sl<LoginViewModel>();
///
/// TYPES OF REGISTRATION TO USE:
///
/// 1. For ViewModels (always use registerFactory):
///    sl.registerFactory(() => MyViewModel(...));
///    Reason: Each screen needs a fresh instance
///
/// 2. For Use Cases (always use registerLazySingleton):
///    sl.registerLazySingleton(() => MyUseCase(sl()));
///    Reason: Use cases have no state, can be shared
///
/// 3. For Repositories (always use registerLazySingleton):
///    sl.registerLazySingleton<MyRepository>(() => MyRepositoryImpl(...));
///    Reason: Repositories are stateless, can be shared
///
/// 4. For Data Sources (always use registerLazySingleton):
///    sl.registerLazySingleton(() => MyDataSource(...));
///    Reason: Data sources are stateless, can be shared
///
/// HOW TO ADD A NEW DEPENDENCY:
/// 1. Import the class at the top of this file
/// 2. Find the appropriate feature section or create a new one
/// 3. Register using the correct type (factory vs lazySingleton)
/// 4. Pass any dependencies using sl<DependencyClass>()
///
/// EXAMPLE:
/// // Adding a new use case for recipe search
/// sl.registerLazySingleton(() => SearchRecipesUseCase(
///   recipeRepository: sl(),  // Get existing dependency
/// ));
