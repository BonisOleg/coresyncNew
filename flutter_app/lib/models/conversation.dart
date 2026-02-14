/// Chat message model matching the Django Message model.
class ChatMessage {
  final String id;
  final String role;
  final String content;
  final Map<String, dynamic> metadata;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.metadata = const {},
    this.createdAt = '',
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      metadata: json['metadata'] ?? {},
      createdAt: json['created_at'] ?? '',
    );
  }
}
