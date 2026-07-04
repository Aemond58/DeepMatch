import '../models/user_input.dart';

class Match {
  final String id;
  final UserInput user;
  final DateTime matchedAt;
  List<ChatMessage> messages;

  Match({
    required this.id,
    required this.user,
    required this.matchedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime sentAt;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.sentAt,
  });
}