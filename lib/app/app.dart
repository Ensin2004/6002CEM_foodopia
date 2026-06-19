// Configures the app application module.

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/domain/entities/user_entity.dart';
import 'routers/app_router.dart';

/// Defines behavior for app.
/// The root widget of the application.
class App extends StatelessWidget {
  /// Whether the user has seen the onboarding flow.
  final bool seenOnboarding;

  /// Whether the user is logged in.
  final bool isLoggedIn;

  /// The authenticated user entity.
  final UserEntity? userEntity;

  /// Creates a app instance.
  const App({
    super.key,
    required this.seenOnboarding,
    required this.isLoggedIn,
    required this.userEntity,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Foodopia',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(
        seenOnboarding: seenOnboarding,
        isLoggedIn: isLoggedIn,
        user: userEntity,
      ),
    );
  }
}