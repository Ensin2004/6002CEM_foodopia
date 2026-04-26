import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/faq_repository.dart';

class DeleteFaqItemUseCase {
  final FaqRepository repository;

  DeleteFaqItemUseCase(this.repository);

  Future<Either<Failure, void>> execute(String id) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(message: 'ID cannot be empty'));
    }
    return await repository.deleteFaqItem(id);
  }
}