/// About content entity for displaying documents like About Us, Terms, Privacy Policy
class AboutContent {
  final String id;
  final String title;
  final String content;
  final DateTime? updatedAt;

  const AboutContent({
    required this.id,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  AboutContent copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return AboutContent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Helper getter
  bool get isEmpty => content.isEmpty;
  bool get isNotEmpty => content.isNotEmpty;
}