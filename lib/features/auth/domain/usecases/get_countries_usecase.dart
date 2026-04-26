import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class GetCountriesUseCase {
  final AuthRepository repository;

  GetCountriesUseCase(this.repository);

  Future<Either<AuthFailure, List<Map<String, dynamic>>>> execute() async {
    return await repository.getCountries();
  }
}