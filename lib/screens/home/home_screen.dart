import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'feed_screen.dart';
import '../create/create_post_screen.dart';
import '../messages/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../explore/explore_screen.dart'; // Inibalik ang ExploreScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onPostCreated() {
    setState(() => _currentIndex = 0); // Go back to feed
  }

  // List of screens for the navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      const ExploreScreen(), // Gagamit ng ExploreScreen na may Search Bar sa loob
      CreatePostScreen(onPostCreated: _onPostCreated),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: _currentIndex == 2 || _currentIndex == 1 // Hide AppBar for Explore (index 1) and Create (index 2)
          ? null 
          : AppBar(
              title: Text(_getTitle(_currentIndex), style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                if (_currentIndex == 0) ...[
                   IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
                if (_currentIndex == 4) ...[
                  IconButton(
                    icon: const Icon(Icons.logout_outlined),
                    onPressed: () => _showLogoutDialog(context, authProvider),
                  ),
                ]
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Social App';
      case 1: return 'Explore';
      case 2: return 'Create Post';
      case 3: return 'Messages';
      case 4: return 'Profile';
      default: return '';
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
