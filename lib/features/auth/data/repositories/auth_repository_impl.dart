// Implements repository operations for auth.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/auth/role_manager.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Defines behavior for auth repository impl.
class AuthRepositoryImpl implements AuthRepository {
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

      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure(message: 'Login failed'));
      }

      final userDoc = await remoteDataSource.getUserFromFirestore(user.uid);
      final userEntity = UserModel.fromFirebase(user, userDoc);

      return Right(userEntity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
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
    required String countryId,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      final credential = await remoteDataSource.signup(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure(message: 'Signup failed'));
      }

      final fcmToken = await remoteDataSource.getFCMToken();

      await remoteDataSource.saveUserToFirestore(
        uid: user.uid,
        userData: {
          'name': name,
          'email': email,
          'gender': gender,
          'countryCurrencyId': countryId,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmTokens': fcmToken != null ? [fcmToken] : [],
          'role': RoleManager().getDefaultRole(),
        },
      );

      await remoteDataSource.sendEmailVerification();

      final userEntity = UserModel.fromFirebase(user, null);

      return Right(userEntity);

    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
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
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Handles the check email verified operation.
  @override
  Future<Either<AuthFailure, bool>> checkEmailVerified() async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.reloadUser();
      final user = remoteDataSource.getCurrentUser();
      return Right(user?.emailVerified ?? false);
    } catch (e) {
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
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Loads data for the get countries operation.
  @override
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> getCountries() async {
    try {
      // Runs the guarded operation that can throw.
      final snapshot = await remoteDataSource.getCountries();
      final countries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final country = data['country']?.toString() ?? '';
        final currency = data['currency']?.toString() ?? '';
        return {
          'id': doc.id,
          'country': country,
          'currency': currency
        };
      }).toList();
      return Right(countries);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }
}
