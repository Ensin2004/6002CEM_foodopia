import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_preferences.dart';
import '../repositories/user_setup_repository.dart';

/// Use case for saving user setup preferences.
/// Encapsulates the business logic for persisting user preferences.
class SaveUserSetupPreferencesUseCase {
  /// Repository instance for data operations.
  final UserSetupRepository repository;

  /// Creates a new save user setup preferences use case instance.
  SaveUserSetupPreferencesUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [uid] is the user's unique identifier.
  /// [preferences] is the preferences to save.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required UserSetupPreferences preferences,
  }) {
    // Delegate to repository to save preferences.
    return repository.savePreferences(uid: uid, preferences: preferences);
  }
}