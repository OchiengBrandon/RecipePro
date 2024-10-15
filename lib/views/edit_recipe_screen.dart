import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe? recipe; // Recipe to edit, null for creating a new one

  const EditRecipeScreen({super.key, this.recipe});

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();

  List<String> _ingredients = []; // List to store ingredients
  late String _userId; // Variable to hold the user ID

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Initialize user ID
    if (widget.recipe != null) {
      // If editing, populate the fields with existing recipe data
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _ingredients =
          List.from(widget.recipe!.ingredients); // Copy existing ingredients
    }
  }

  Future<void> _initializeUser() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      _userId = user.uid; // Store the user ID
    } else {
      // Handle the case where user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to edit recipes.')),
      );
      Navigator.pop(context);
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text);
        _ingredientController.clear(); // Clear input field
      });
    }
  }

  Future<void> _submitRecipe() async {
    String title = _titleController.text;
    String description = _descriptionController.text;

    if (title.isEmpty || description.isEmpty || _ingredients.isEmpty) {
      // Handle validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    Recipe newRecipe = Recipe(
      id: widget.recipe?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      title: title,
      description: description,
      ingredients: _ingredients,
      createdBy: _userId, // Use the actual user ID
      likes: [],
      dislikes: [],
      favorites: [], // Initialize favorites as an empty list
      comments: {}, // Initialize comments as an empty map
      createdAt: DateTime.now(),
    );

    if (widget.recipe == null) {
      // Create new recipe
      await _recipeService.createRecipe(newRecipe);
    } else {
      // Update existing recipe
      if (widget.recipe!.createdBy != _userId) {
        // Prevent unauthorized edits
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You are not authorized to edit this recipe.')),
        );
        return;
      }
      await _recipeService.updateRecipe(newRecipe);
    }

    Navigator.pop(context); // Go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Create Recipe' : 'Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Recipe Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Recipe Description'),
              maxLines: 5,
            ),
            TextField(
              controller: _ingredientController,
              decoration: const InputDecoration(labelText: 'Add Ingredient'),
            ),
            ElevatedButton(
              onPressed: _addIngredient,
              child: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 20),
            const Text('Ingredients:'),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_ingredients[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _ingredients.removeAt(index); // Remove ingredient
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRecipe,
              child: Text(
                  widget.recipe == null ? 'Submit Recipe' : 'Update Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
