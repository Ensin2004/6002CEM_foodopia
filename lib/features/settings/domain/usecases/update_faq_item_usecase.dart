import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';
import '../repositories/faq_repository.dart';

class UpdateFaqItemUseCase {
  final FaqRepository repository;

  UpdateFaqItemUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String id,
    required String question,
    required String answer,
    String? existingQuestionImageUrl,
    String? existingAnswerImageUrl,
    File? newQuestionImageFile,
    File? newAnswerImageFile,
  }) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(message: 'ID cannot be empty'));
    }
    if (question.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Question cannot be empty'));
    }
    if (answer.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Answer cannot be empty'));
    }

    final item = FaqItem(
      id: id,
      question: question.trim(),
      answer: answer.trim(),
      questionImageUrl: existingQuestionImageUrl,
      answerImageUrl: existingAnswerImageUrl,
      createdAt: DateTime.now(),
    );

    return await repository.updateFaqItem(item);
  }
}