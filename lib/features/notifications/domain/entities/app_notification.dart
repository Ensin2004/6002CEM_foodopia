enum AppNotificationType {
  newFollower,
  newRating,
  newComment,
  newRecipe,
  newReply,
  newLike,
  newUser,
  systemRating,
  newHelpTicket,
  helpReply,
  planReminder,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? nativeNotificationId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.nativeNotificationId,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      nativeNotificationId: nativeNotificationId,
    );
  }
}
