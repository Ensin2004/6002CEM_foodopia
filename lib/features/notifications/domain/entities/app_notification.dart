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
  newCategory,
  recipeReview,
  recipeHidden,
  helpReply,
  planReminder,
}

// Domain entity for one notification shown inside the app.
// It stores the message, read status, time, and optional native Android
// notification id if the notification also exists on the device.
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
