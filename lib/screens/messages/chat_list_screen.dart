import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Global Search: Naghahanap sa buong 'users' collection sa Firestore
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Naghahanap ng users kung saan ang username ay nagsisimula sa query
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(15)
          .get();

      if (mounted) {
        setState(() {
          _searchResults = snapshot.docs
              .map((doc) => UserModel.fromDocument(doc))
              .toList();
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
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _searchUsers(value),
              decoration: InputDecoration(
                hintText: 'Search people to message...',
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
                fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults(currentUserId)
                : _buildConversationList(currentUserId),
          ),
        ],
      ),
    );
  }

  // UI para sa Global Search Results
  Widget _buildSearchResults(String currentUserId) {
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        // Wag ipakita ang sarili sa search results
        if (user.id == currentUserId) return const SizedBox.shrink();

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Tap to start chatting'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  receiverId: user.id,
                  receiverName: user.username,
                  receiverImageUrl: user.profileImageUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UI para sa dati nang mga usapan (Conversations)
  Widget _buildConversationList(String userId) {
    return StreamBuilder<List<ConversationModel>>(
      stream: MessageService().getUserConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Search for anyone to start a chat!'),
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
                radius: 28,
                backgroundImage: otherUser['profileImageUrl'] != null && otherUser['profileImageUrl'] != ''
                    ? NetworkImage(otherUser['profileImageUrl'])
                    : null,
                child: (otherUser['profileImageUrl'] == null || otherUser['profileImageUrl'] == '')
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(otherUser['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_formatTime(conversation.lastMessageTime)),
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
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${dateTime.day}/${dateTime.month}';
  }
}
