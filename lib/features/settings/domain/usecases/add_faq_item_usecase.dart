import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';
import '../repositories/faq_repository.dart';

class AddFaqItemUseCase {
  final FaqRepository repository;

  AddFaqItemUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String question,
    required String answer,
    File? questionImageFile,
    File? answerImageFile,
  }) async {
    if (question.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Question cannot be empty'));
    }
    if (answer.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Answer cannot be empty'));
    }

    final item = FaqItem(
      id: '', // Will be set by Firestore
      question: question.trim(),
      answer: answer.trim(),
      createdAt: DateTime.now(),
    );

    return await repository.addFaqItem(item);
  }
}