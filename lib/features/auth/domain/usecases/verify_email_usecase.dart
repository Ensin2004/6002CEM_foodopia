import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailUseCase {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  Future<Either<AuthFailure, bool>> execute() async {
    return await repository.checkEmailVerified();
  }
}