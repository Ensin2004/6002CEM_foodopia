/// FAQ Item Entity
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String? questionImageUrl;
  final String? answerImageUrl;
  final DateTime createdAt;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.questionImageUrl,
    this.answerImageUrl,
    required this.createdAt,
  });

  bool get hasQuestionImage => questionImageUrl != null && questionImageUrl!.isNotEmpty;
  bool get hasAnswerImage => answerImageUrl != null && answerImageUrl!.isNotEmpty;
}