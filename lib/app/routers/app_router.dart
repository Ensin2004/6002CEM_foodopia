import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/main/presentation/view/main_page.dart';
import '../../features/notifications/presentation/view/notifications_page.dart';
import '../../features/recipe/presentation/view/add_recipe_page.dart';
import '../../features/settings/presentation/view/settings_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_editor_page.dart';
import '../../features/settings/presentation/view/subfeatures/about/about_viewer_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/change_password_page.dart';
import '../../features/settings/presentation/view/subfeatures/account/edit_profile_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/admin_help_center_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/faq_form_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/issue_detail_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/rate_us_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_faq_page.dart';
import '../../features/settings/presentation/view/subfeatures/support/user_help_center_page.dart';
import 'router_args.dart';

/// Defines behavior for app router.
class AppRouter {
  // Route names
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String changePassword = '/settings/change-password';
  static const String about = '/about';
  static const String faq = '/faq';
  static const String rateUs = '/rate-us';
  static const String helpCenter = '/help-center';
  static const String notifications = '/notifications';
  static const String addRecipe = '/recipes/add';
  static const String issueDetail = '/help-center/issue';
  static const String faqForm = '/faq/form';
  static const String imagePreview = '/image-preview';

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
      /// Creates a go route instance.
      GoRoute(
        name: 'home',
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
          return args?.isAdmin == true ? const AdminFaqPage() : const UserFaqPage();
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
            appBar: AppBar(),
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
