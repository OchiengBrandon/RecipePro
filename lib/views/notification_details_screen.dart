import 'package:flutter/material.dart';
import 'package:food_recipe_app/models/notification.dart';
import 'package:food_recipe_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel notification;
  final String userId;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
    required this.userId,
  });

  Future<void> _deleteNotification(BuildContext context) async {
    await NotificationService().deleteNotification(notification.id, userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
    Navigator.of(context).pop(); // Go back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              notification.body,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Received at: ${DateFormat.yMMMd().add_jm().format(notification.createdAt.toLocal())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _deleteNotification(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
