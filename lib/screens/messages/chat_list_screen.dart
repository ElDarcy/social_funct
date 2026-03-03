import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder(
      stream: MessageService().getUserConversations(authProvider.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with your friends!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final otherUser = conversation.participantDetails;

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: otherUser['profileImageUrl'] != null
                    ? NetworkImage(otherUser['profileImageUrl'])
                    : null,
                child: otherUser['profileImageUrl'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                otherUser['username'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(conversation.lastMessageTime),
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
              trailing: conversation.unreadCount > 0
                  ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: otherUser['id'],
                      receiverName: otherUser['username'],
                      receiverImageUrl: otherUser['profileImageUrl'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
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