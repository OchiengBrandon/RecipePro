import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a recipe to the user's favorites.
  Future<void> addToFavorites(String userId, String recipeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([recipeId]),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Removes a recipe from the user's favorites.
  Future<void> removeFromFavorites(String userId, String recipeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([recipeId]),
      });
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Retrieves the list of favorite recipes for a user.
  Future<List<String>> getFavoriteRecipes(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return List<String>.from(userDoc['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to retrieve favorites: $e');
    }
  }
}
