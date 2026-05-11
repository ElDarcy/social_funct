import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.currentUser;

    return StreamBuilder(
      stream: postProvider.getUserPosts(user?.id ?? ''),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(user?.username ?? 'Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.username ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user?.bio != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user!.bio!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(posts.length.toString(), 'Posts'),
                          _buildStatItem(
                              user?.followersCount.toString() ?? '0', 'Followers'),
                          _buildStatItem(
                              user?.followingCount.toString() ?? '0', 'Following'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Edit profile button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Posts grid
                if (posts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to post detail
                        },
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: post.mediaUrls.isNotEmpty
                              ? Image.network(
                            post.mediaUrls.first,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.image_outlined),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
