import 'package:firebase_core/firebase_core.dart';

class FirebaseConfigChecker {
  static Future<bool> isFirebaseConfigured() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> checkAndInitialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      print('Make sure google-services.json is in android/app/');
    }
  }
}