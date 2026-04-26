// ============================================================================
// WIDGET TESTS FOR FOODOPIA APP
// ============================================================================
//
// HOW TO RUN TESTS:
// flutter test test/widget_test.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodopia/app/app.dart';
import 'package:foodopia/features/onboarding/presentation/view/onboarding_screen.dart';
import 'package:foodopia/features/auth/presentation/view/login_screen.dart';

void main() {
  // Setup for tests
  setUpAll(() async {
    // Initialize WidgetsBinding
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Mock Firebase (optional - for tests that need Firebase)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  });

  group('App Navigation Tests', () {
    testWidgets('App shows Onboarding when onboarding not seen and not logged in',
            (WidgetTester tester) async {
          // Build app with onboarding not seen, not logged in, no user
          await tester.pumpWidget(const App(
            seenOnboarding: false,
            isLoggedIn: false,
            userEntity: null,  // ✅ Added required parameter
          ));

          // Verify Onboarding screen is shown
          expect(find.byType(OnboardingScreen), findsOneWidget);
          expect(find.byType(LoginScreen), findsNothing);
        });

    testWidgets('App shows Login when onboarding seen and not logged in',
            (WidgetTester tester) async {
          // Build app with onboarding seen, not logged in
          await tester.pumpWidget(const App(
            seenOnboarding: true,
            isLoggedIn: false,
            userEntity: null,  // ✅ Added required parameter
          ));

          // Verify Login screen is shown
          expect(find.byType(LoginScreen), findsOneWidget);
          expect(find.byType(OnboardingScreen), findsNothing);
        });
  });

  group('Onboarding Screen Tests', () {
    testWidgets('Onboarding screen displays title',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: OnboardingScreen(),
            ),
          );

          // Verify app title is displayed
          expect(find.text('Foodopia'), findsOneWidget);
        });

    testWidgets('Onboarding has skip button',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: OnboardingScreen(),
            ),
          );

          // Verify skip button exists
          expect(find.text('Skip'), findsOneWidget);
        });

    testWidgets('Onboarding has NEXT/GET STARTED button',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: OnboardingScreen(),
            ),
          );

          // Verify button exists (initially shows NEXT, not GET STARTED)
          expect(find.text('NEXT'), findsOneWidget);
        });
  });

  group('Login Screen Tests', () {
    testWidgets('Login screen displays email and password fields',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          // Verify form fields exist
          expect(find.byType(TextField), findsAtLeast(2));
          expect(find.text('Welcome Back'), findsOneWidget);
        });

    testWidgets('Login button is present',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          // Verify login button exists
          expect(find.text('Login'), findsOneWidget);
        });

    testWidgets('Sign Up link is present',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          // Verify sign up link exists
          expect(find.text('Sign Up'), findsOneWidget);
        });
  });
}