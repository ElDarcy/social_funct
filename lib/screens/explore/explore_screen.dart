import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  
  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];
  bool _isSearching = false;
  final Map<String, bool> _processingIds = {};
  
  // ✅ I-store ang stream para hindi mag-reset tuwing build
  Stream<List<PostModel>>? _exploreStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize ang stream dito para stable
    _exploreStream = Provider.of<PostProvider>(context, listen: false).getFeedPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _postResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(15)
          .get();

      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('caption', isGreaterThanOrEqualTo: query)
          .where('caption', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      if (mounted) {
        setState(() {
          _userResults = userSnapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
          _postResults = postSnapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList();
          _isSearching = false;
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _performSearch(value),
            decoration: InputDecoration(
              hintText: 'Search users or posts...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        bottom: _searchController.text.isNotEmpty
            ? TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.onSurface,
                tabs: const [
                  Tab(text: 'Accounts'),
                  Tab(text: 'Posts'),
                ],
              )
            : null,
      ),
      body: _searchController.text.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildUserResults(authProvider, currentUser),
                _buildPostResults(),
              ],
            )
          : _buildExploreGrid(),
    );
  }

  Widget _buildExploreGrid() {
    return StreamBuilder<List<PostModel>>(
      stream: _exploreStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('No posts found.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () => _showPostDetail(context, post),
              child: Image.network(
                post.mediaUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserResults(AuthProvider authProvider, UserModel? currentUser) {
    if (_isSearching && _userResults.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_userResults.isEmpty) return const Center(child: Text('No users found.'));

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        if (user.id == currentUser?.id) return const SizedBox.shrink();

        final isFollowing = currentUser?.following.contains(user.id) ?? false;
        final isProcessing = _processingIds[user.id] ?? false;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${user.followersCount} followers'),
          trailing: SizedBox(
            width: 90,
            height: 32,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () async {
                setState(() => _processingIds[user.id] = true);
                try {
                  if (isFollowing) {
                    await authProvider.unfollowUser(user.id);
                  } else {
                    await authProvider.followUser(user.id);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Follow error: $e'))
                    );
                  }
                } finally {
                  if (mounted) setState(() => _processingIds[user.id] = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[300] : Theme.of(context).colorScheme.primary,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Text(isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostResults() {
    if (_isSearching && _postResults.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_postResults.isEmpty) return const Center(child: Text('No posts found.'));

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return GestureDetector(
          onTap: () => _showPostDetail(context, post),
          child: Image.network(
            post.mediaUrls.first,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void _showPostDetail(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: PostCard(post: post),
          );
        },
      ),
    );
  }
}
