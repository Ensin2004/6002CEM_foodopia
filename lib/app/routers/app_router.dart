import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/main/presentation/view/main_page.dart';
import 'router_args.dart';

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

  /// Create router with app state (no direct Firebase dependency!)
  static GoRouter createRouter({
    required bool seenOnboarding,
    required bool isLoggedIn,
    required UserEntity? user,
  }) {
    return GoRouter(
      initialLocation: _getInitialLocation(seenOnboarding, isLoggedIn),
      redirect: (context, state) {
        return _handleRedirect(
          state: state,
          seenOnboarding: seenOnboarding,
          isLoggedIn: isLoggedIn,
        );
      },
      routes: _buildRoutes(user), // ✅ Pass user to routes
    );
  }

  static String _getInitialLocation(bool seenOnboarding, bool isLoggedIn) {
    if (!seenOnboarding) return onboarding;
    if (!isLoggedIn) return login;
    return home;
  }

  static String? _handleRedirect({
    required GoRouterState state,
    required bool seenOnboarding,
    required bool isLoggedIn,
  }) {
    final location = state.matchedLocation;
    final isAuthPage = location == login || location == signup;
    final isOnboarding = location == onboarding;

    // Not seen onboarding → force onboarding
    if (!seenOnboarding && !isOnboarding) {
      return onboarding;
    }

    // Not logged in → force login
    if (!isLoggedIn && !isAuthPage && !isOnboarding) {
      return login;
    }

    // Logged in → prevent auth pages
    if (isLoggedIn && (isAuthPage || isOnboarding)) {
      return home;
    }

    return null;
  }

  static List<GoRoute> _buildRoutes(UserEntity? user) {
    return [
      GoRoute(
        name: 'onboarding',
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'login',
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'signup',
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        name: 'home',
        path: home,
        builder: (context, state) {
          final args = state.extra as HomeArgs?;
          // ✅ Handle null user gracefully
          final userEntity = args?.user ?? user;
          if (userEntity == null) {
            // If no user, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(login);
            });
            return const SizedBox.shrink();
          }
          return MainPage(user: userEntity, role: args?.role ?? 'user');
        },
      ),
    ];
  }
}