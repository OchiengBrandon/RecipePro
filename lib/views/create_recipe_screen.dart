import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen>
    with SingleTickerProviderStateMixin {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animation setup
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    Recipe newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      title: title,
      description: description,
      ingredients: _ingredients,
      createdBy: 'userId', // Replace with the actual user ID
      likes: [],
      dislikes: [],
      favorites: [],
      comments: {},
      createdAt: DateTime.now(),
    );

    await _recipeService.createRecipe(newRecipe);
    Navigator.pop(context); // Go back to previous screen
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe'),
        backgroundColor: Colors.teal,
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Title',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Description',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2.0),
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ingredientController,
                decoration: const InputDecoration(
                  labelText: 'Add Ingredient',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addIngredient,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Add Ingredient'),
              ),
              const SizedBox(height: 20),
              const Text('Ingredients:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(_ingredients[index]),
                      onDismissed: (direction) {
                        setState(() {
                          _ingredients.removeAt(index); // Remove ingredient
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${_ingredients[index]} removed')),
                        );
                      },
                      background: Container(color: Colors.red),
                      child: ListTile(
                        title: Text(_ingredients[index]),
                        trailing: const Icon(Icons.delete, color: Colors.teal),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRecipe,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Submit Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
