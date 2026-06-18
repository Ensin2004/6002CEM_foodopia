// Implements repository operations for auth.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/auth/role_manager.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Defines behavior for auth repository impl.
/// Implements the AuthRepository interface using remote data source.
class AuthRepositoryImpl implements AuthRepository {
  /// Remote data source for authentication operations.
  final AuthRemoteDataSource remoteDataSource;

  /// Creates a auth repository impl instance.
  AuthRepositoryImpl({required this.remoteDataSource});

  /// Runs the login operation.
  @override
  Future<Either<AuthFailure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      final credential = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Get the authenticated user.
      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure(message: 'Login failed'));
      }

      // Fetch user data from Firestore.
      final userDoc = await remoteDataSource.getUserFromFirestore(user.uid);

      // Ensure notification preferences exist.
      await remoteDataSource.ensureNotificationPreferences(user.uid);

      // Save FCM token.
      await remoteDataSource.saveFcmToken(user.uid);

      // Initialize FCM notification service.
      await FcmNotificationService.initialize();

      // Create user entity.
      final userEntity = UserModel.fromFirebase(user, userDoc);

      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors.
      String message;

      // Map error codes to user-friendly messages.
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password provided';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This user has been disabled';
          break;
        default:
          message = e.message ?? 'Login failed';
      }

      return Left(AuthFailure(message: message, code: e.code));
    } catch (e) {
      // Map any other exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Runs the signup operation.
  @override
  Future<Either<AuthFailure, UserEntity>> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      final credential = await remoteDataSource.signup(
        email: email,
        password: password,
      );

      // Get the authenticated user.
      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure(message: 'Signup failed'));
      }

      // Get FCM token.
      final fcmToken = await remoteDataSource.getFCMToken();

      // Split name into first and last name.
      final nameParts = name.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : name.trim();
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Save user data to Firestore.
      await remoteDataSource.saveUserToFirestore(
        uid: user.uid,
        userData: {
          'firstName': firstName,
          'lastName': lastName,
          'name': name,
          'email': email,
          'gender': gender,
          'ageGroupId': ageGroupId,
          'ageGroupName': ageGroupName,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmTokens': fcmToken != null ? [fcmToken] : [],
          'role': RoleManager().getDefaultRole(),
        },
      );

      // Save FCM token.
      await remoteDataSource.saveFcmToken(user.uid);

      // Send email verification.
      await remoteDataSource.sendEmailVerification();

      // Create user entity.
      final userEntity = UserModel.fromFirebase(user, null);

      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors.
      String message;

      // Map error codes to user-friendly messages.
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Signup not enabled';
          break;
        default:
          message = e.message ?? 'Signup failed';
      }

      return Left(AuthFailure(message: message, code: e.code));
    } catch (e) {
      // Map any other exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Runs the send email verification operation.
  @override
  Future<Either<AuthFailure, void>> sendEmailVerification() async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      // Map any exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Handles the check email verified operation.
  @override
  Future<Either<AuthFailure, bool>> checkEmailVerified() async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.reloadUser();

      // Get the current user.
      final user = remoteDataSource.getCurrentUser();

      // Return email verification status.
      return Right(user?.emailVerified ?? false);
    } catch (e) {
      // Map any exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Handles the resend verification email operation.
  @override
  Future<Either<AuthFailure, void>> resendVerificationEmail() async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      // Map any exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Requests a password reset email.
  @override
  Future<Either<AuthFailure, void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors.
      String message;

      // Map error codes to user-friendly messages.
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-not-found':
          message = 'Unable to send password reset email';
          break;
        case 'user-disabled':
          message = 'This user has been disabled';
          break;
        default:
          message = e.message ?? 'Unable to send password reset email';
      }

      return Left(AuthFailure(message: message, code: e.code));
    } catch (e) {
      // Map any other exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Handles the logout operation.
  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      // Map any exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Loads configured age groups.
  @override
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> getAgeGroups() async {
    try {
      // Fetch age groups from remote data source.
      final snapshot = await remoteDataSource.getAgeGroups();

      // Map documents to maps.
      final ageGroups = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name']?.toString() ?? '';
        final description = data['description']?.toString() ?? '';
        final sortOrder = data['sortOrder'] is int
            ? data['sortOrder'] as int
            : 0;
        final isActive = data['isActive'] is bool
            ? data['isActive'] as bool
            : true;

        return {
          'id': doc.id,
          'name': name,
          'description': description,
          'sortOrder': sortOrder,
          'isActive': isActive,
        };
      })
          .where((item) => item['isActive'] == true)
          .toList();

      return Right(ageGroups);
    } catch (e) {
      // Map any exception to an auth failure.
      return Left(AuthFailure(message: e.toString()));
    }
  }
}