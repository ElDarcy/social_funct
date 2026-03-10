import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SEND MESSAGE
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      String conversationId = _getConversationId(senderId, receiverId);

      // Generate message ID
      String messageId = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc()
          .id;

      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        createdAt: DateTime.now(),
      );

      // SAVE MESSAGE TO SUBCOLLECTION
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Conversation reference
      DocumentReference convRef =
      _firestore.collection('conversations').doc(conversationId);

      DocumentSnapshot convDoc = await convRef.get();

      // UPDATE OR CREATE CONVERSATION
      if (convDoc.exists) {
        await convRef.update({
          'lastMessage': content,
          'lastMessageType': type.index,
          'lastMessageTime': message.createdAt,
          'unreadCount': FieldValue.increment(1),
        });
      } else {
        await convRef.set({
          'participants': [senderId, receiverId],
          'lastMessage': content,
          'lastMessageType': type.index,
          'lastMessageTime': message.createdAt,
          'unreadCount': 1,
        });
      }

      return message;
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  // GET USER CONVERSATIONS
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ConversationModel> conversations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        String otherUserId =
        participants.firstWhere((id) => id != userId, orElse: () => '');

        if (otherUserId.isEmpty) continue;

        var userDoc =
        await _firestore.collection('users').doc(otherUserId).get();

        if (userDoc.exists) {
          final participantDetails = {
            'id': otherUserId,
            'username': userDoc.get('username') ?? 'Unknown User',
            'profileImageUrl': userDoc.data()?.containsKey('profileImageUrl') ==
                true
                ? userDoc.get('profileImageUrl')
                : null,
          };

          conversations.add(
            ConversationModel(
              id: doc.id,
              participants: participants,
              lastMessage: data['lastMessage'] ?? '',
              lastMessageType:
              MessageType.values[data['lastMessageType'] ?? 0],
              lastMessageTime:
              (data['lastMessageTime'] as Timestamp).toDate(),
              unreadCount: data['unreadCount'] ?? 0,
              participantDetails: participantDetails,
            ),
          );
        }
      }

      return conversations;
    });
  }

  // GET MESSAGES
  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    String conversationId = _getConversationId(userId1, userId2);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromDocument(doc))
          .toList();
    });
  }

  // MARK MESSAGES AS READ
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      QuerySnapshot messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Mark messages as read error: $e');
    }
  }

  // GENERATE CONVERSATION ID
  String _getConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}