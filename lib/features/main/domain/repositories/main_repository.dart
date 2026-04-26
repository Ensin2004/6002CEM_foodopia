import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class MainRepository {
  Future<Either<Failure, String?>> getUserProfileImage(String userId);
  Future<Either<Failure, void>> updateLastLogin(String userId);
}