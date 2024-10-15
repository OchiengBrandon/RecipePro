import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // Import NotificationService
import '../models/recipe.dart';
import '../services/profile_service.dart'; // Import ProfileService

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      NotificationService(); // Instantiate NotificationService
  final ProfileService _profileService =
      ProfileService(); // Instantiate ProfileService

  Future<void> createRecipe(Recipe recipe) async {
    String username = await _fetchUsername(recipe.createdBy);

    await _firestore.collection('recipes').doc(recipe.id).set({
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'createdBy': username, // Use username instead of userId
      'likes': recipe.likes ?? [],
      'dislikes': recipe.dislikes ?? [],
      'comments': recipe.comments.map((_, comment) {
        return MapEntry(comment.userId, {
          'text': comment.text,
          'createdAt': comment.createdAt,
          'likes': comment.likes ?? [],
          'dislikes': comment.dislikes ?? [],
        });
      }),
      'favorites': recipe.favorites ?? [],
      'createdAt': recipe.createdAt,
    });

    // Send notification for the new recipe
    await _notificationService.sendNewRecipeNotification(recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    String username = await _fetchUsername(recipe.createdBy);

    await _firestore.collection('recipes').doc(recipe.id).update({
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'likes': recipe.likes ?? [],
      'dislikes': recipe.dislikes ?? [],
      'comments': recipe.comments.map((_, comment) {
        return MapEntry(comment.userId, {
          'text': comment.text,
          'createdAt': comment.createdAt,
          'likes': comment.likes ?? [],
          'dislikes': comment.dislikes ?? [],
        });
      }),
      'favorites': recipe.favorites ?? [],
      'createdBy': username, // Update username if needed
    });
  }

  Future<String> _fetchUsername(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['username'] ?? 'Unknown User';
    }
    return 'Unknown User'; // Fallback if the user document does not exist
  }

  Future<void> toggleFavorite(String recipeId, String username) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final favorites =
        List<String>.from(recipeSnapshot.data()?['favorites'] ?? []);

    if (favorites.contains(username)) {
      await recipeRef.update({
        'favorites': FieldValue.arrayRemove([username]),
      });
    } else {
      await recipeRef.update({
        'favorites': FieldValue.arrayUnion([username]),
      });
    }
  }

  Future<String> toggleLike(String recipeId, String username) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final likes = List<String>.from(recipeSnapshot.data()?['likes'] ?? []);
    final dislikes =
        List<String>.from(recipeSnapshot.data()?['dislikes'] ?? []);

    if (likes.contains(username)) {
      return 'You have already liked this recipe.'; // User feedback
    } else if (dislikes.contains(username)) {
      await recipeRef.update({
        'dislikes': FieldValue.arrayRemove([username]), // Remove dislike
        'likes': FieldValue.arrayUnion([username]), // Add like
      });
      await _notificationService.sendLikeNotification(recipeId, username);
      return 'You liked this recipe.';
    } else {
      await recipeRef.update({
        'likes': FieldValue.arrayUnion([username]), // Add like
      });
      await _notificationService.sendLikeNotification(recipeId, username);
      return 'You liked this recipe.';
    }
  }

  Future<String> toggleDislike(String recipeId, String username) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final dislikes =
        List<String>.from(recipeSnapshot.data()?['dislikes'] ?? []);
    final likes = List<String>.from(recipeSnapshot.data()?['likes'] ?? []);

    if (dislikes.contains(username)) {
      return 'You have already disliked this recipe.'; // User feedback
    } else if (likes.contains(username)) {
      await recipeRef.update({
        'likes': FieldValue.arrayRemove([username]), // Remove like
        'dislikes': FieldValue.arrayUnion([username]), // Add dislike
      });
      return 'You disliked this recipe.';
    } else {
      await recipeRef.update({
        'dislikes': FieldValue.arrayUnion([username]), // Add dislike
      });
      return 'You disliked this recipe.';
    }
  }

  Future<void> addComment(String recipeId, Comment comment) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final comments =
        recipeSnapshot.data()?['comments'] as Map<String, dynamic>? ?? {};

    if (comments.containsKey(comment.userId)) {
      return; // User already commented, ignore the new comment
    }

    await recipeRef.update({
      'comments': {
        ...comments,
        comment.userId: {
          'text': comment.text,
          'createdAt': comment.createdAt,
          'likes': comment.likes ?? [],
          'dislikes': comment.dislikes ?? [],
        },
      },
    });

    await _notificationService.sendCommentNotification(recipeId, comment);
  }

  Future<void> likeComment(String recipeId, String username) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final comments =
        recipeSnapshot.data()?['comments'] as Map<String, dynamic>? ?? {};

    if (comments.containsKey(username)) {
      await recipeRef.update({
        'comments.$username.likes': FieldValue.arrayUnion([username]),
        'comments.$username.dislikes': FieldValue.arrayRemove([username]),
      });
    }
  }

  Future<void> dislikeComment(String recipeId, String username) async {
    final recipeRef = _firestore.collection('recipes').doc(recipeId);
    final recipeSnapshot = await recipeRef.get();
    final comments =
        recipeSnapshot.data()?['comments'] as Map<String, dynamic>? ?? {};

    if (comments.containsKey(username)) {
      await recipeRef.update({
        'comments.$username.dislikes': FieldValue.arrayUnion([username]),
        'comments.$username.likes': FieldValue.arrayRemove([username]),
      });
    }
  }

  Future<List<Recipe>> getFavoriteRecipes(String username) async {
    final snapshot = await _firestore
        .collection('recipes')
        .where('favorites', arrayContains: username)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Recipe(
        id: doc.id,
        title: data['title'],
        description: data['description'],
        ingredients: List<String>.from(data['ingredients'] ?? []),
        createdBy: data['createdBy'], // This should now be the username
        likes: List<String>.from(data['likes'] ?? []),
        dislikes: List<String>.from(data['dislikes'] ?? []),
        favorites: List<String>.from(data['favorites'] ?? []),
        comments:
            (data['comments'] as Map<String, dynamic>? ?? {}).map((key, value) {
          return MapEntry(
            key,
            Comment(
              userId: key,
              text: value['text'],
              createdAt: (value['createdAt'] as Timestamp).toDate(),
              likes: List<String>.from(value['likes'] ?? []),
              dislikes: List<String>.from(value['dislikes'] ?? []),
            ),
          );
        }),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<List<Recipe>> fetchRecipes() async {
    final snapshot = await _firestore.collection('recipes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Recipe(
        id: doc.id,
        title: data['title'],
        description: data['description'],
        ingredients: List<String>.from(data['ingredients'] ?? []),
        createdBy: data['createdBy'], // This should now be the username
        likes: List<String>.from(data['likes'] ?? []),
        dislikes: List<String>.from(data['dislikes'] ?? []),
        favorites: List<String>.from(data['favorites'] ?? []),
        comments:
            (data['comments'] as Map<String, dynamic>? ?? {}).map((key, value) {
          return MapEntry(
            key,
            Comment(
              userId: key,
              text: value['text'],
              createdAt: (value['createdAt'] as Timestamp).toDate(),
              likes: List<String>.from(value['likes'] ?? []),
              dislikes: List<String>.from(value['dislikes'] ?? []),
            ),
          );
        }),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  // New method to fetch recipes as a stream
  Stream<List<Recipe>> fetchRecipesStream() {
    return _firestore.collection('recipes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          ingredients: List<String>.from(data['ingredients'] ?? []),
          createdBy: data['createdBy'], // This should now be the username
          likes: List<String>.from(data['likes'] ?? []),
          dislikes: List<String>.from(data['dislikes'] ?? []),
          favorites: List<String>.from(data['favorites'] ?? []),
          comments: (data['comments'] as Map<String, dynamic>? ?? {})
              .map((key, value) {
            return MapEntry(
              key,
              Comment(
                userId: key,
                text: value['text'],
                createdAt: (value['createdAt'] as Timestamp).toDate(),
                likes: List<String>.from(value['likes'] ?? []),
                dislikes: List<String>.from(value['dislikes'] ?? []),
              ),
            );
          }),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }
}
