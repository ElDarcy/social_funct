import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'feed_screen.dart';
import '../create/create_post_screen.dart';
import '../messages/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const Center(child: Text('Search', style: TextStyle(fontSize: 24))),
    const CreatePostScreen(),
    const ChatListScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Social App',
    'Search',
    'Create',
    'Messages',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}