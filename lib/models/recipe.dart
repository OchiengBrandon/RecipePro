class Recipe {
  String id; // Unique identifier for the recipe
  String title; // Title of the recipe
  String description; // Description of the recipe
  List<String> ingredients; // List of ingredients
  String createdBy; // User ID of the creator
  List<String> likes; // List of user IDs who liked the recipe
  List<String> dislikes; // List of user IDs who disliked the recipe
  List<String> favorites; // List of user IDs who favorited the recipe
  Map<String, Comment> comments; // Map of comments with user ID as key
  DateTime createdAt; // Creation date of the recipe

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.createdBy,
    required this.likes,
    required this.dislikes,
    required this.favorites, // Initialize favorites
    required this.comments,
    required this.createdAt,
  });

  void addLike(String userId) {
    if (!likes.contains(userId)) {
      likes.add(userId);
    }
    dislikes.remove(userId); // Remove dislike if user liked
  }

  void addDislike(String userId) {
    if (!dislikes.contains(userId)) {
      dislikes.add(userId);
    }
    likes.remove(userId); // Remove like if user disliked
  }

  void addFavorite(String userId) {
    if (!favorites.contains(userId)) {
      favorites.add(userId);
    }
  }

  void removeFavorite(String userId) {
    favorites.remove(userId); // Remove user from favorites
  }

  void addComment(Comment comment) {
    comments[comment.userId] = comment; // Add or update the comment by user ID
  }
}

class Comment {
  String userId; // User ID of the commenter
  String text; // Comment text
  DateTime createdAt; // Creation date of the comment
  List<String> likes; // List of user IDs who liked the comment
  List<String> dislikes; // List of user IDs who disliked the comment

  Comment({
    required this.userId,
    required this.text,
    required this.createdAt,
    this.likes = const [],
    this.dislikes = const [],
  });

  void addLike(String userId) {
    if (!likes.contains(userId)) {
      likes.add(userId);
    }
    dislikes.remove(userId); // Remove dislike if user liked
  }

  void addDislike(String userId) {
    if (!dislikes.contains(userId)) {
      dislikes.add(userId);
    }
    likes.remove(userId); // Remove like if user disliked
  }
}
