import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/faq_item.dart';

class FaqItemModel extends FaqItem {
  const FaqItemModel({
    required super.id,
    required super.question,
    required super.answer,
    super.questionImageUrl,
    super.answerImageUrl,
    required super.createdAt,
  });

  factory FaqItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FaqItemModel(
      id: doc.id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      questionImageUrl: data['questionImageUrl'] as String?,
      answerImageUrl: data['answerImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      if (questionImageUrl != null) 'questionImageUrl': questionImageUrl,
      if (answerImageUrl != null) 'answerImageUrl': answerImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{
      'question': question,
      'answer': answer,
    };
    if (questionImageUrl != null) {
      data['questionImageUrl'] = questionImageUrl;
    }
    if (answerImageUrl != null) {
      data['answerImageUrl'] = answerImageUrl;
    }
    return data;
  }
}