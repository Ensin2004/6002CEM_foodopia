import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/app.dart';
import 'core/utils/shared_prefs_manager.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/domain/entities/user_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
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
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  final isLoggedIn = currentUser != null && currentUser.emailVerified && userEntity != null;

  // Debug prints
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔍 APP STARTUP DEBUG INFO:');
  print('📱 seenOnboarding: $seenOnboarding');
  print('👤 currentUser: ${currentUser?.email ?? "null"}');
  print('✅ isLoggedIn: $isLoggedIn');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  runApp(App(
    seenOnboarding: seenOnboarding,
    isLoggedIn: isLoggedIn,
    userEntity: userEntity,
  ));
}