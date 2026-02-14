import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/conversation.dart';

/// Chat message bubble matching the website's concierge chat style.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String action)? onActionTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final buttons = message.metadata['buttons'] as List<dynamic>?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withAlpha(25)
              : CoreSyncTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isUser
              ? null
              : Border.all(color: CoreSyncTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CoreSyncTheme.textPrimary,
                    height: 1.5,
                  ),
            ),
            if (buttons != null && buttons.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...buttons.map((btn) {
                final label = btn['label'] ?? '';
                final action = btn['action'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onActionTap != null
                          ? () => onActionTap!(action)
                          : null,
                      child: Text(label),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
