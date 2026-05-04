// Executes the add faq item use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Defines behavior for add faq item use case.
class AddFaqItemUseCase {
  final FaqRepository repository;

  /// Creates a add faq item use case instance.
  AddFaqItemUseCase(this.repository);

  /// Validates input and delegates the add faq item request to the repository.
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
