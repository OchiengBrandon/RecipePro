import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailsScreen({super.key, required this.recipeId});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final RecipeService _recipeService = RecipeService();
  late String _userId;
  final TextEditingController _commentController = TextEditingController();
  String? _errorMessage;
  List<bool> _ingredientChecked = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      try {
        Comment newComment = Comment(
          userId: _userId,
          text: _commentController.text,
          createdAt: DateTime.now(),
        );
        await _recipeService.addComment(widget.recipeId, newComment);
        _commentController.clear(); // Clear the input after submission
      } catch (e) {
        setState(() {
          _errorMessage = "Failed to add comment: $e";
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _recipeService.toggleFavorite(widget.recipeId, _userId);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to toggle favorite: $e";
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _recipeService.toggleLike(widget.recipeId, _userId);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to toggle like: $e";
      });
    }
  }

  Future<void> _toggleDislike() async {
    try {
      await _recipeService.toggleDislike(widget.recipeId, _userId);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to toggle dislike: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Details"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipeData = snapshot.data!.data() as Map<String, dynamic>;
          final comments = recipeData['comments'] as Map<String, dynamic>;
          final likes = recipeData['likes'] as List<dynamic>;
          final dislikes = recipeData['dislikes'] as List<dynamic>;
          final favoritesCount = recipeData['favorites']?.length ?? 0;

          // Initialize ingredient checked states
          _ingredientChecked = List<bool>.generate(
              recipeData['ingredients'].length, (index) => false);

          bool isLiked = likes.contains(_userId);
          bool isDisliked = dislikes.contains(_userId);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe details (title, description, etc.)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipeData['title'],
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(recipeData['description'],
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Text("Created by: ${recipeData['createdBy']}",
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.comment, size: 16),
                              const SizedBox(width: 4),
                              Text('${comments.length} comments'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16),
                              const SizedBox(width: 4),
                              Text('$favoritesCount favorites'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _toggleFavorite,
                        child: const Text('Add to Favorites'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Ingredients Section
                const Text("Ingredients:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recipeData['ingredients'].length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text(recipeData['ingredients'][index]),
                      value: _ingredientChecked[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _ingredientChecked[index] = value!;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Like and Dislike Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        key: ValueKey<bool>(isLiked),
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                          color: isLiked ? Colors.blue : null,
                        ),
                        onPressed: _toggleLike,
                      ),
                    ),
                    Text('${likes.length} likes'),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        key: ValueKey<bool>(isDisliked),
                        icon: Icon(
                          isDisliked
                              ? Icons.thumb_down
                              : Icons.thumb_down_off_alt,
                          color: isDisliked ? Colors.red : null,
                        ),
                        onPressed: _toggleDislike,
                      ),
                    ),
                    Text('${dislikes.length} dislikes'),
                  ],
                ),

                const SizedBox(height: 16),
                const Text("Comments:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentKey = comments.keys.elementAt(index);
                      final comment = comments[commentKey];
                      return ListTile(
                        title: Text(comment['text']),
                        subtitle: Text('by $commentKey'),
                      );
                    },
                  ),
                ),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(labelText: 'Add a comment'),
                  onSubmitted: (_) => _addComment(),
                ),
                ElevatedButton(
                  onPressed: _addComment,
                  child: const Text('Submit'),
                ),
                if (_errorMessage != null) // Display error message if any
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
