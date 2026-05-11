import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Track users currently being processed (follow/unfollow)
  final Map<String, bool> _processingIds = {};

  @override
  void initState() {
    super.initState();
    // Load initial users to show "real users" immediately
    _fetchInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialUsers() async {
    setState(() => _isSearching = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(20)
          .get();
      
      if (mounted) {
        setState(() {
          _results = snapshot.docs
              .map((doc) => UserModel.fromDocument(doc))
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial users: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _fetchInitialUsers();
      setState(() {
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // ✅ Search logic - Note: Firestore is case-sensitive.
      // To make it case-insensitive, you'd usually store a lowercase_username field.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      if (mounted) {
        setState(() {
          _results = snapshot.docs
              .map((doc) => UserModel.fromDocument(doc))
              .toList();
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {});
                // Simple debounce logic
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
            ),
          ),
        ),
      ),
      body: _isSearching && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text('No users found'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchInitialUsers,
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      // Don't show current user in search results
                      if (user.id == currentUser?.id) return const SizedBox.shrink();
                      
                      final isFollowing = currentUser?.following.contains(user.id) ?? false;
                      final isProcessing = _processingIds[user.id] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${user.followersCount} followers'),
                        trailing: SizedBox(
                          width: 100,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () async {
                              setState(() => _processingIds[user.id] = true);
                              try {
                                if (isFollowing) {
                                  await authProvider.unfollowUser(user.id);
                                  if (mounted) {
                                    setState(() {
                                      _results[index] = user.copyWith(
                                        followersCount: (user.followersCount - 1).clamp(0, 999999),
                                      );
                                    });
                                  }
                                } else {
                                  await authProvider.followUser(user.id);
                                  if (mounted) {
                                    setState(() {
                                      _results[index] = user.copyWith(
                                        followersCount: user.followersCount + 1,
                                      );
                                    });
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'))
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _processingIds[user.id] = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey.shade200
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: isFollowing ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isProcessing 
                              ? const SizedBox(
                                  height: 16, 
                                  width: 16, 
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, 
                                    color: Colors.grey
                                  )
                                )
                              : Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
