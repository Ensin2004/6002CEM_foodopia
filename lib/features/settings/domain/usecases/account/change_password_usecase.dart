import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/password_repository.dart';

/// Runs the change password use case operation.
class ChangePasswordUseCase {
  final PasswordRepository repository;

  /// Runs the change password use case operation.
  ChangePasswordUseCase(this.repository);

  /// Validates input and delegates the change password request to the repository.
  Future<Either<Failure, void>> execute({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Checks required fields before repository access.
    if (currentPassword.isEmpty) {
      return Left(ValidationFailure(message: 'Current password cannot be empty'));
    }
    if (newPassword.isEmpty) {
      return Left(ValidationFailure(message: 'New password cannot be empty'));
    }

    // Checks password strength rules before submission.
    if (newPassword.length < 12) {
      return Left(ValidationFailure(message: 'Password must be at least 12 characters'));
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      return Left(ValidationFailure(message: 'Password must contain at least one uppercase letter'));
    }
    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      return Left(ValidationFailure(message: 'Password must contain at least one lowercase letter'));
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      return Left(ValidationFailure(message: 'Password must contain at least one number'));
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
      return Left(ValidationFailure(message: 'Password must contain at least one special character'));
    }

    return await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
