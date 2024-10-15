import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_recipe_app/views/favorites_screen.dart';
import 'package:food_recipe_app/views/recipe_screen.dart';
import 'package:food_recipe_app/views/notifications_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  int _selectedIndex = 0; // Track the selected index for bottom navigation
  late String _username; // Variable to hold the username
  bool _isLoading = true; // Loading state
  List<Widget> _screens = []; // Initialize as an empty list

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Initialize the user on startup
  }

  Future<void> _initializeUser() async {
    User? user = _auth.currentUser; // Get the current user
    if (user != null) {
      _username =
          await _fetchUsername(user.uid); // Fetch the username from Firestore
      _screens = [
        RecipeListScreen(
            username: _username), // Pass username to RecipeListScreen
        const FavoritesScreen(),
        const NotificationsScreen(),
        const ProfileScreen(),
      ];
    }
    setState(() {
      _isLoading = false; // Update loading state
    });
  }

  Future<String> _fetchUsername(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc['username'] ?? 'Unknown'; // Return username or default
    } catch (e) {
      print('Error fetching username: $e');
      return 'Unknown'; // Return default on error
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut(); // Sign out from Firebase
    await _googleSignIn.signOut(); // Sign out from Google
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Clear login status

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  AppBar _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: const Text('Recipes'),
        );
      case 1:
        return AppBar(
          title: const Text('Favorites'),
        );
      case 2:
        return AppBar(
          title: const Text('Notifications'),
        );
      case 3:
        return AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        );
      default:
        return AppBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens.isNotEmpty
              ? _screens[_selectedIndex]
              : const Center(child: Text('No screens available.')),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
