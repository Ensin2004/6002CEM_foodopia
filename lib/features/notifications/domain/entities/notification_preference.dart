class NotificationPreference {
  final String id;
  final String title;
  final String description;
  final bool enabled;

  const NotificationPreference({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  NotificationPreference copyWith({bool? enabled}) {
    return NotificationPreference(
      id: id,
      title: title,
      description: description,
      enabled: enabled ?? this.enabled,
    );
  }
}
