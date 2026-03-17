class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? messageType;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? uiData;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.messageType,
    this.metadata,
    this.uiData,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasStructuredUI => messageType != null && messageType != 'text';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final String parsedId = rawId is int ? rawId.toString() : (rawId as String? ?? '');

    Map<String, dynamic>? meta = json['metadata'] as Map<String, dynamic>?;
    Map<String, dynamic>? ui;
    String? msgType;

    if (meta != null) {
      msgType = meta['message_type'] as String?;
      ui = meta['ui_data'] as Map<String, dynamic>?;
    }

    return ChatMessage(
      id: parsedId,
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      messageType: msgType,
      metadata: meta,
      uiData: ui,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
