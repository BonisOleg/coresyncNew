import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/conversation.dart';
import 'api_service.dart';

/// Service for interacting with the AI concierge via the Django API.
class ConciergeService extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ChatMessage> _messages = [];
  String _sessionId = '';
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// Initialize with the welcome message.
  void initialize() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        id: 'welcome',
        role: 'assistant',
        content:
            'Welcome. I\'m your CoreSync concierge. '
            'Are you here to book an evening, explore membership, '
            'or just feel the space?',
        metadata: {
          'buttons': [
            {'label': 'Book an evening', 'action': 'book'},
            {'label': 'Explore membership', 'action': 'membership'},
            {'label': 'Just exploring', 'action': 'explore'},
          ]
        },
      ));
      notifyListeners();
    }
  }

  /// Send a message to the concierge.
  Future<void> sendMessage(String text, {String action = ''}) async {
    if (text.isEmpty && action.isEmpty) return;

    // Add user message locally
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text.isNotEmpty ? text : action,
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'message': text.isNotEmpty ? text : action,
        if (_sessionId.isNotEmpty) 'session_id': _sessionId,
        if (action.isNotEmpty) 'action': action,
      };

      final response = await _api.post(ApiConfig.conciergeMessageUrl, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final msg = ChatMessage.fromJson(data['message']);
        _sessionId = data['session_id'] ?? _sessionId;
        _messages.add(msg);
      } else {
        _messages.add(ChatMessage(
          id: 'error-${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: 'I appreciate your patience. Could you try again?',
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: 'Connection issue. Please check your network and try again.',
      ));
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear conversation.
  void clear() {
    _messages.clear();
    _sessionId = '';
    notifyListeners();
  }
}
