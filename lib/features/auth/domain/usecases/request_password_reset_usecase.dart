import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository _repository;

  const RequestPasswordResetUseCase(this._repository);

  Future<Either<AuthFailure, void>> execute({required String email}) {
    return _repository.requestPasswordReset(email: email);
  }
}
