import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class PasswordRepository {
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}