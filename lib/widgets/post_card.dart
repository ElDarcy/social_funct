import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/post_model.dart';
import '../screens/comments/comments_screen.dart';
import 'reaction_button.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showReactions = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://picsum.photos/100'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'username',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Media content
          GestureDetector(
            onDoubleTap: () {
              // Toggle like on double tap
              postProvider.toggleLike(
                postId: widget.post.id,
                userId: authProvider.currentUser!.id,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Media
                SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: widget.post.type == PostType.carousel
                      ? PageView.builder(
                    itemCount: widget.post.mediaUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.post.mediaUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  )
                      : Image.network(
                    widget.post.mediaUrls.first,
                    fit: BoxFit.cover,
                  ),
                ),

                // Reactions overlay
                if (_showReactions)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '❤️🔥👏',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Like button
                ReactionButton(
                  post: widget.post,
                  onReactionSelected: (reaction) {
                    postProvider.toggleLike(
                      postId: widget.post.id,
                      userId: authProvider.currentUser!.id,
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Comment button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(post: widget.post),
                      ),
                    );
                  },
                ),
                // Share button
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                // Save button
                IconButton(
                  icon: Icon(
                    widget.post.isSavedBy(authProvider.currentUser!.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  onPressed: () {
                    postProvider.toggleSave(
                      postId: widget.post.id,
                      userId: authProvider.currentUser!.id,
                    );
                  },
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.post.likesCount} likes',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'username',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.post.caption),
                ),
              ],
            ),
          ),

          // View comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommentsScreen(post: widget.post),
                  ),
                );
              },
              child: Text(
                widget.post.commentsCount > 0
                    ? 'View all ${widget.post.commentsCount} comments'
                    : 'No comments yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _formatTime(widget.post.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
