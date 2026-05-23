import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.createdAt,
    super.isRead,
    super.nativeNotificationId,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
      nativeNotificationId: json['nativeNotificationId'] is int
          ? json['nativeNotificationId'] as int
          : int.tryParse(json['nativeNotificationId']?.toString() ?? ''),
    );
  }

  factory AppNotificationModel.fromEntity(AppNotification notification) {
    return AppNotificationModel(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      createdAt: notification.createdAt,
      isRead: notification.isRead,
      nativeNotificationId: notification.nativeNotificationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'nativeNotificationId': nativeNotificationId,
    };
  }

  static AppNotificationType _typeFromString(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AppNotificationType.planReminder,
    );
  }
}
