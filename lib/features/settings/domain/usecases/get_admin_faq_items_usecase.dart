import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';
import '../repositories/faq_repository.dart';

class GetAdminFaqItemsUseCase {
  final FaqRepository repository;

  GetAdminFaqItemsUseCase(this.repository);

  Future<Either<Failure, List<FaqItem>>> execute() async {
    return await repository.getAdminFaqItems();
  }
}