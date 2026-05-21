/// About content entity for displaying documents like About Us, Terms, Privacy Policy
class AboutContent {
  final String id;
  final String title;
  final String content;
  final DateTime? updatedAt;

  /// Creates a about content instance.
  const AboutContent({
    required this.id,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  /// Handles the copy with operation.
  AboutContent copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    /// Handles the about content operation.
    return AboutContent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getter
  bool get isEmpty => content.isEmpty;
  /// Handles the is not empty operation.
  bool get isNotEmpty => content.isNotEmpty;
}
