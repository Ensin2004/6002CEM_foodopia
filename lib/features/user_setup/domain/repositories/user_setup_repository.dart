import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_option.dart';
import '../entities/user_setup_preferences.dart';

abstract class UserSetupRepository {
  Future<Either<Failure, List<UserSetupOption>>> getAdminOptions(
    String categoryId,
  );

  Future<Either<Failure, List<UserSetupOption>>> searchFoods(String query);

  Future<Either<Failure, UserSetupPreferences>> getPreferences(String uid);

  Future<Either<Failure, bool>> isSetupCompleted(String uid);

  Future<Either<Failure, void>> savePreferences({
    required String uid,
    required UserSetupPreferences preferences,
  });
}
