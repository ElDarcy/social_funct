import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
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
  UserModel? _postUser;
  bool _loadingUser = true;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _fetchPostUser();
  }

  Future<void> _fetchPostUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _postUser = UserModel.fromDocument(doc);
          _loadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final currentUser = authProvider.currentUser;
    final isOwner = widget.post.userId == currentUser?.id;
    final isFollowing = currentUser?.following.contains(widget.post.userId) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================== HEADER ===================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: _postUser?.profileImageUrl != null
                      ? NetworkImage(_postUser!.profileImageUrl!)
                      : null,
                  child: _postUser?.profileImageUrl == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _loadingUser
                      ? Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : Text(
                          _postUser?.username ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
                if (!isOwner && !_loadingUser)
                  TextButton(
                    onPressed: () async {
                      if (isFollowing) {
                        await authProvider.unfollowUser(widget.post.userId);
                      } else {
                        await authProvider.followUser(widget.post.userId);
                      }
                    },
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFollowing
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context, authProvider, postProvider),
                ),
              ],
            ),
          ),

          // =================== MEDIA ===================
          GestureDetector(
            onDoubleTap: () {
              if (currentUser != null) {
                postProvider.toggleLike(
                  postId: widget.post.id,
                  userId: currentUser.id,
                );
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                          width: double.infinity,
                        ),
                ),
              ],
            ),
          ),

          // =================== ACTION BUTTONS ===================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                ReactionButton(
                  post: widget.post,
                  onReactionSelected: (reaction) {
                    if (currentUser != null) {
                      postProvider.toggleLike(
                        postId: widget.post.id,
                        userId: currentUser.id,
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
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
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    currentUser != null && widget.post.isSavedBy(currentUser.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  onPressed: () {
                    if (currentUser != null) {
                      postProvider.toggleSave(
                        postId: widget.post.id,
                        userId: currentUser.id,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // =================== LIKES ===================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.post.likesCount} likes',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // =================== CAPTION ===================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _postUser?.username ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.post.caption)),
              ],
            ),
          ),

          // =================== COMMENTS ===================
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // =================== TIMESTAMP ===================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _formatTime(widget.post.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, AuthProvider authProvider, PostProvider postProvider) {
    final isOwner = widget.post.userId == authProvider.currentUser?.id;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCaptionDialog(context, postProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  postProvider.deletePost(widget.post.id, authProvider.currentUser!.id);
                },
              ),
            ],
            if (!isOwner) ...[
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Hide Post'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isHidden = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported. Thank you.')),
                  );
                  setState(() => _isHidden = true);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCaptionDialog(BuildContext context, PostProvider postProvider) {
    final controller = TextEditingController(text: widget.post.caption);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter new caption...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              postProvider.updatePost(widget.post.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
