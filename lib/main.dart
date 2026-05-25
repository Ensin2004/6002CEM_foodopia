import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app/dependency_injection/injection_container.dart';
import 'app/app.dart';
import 'core/services/fcm_notification_service.dart';
import 'core/services/shared_prefs_manager.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/domain/entities/user_entity.dart';

/// Handles the main operation.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Pass all uncaught Flutter framework errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, stack) {
    print('❌ Error initializing Firebase: $e');
    // Only record this if Firebase initialized enough for Crashlytics to work.
    // If Firebase failed completely, this may also fail, so keep it guarded.
    try {
      await FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
    } catch (_) {}
  }

  // Initialize dependencies
  await initDependencies();

  // Initialize SharedPreferences Manager
  await SharedPrefsManager.init();

  // Check onboarding status using the manager
  final seenOnboarding = SharedPrefsManager.hasCompletedOnboarding();

  final currentUser = FirebaseAuth.instance.currentUser;
  UserEntity? userEntity;

  if (currentUser != null && currentUser.emailVerified) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      userEntity = UserModel.fromFirebase(currentUser, userDoc);
    } catch (e, stack) {
      print('Error fetching user data: $e');

      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error fetching user data during app startup',
        fatal: false,
      );
    }
  }

  final isLoggedIn =
      currentUser != null && currentUser.emailVerified && userEntity != null;

  if (isLoggedIn) {
    await FcmNotificationService.initialize();
  }

  // Debug prints
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔍 APP STARTUP DEBUG INFO:');
  print('📱 seenOnboarding: $seenOnboarding');
  print('👤 currentUser: ${currentUser?.email ?? "null"}');
  print('✅ isLoggedIn: $isLoggedIn');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  /// Creates a run app instance.
  runApp(
    App(
      seenOnboarding: seenOnboarding,
      isLoggedIn: isLoggedIn,
      userEntity: userEntity,
    ),
  );
}
