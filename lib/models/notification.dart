// lib/models/notification.dart
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String userId; // Added userId for association

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.userId,
  });
}
