// Implements repository operations for password.

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/password_repository.dart';
import '../datasources/password_remote_datasource.dart';

/// Defines behavior for password repository impl.
/// Implements the PasswordRepository interface using remote data source.
class PasswordRepositoryImpl implements PasswordRepository {
  /// Remote data source for password operations.
  final PasswordRemoteDataSource remoteDataSource;

  /// Creates a password repository impl instance.
  PasswordRepositoryImpl({required this.remoteDataSource});

  /// Runs the change password operation.
  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors.
      String message;

      // Map error codes to user-friendly messages.
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log in again to change your password';
          break;
        default:
          message = e.message ?? 'Password change failed';
      }

      return Left(AuthFailure(message: message, code: e.code));
    } catch (e) {
      // Map any other exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}