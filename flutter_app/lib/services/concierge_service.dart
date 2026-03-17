import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

class ConciergeService {
  final ApiClient _client;
  String? _sessionId;

  ConciergeService(this._client);

  String? get sessionId => _sessionId;

  Future<ChatMessage?> sendMessage(String content) async {
    return sendFlowMessage(content: content);
  }

  Future<ChatMessage?> sendFlowMessage({
    String content = '',
    String flowStep = '',
    Map<String, dynamic> flowData = const {},
  }) async {
    try {
      final body = <String, dynamic>{
        'message': content,
        if (_sessionId != null) 'session_id': _sessionId,
        if (flowStep.isNotEmpty) 'flow_step': flowStep,
        if (flowData.isNotEmpty) 'flow_data': flowData,
      };

      final response = await _client.post(
        ApiConfig.conciergeMessage,
        data: body,
      );

      final data = response.data as Map<String, dynamic>;

      _sessionId = data['session_id'] as String? ?? _sessionId;

      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) return null;

      final msg = ChatMessage.fromJson(messageData);
      return msg;
    } on DioException {
      rethrow;
    }
  }

  Future<List<ChatMessage>> getHistory() async {
    try {
      final response = await _client.get(ApiConfig.conciergeHistory);
      final data = response.data;

      final List<dynamic> conversations = data is List<dynamic>
          ? data
          : (data as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];

      final messages = <ChatMessage>[];
      for (final conv in conversations) {
        final convMap = conv as Map<String, dynamic>;
        final msgList = convMap['messages'] as List<dynamic>? ?? [];
        for (final m in msgList) {
          messages.add(ChatMessage.fromJson(m as Map<String, dynamic>));
        }
        if (_sessionId == null) {
          _sessionId = convMap['id'] as String?;
        }
      }
      return messages;
    } on DioException {
      return [];
    }
  }
}
