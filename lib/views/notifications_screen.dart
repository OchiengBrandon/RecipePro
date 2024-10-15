import 'package:flutter/material.dart';
import 'package:food_recipe_app/models/notification.dart';
import 'package:food_recipe_app/services/notification_service.dart';
import 'package:food_recipe_app/services/profile_service.dart'; // Import ProfileService
import 'package:intl/intl.dart'; // Import for date formatting
import 'notification_details_screen.dart'; // Import the NotificationDetailsScreen

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? userId;
  String? userName;
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      ProfileService profileService = ProfileService();
      userId = profileService.currentUser?.uid; // Get the current user's ID
      userName = await profileService
          .getCurrentUsername(); // Get the current user's username

      if (mounted) {
        setState(() {
          isLoading = false; // Update loading state
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false; // Update loading state on error
        });
      }
      // Handle error if needed, e.g., show a dialog or message
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    if (userId != null) {
      await NotificationService().deleteNotification(notificationId, userId!);
      // Show a snackbar to indicate success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator()); // Show loading indicator
    }

    if (userId == null) {
      return const Center(
          child: Text('User ID not found.')); // Handle missing user ID
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().fetchNotifications(
          userName!), // Use username for fetching notifications
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Show loading indicator
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}')); // Display error message
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
              child: Text('No notifications available.')); // No notifications
        }

        return ListView.builder(
          padding:
              const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];

            return Dismissible(
              key: Key(notification.id), // Unique key for dismissible
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                _deleteNotification(
                    notification.id); // Delete notification on swipe
              },
              child: Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0), // Card margin
                elevation: 4, // Elevation for shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(16.0), // Padding inside the ListTile
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(
                          height: 8.0), // Space between body and date
                      Text(
                        DateFormat.yMMMd().add_jm().format(
                            notification.createdAt.toLocal()), // Format date
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to the Notification Details Screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailsScreen(
                          notification: notification,
                          userId: userId!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    // Any additional cleanup can be done here if necessary
  }
}
