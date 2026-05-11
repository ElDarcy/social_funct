import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/story_ring.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  int _feedTab = 0;
  List<UserModel> _storyUsers = [];
  bool _loadingStories = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Gamitin ang addPostFrameCallback para masiguradong ready na ang Provider context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStoryUsers();
    });
  }

  Future<void> _fetchStoryUsers() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      

      if (currentUser == null || currentUser.following.isEmpty) {
        if (mounted) {
          setState(() {
            _storyUsers = [];
            _loadingStories = false;
          });
        }
        return;
      }

      final followingIds = currentUser.following;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds.take(30).toList())
          .get();

      if (mounted) {
        setState(() {
          _storyUsers = snapshot.docs
              .map((doc) => UserModel.fromDocument(doc))
              .toList();
          _loadingStories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching story users: $e');
      if (mounted) setState(() => _loadingStories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';
    final currentUser = authProvider.currentUser;

    return Column(
      children: [
        // =================== TAB SWITCHER ===================
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              _buildTab('Following', 0),
              _buildTab('Explore', 1),
            ],
          ),
        ),

        // =================== FEED CONTENT ===================
        Expanded(
          child: StreamBuilder(
            stream: _feedTab == 0
                ? postProvider.getFollowingFeedPosts(userId)
                : postProvider.getFeedPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _feedTab == 0
                            ? Icons.people_outline
                            : Icons.photo_library_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _feedTab == 0
                            ? 'No posts from people you follow'
                            : 'No posts yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _feedTab == 0
                            ? 'Follow some users or check Explore!'
                            : 'Be the first to share something!',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                      if (_feedTab == 0) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _feedTab = 1),
                          child: const Text('Browse Explore'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _fetchStoryUsers();
                  setState(() {});
                },
                child: ListView(
                  children: [
                    // =================== STORIES ===================
                    SizedBox(
                      height: 115,
                      child: _loadingStories
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              itemCount: _storyUsers.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return StoryRing(
                                    isAddStory: true,
                                    imageUrl: currentUser?.profileImageUrl,
                                    username: 'Your Story',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Add story coming soon!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  );
                                }

                                final user = _storyUsers[index - 1];

                                if (user.id == userId) {
                                  return const SizedBox.shrink();
                                }

                                return StoryRing(
                                  isAddStory: false,
                                  imageUrl: user.profileImageUrl,
                                  username: user.username,
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${user.username}\'s story'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  onSecondaryTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.volume_off_outlined),
                                              title: Text(
                                                  'Mute ${user.username}'),
                                              onTap: () =>
                                                  Navigator.pop(context),
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.hide_source_outlined),
                                              title:
                                                  const Text('Hide Story'),
                                              onTap: () =>
                                                  Navigator.pop(context),
                                            ),
                                            ListTile(
                                              leading:
                                                  const Icon(Icons.close),
                                              title: const Text('Cancel'),
                                              onTap: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    const Divider(height: 1),

                    // =================== POSTS ===================
                    ...posts.map((post) => PostCard(post: post)).toList(),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _feedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _feedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
