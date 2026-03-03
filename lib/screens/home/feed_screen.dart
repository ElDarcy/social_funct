import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/story_ring.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);

    return StreamBuilder(
      stream: postProvider.getFeedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share something!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic handled by stream
          },
          child: ListView(
            children: [
              // Stories section
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return StoryRing(
                      isAddStory: index == 0,
                      imageUrl: index == 0
                          ? null
                          : 'https://picsum.photos/100?random=$index',
                      username: index == 0 ? 'Your Story' : 'user_$index',
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Posts
              ...posts.map((post) => PostCard(post: post)).toList(),
            ],
          ),
        );
      },
    );
  }
}