/// FAQ Item Entity
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String? questionImageUrl;
  final String? answerImageUrl;
  final DateTime createdAt;

  /// Creates a faq item instance.
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.questionImageUrl,
    this.answerImageUrl,
    required this.createdAt,
  });

  /// Handles the has question image operation.
  bool get hasQuestionImage => questionImageUrl != null && questionImageUrl!.isNotEmpty;
  /// Handles the has answer image operation.
  bool get hasAnswerImage => answerImageUrl != null && answerImageUrl!.isNotEmpty;
}
