import 'package:flutter/material.dart';
import '../../models/comment_model.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final bool isOwnComment;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onDelete,
    this.isOwnComment = false,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
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
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            comment.isLikedBy(comment.userId)
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            size: 16,
                            color: comment.isLikedBy(comment.userId)
                                ? Colors.red
                                : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
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
                                    .withOpacity(0.6),
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
                            .withOpacity(0.6),
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
              onPressed: onDelete,
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