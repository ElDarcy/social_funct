import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values[data['type'] ?? 0],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final MessageType lastMessageType;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic> participantDetails;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.participantDetails,
  });

  factory ConversationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageType: MessageType.values[data['lastMessageType'] ?? 0],
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      participantDetails: data['participantDetails'] ?? {},
    );
  }
}