import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/models/notification.dart'; // Import your Notification model

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Method to send a notification when a new comment is added
  Future<void> sendCommentNotification(String recipeId, Comment comment) async {
    final recipeDoc =
        await _firestore.collection('recipes').doc(recipeId).get();
    final recipeData = recipeDoc.data();

    if (recipeData != null) {
      final String creatorUsername =
          recipeData['createdBy']; // Use username instead of userId

      final payload = {
        'notification': {
          'title': 'New Comment!',
          'body':
              '${comment.userId} commented on your recipe: ${recipeData['title']}',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'to': creatorUsername, // Send directly to the user by username
      };

      await _sendNotification(payload);

      // Save the notification to Firestore
      await _saveNotification(NotificationModel(
        id: '', // Firestore will generate the ID
        title: 'New Comment!',
        body:
            '${comment.userId} commented on your recipe: ${recipeData['title']}',
        createdAt: DateTime.now(),
        userId: creatorUsername, // Associate with the recipe creator
      ));
    } else {
      print('Recipe data not found for recipeId: $recipeId');
    }
  }

  // Method to send a notification when a new like is added
  Future<void> sendLikeNotification(String recipeId, String userId) async {
    final recipeDoc =
        await _firestore.collection('recipes').doc(recipeId).get();
    final recipeData = recipeDoc.data();

    if (recipeData != null) {
      final String creatorUsername = recipeData['createdBy'];

      if (userId == creatorUsername) {
        // If the user liked their own recipe, save self-like notification
        final body = 'You liked your recipe: ${recipeData['title']}';

        await _saveNotification(NotificationModel(
          id: '', // Firestore will generate the ID
          title: 'Self Like',
          body: body,
          createdAt: DateTime.now(),
          userId: userId, // Associate with the user
        ));
      } else {
        final payload = {
          'notification': {
            'title': 'New Like!',
            'body': '$userId liked your recipe: ${recipeData['title']}',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'to': creatorUsername, // Send directly to the user by username
        };

        await _sendNotification(payload);

        // Save the notification to Firestore
        await _saveNotification(NotificationModel(
          id: '', // Firestore will generate the ID
          title: 'New Like!',
          body: '$userId liked your recipe: ${recipeData['title']}',
          createdAt: DateTime.now(),
          userId: creatorUsername, // Associate with the recipe creator
        ));
      }
    } else {
      print('Recipe data not found for recipeId: $recipeId');
    }
  }

  // Method to send a notification when a new recipe is created
  Future<void> sendNewRecipeNotification(Recipe recipe) async {
    final payload = {
      'notification': {
        'title': 'New Recipe!',
        'body': '${recipe.title} has been posted.',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'topic': 'all', // Send to all users
    };

    await _sendNotification(payload);

    // Save the notification to Firestore
    await _saveNotification(NotificationModel(
      id: '', // Firestore will generate the ID
      title: 'New Recipe!',
      body: '${recipe.title} has been posted.',
      createdAt: DateTime.now(),
      userId: 'all', // General identifier for all users
    ));
  }

  // Method to fetch notifications for a specific user by username
  Stream<List<NotificationModel>> fetchNotifications(String username) {
    return _firestore
        .collection('notifications')
        .where('userId',
            isEqualTo: username) // Filter notifications by username
        .orderBy('createdAt', descending: true) // Order by creation date
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          title: data['title'] ?? 'No Title', // Provide a default value
          body: data['body'] ?? 'No Body', // Provide a default value
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(), // Handle potential null
          userId: data['userId'] ?? 'Unknown', // Handle potential null
        );
      }).toList();
    });
  }

  // Method to delete a notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    // Fetch the notification to save it before deleting
    final notificationDoc =
        await _firestore.collection('notifications').doc(notificationId).get();
    if (notificationDoc.exists) {
      final notificationData = notificationDoc.data();

      // Save the deleted notification to a separate collection
      await _firestore.collection('deleted_notifications_$userId').add({
        'title': notificationData?['title'],
        'body': notificationData?['body'],
        'createdAt': notificationData?['createdAt'],
        'deletedAt': DateTime.now(),
        'userId': userId,
      });

      // Delete the notification
      await _firestore.collection('notifications').doc(notificationId).delete();
    }
  }

  // Internal method to send a notification
  Future<void> _sendNotification(Map<String, dynamic> payload) async {
    // You would typically call your backend to send the notification
    print('Sending notification: $payload');
  }

  // Method to save the notification to Firestore
  Future<void> _saveNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add({
      'title': notification.title,
      'body': notification.body,
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'userId': notification.userId,
    });
  }
}
