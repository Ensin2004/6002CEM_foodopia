// Configures the app application module.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/domain/entities/user_entity.dart';
import 'routers/app_router.dart';

/// Defines behavior for app.
class App extends StatelessWidget {
  final bool seenOnboarding;
  final bool isLoggedIn;
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
