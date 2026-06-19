import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../entities/user_setup_preferences.dart';

/// Repository interface for user setup operations.
/// Defines data operations for user preferences and options during setup.
abstract class UserSetupRepository {
  /// Retrieves admin-configured options for a category.
  ///
  /// [categoryId] is the ID of the category (e.g., 'diet', 'allergies').
  /// Returns either a failure or a list of setup options on success.
  Future<Either<Failure, List<UserSetupOption>>> getAdminOptions(
      String categoryId,
      );

  /// Searches for foods matching a query.
  ///
  /// [query] is the search string.
  /// Returns either a failure or a list of matching food options on success.
  Future<Either<Failure, List<UserSetupOption>>> searchFoods(String query);

  /// Retrieves user preferences.
  ///
  /// [uid] is the user's unique identifier.
  /// Returns either a failure or the user's preferences on success.
  Future<Either<Failure, UserSetupPreferences>> getPreferences(String uid);

  /// Checks if user setup is completed.
  ///
  /// [uid] is the user's unique identifier.
  /// Returns either a failure or a boolean indicating completion status.
  Future<Either<Failure, bool>> isSetupCompleted(String uid);

  /// Saves user preferences.
  ///
  /// [uid] is the user's unique identifier.
  /// [preferences] is the preferences to save.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> savePreferences({
    required String uid,
    required UserSetupPreferences preferences,
  });
}