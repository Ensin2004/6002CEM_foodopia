// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../core/theme/app_theme.dart';
// import '../features/auth/presentation/view/login_screen.dart';
// import '../features/onboarding/presentation/view/onboarding_screen.dart';
// import '../features/main/presentation/view/main_page.dart';
// import '../features/auth/domain/entities/user_entity.dart';
// import '../core/utils/role_manager.dart';
//
// class App extends StatelessWidget {
//   final bool seenOnboarding;
//   final bool isLoggedIn;
//   final UserEntity? userEntity; // Add this
//
//   const App({
//     super.key,
//     required this.seenOnboarding,
//     required this.isLoggedIn,
//     required this.userEntity, // Add this
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Foodopia',
//       theme: AppTheme.lightTheme,
//       home: _getInitialScreen(),
//     );
//   }
//
//   Widget _getInitialScreen() {
//     // Priority 1: If user is logged in and email verified, go to MainPage
//     if (isLoggedIn && userEntity != null) {
//       return MainPage(user: userEntity!, role: userEntity!.role.name);
//     }
//
//     // Priority 2: If onboarding not seen, show onboarding
//     if (!seenOnboarding) {
//       return const OnboardingScreen();
//     }
//
//     // Priority 3: Otherwise show login screen
//     return const LoginScreen();
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'routers/app_router.dart';
import '../features/auth/domain/entities/user_entity.dart';

class App extends StatelessWidget {
  final bool seenOnboarding;
  final bool isLoggedIn;
  final UserEntity? userEntity;

  const App({
    super.key,
    required this.seenOnboarding,
    required this.isLoggedIn,
    required this.userEntity,
  });

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