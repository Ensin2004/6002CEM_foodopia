import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotificationModel(
      id: doc.id,
      type: _typeFromString(data['type']?.toString()),
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      createdAt: _dateTime(data['createdAt']),
      isRead: data['isRead'] == true,
      nativeNotificationId: data['nativeNotificationId'] is int
          ? data['nativeNotificationId'] as int
          : int.tryParse(data['nativeNotificationId']?.toString() ?? ''),
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

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
