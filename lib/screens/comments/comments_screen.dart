import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/comment_service.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final CommentService _commentService = CommentService();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    String commentText = _commentController.text;
    _commentController.clear();

    try {
      await _commentService.addComment(
        postId: widget.post.id,
        userId: authProvider.currentUser!.id,
        username: authProvider.currentUser!.username,
        userProfileImage: authProvider.currentUser!.profileImageUrl,
        content: commentText,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(commentId, widget.post.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
  }

  Future<void> _toggleCommentLike(CommentModel comment) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      await _commentService.toggleCommentLike(
        commentId: comment.id,
        userId: authProvider.currentUser!.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments (${widget.post.commentsCount})'),
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder(
              stream: _commentService.getPostComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwnComment = authProvider.currentUser != null &&
                        comment.userId == authProvider.currentUser!.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: comment.userProfileImage != null
                                ? NetworkImage(comment.userProfileImage!)
                                : null,
                            child: comment.userProfileImage == null
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Comment content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(comment.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.content),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Like button
                                    GestureDetector(
                                      onTap: () => _toggleCommentLike(comment),
                                      child: Row(
                                        children: [
                                          Icon(
                                            authProvider.currentUser != null &&
                                                    comment.isLikedBy(
                                                        authProvider.currentUser!.id)
                                                ? Icons.favorite
                                                : Icons.favorite_outline,
                                            size: 16,
                                            color: authProvider.currentUser != null &&
                                                    comment.isLikedBy(
                                                        authProvider.currentUser!.id)
                                                ? Colors.red
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                          ),
                                          if (comment.likesCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '${comment.likesCount}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Reply
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Delete button (if own comment)
                          if (isOwnComment)
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Comment'),
                                    content: const Text(
                                        'Are you sure you want to delete this comment?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteComment(comment.id);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: authProvider.currentUser?.profileImageUrl != null
                        ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
                        : null,
                    child: authProvider.currentUser?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    color: const Color(0xFF6C63FF),
                    onPressed: _addComment,
                  ),
                ],
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
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
