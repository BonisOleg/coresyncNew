import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../providers/providers.dart';
import '../widgets/glass_panel.dart';

class ConciergeScreen extends ConsumerStatefulWidget {
  const ConciergeScreen({super.key});

  @override
  ConsumerState<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends ConsumerState<ConciergeScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history =
        await ref.read(conciergeServiceProvider).getHistory();
    if (!mounted) return;
    setState(() {
      _messages = history;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final response =
          await ref.read(conciergeServiceProvider).sendMessage(text);
      if (!mounted) return;
      if (response != null) {
        setState(() {
          _messages = [..._messages, response];
          _isSending = false;
        });
      } else {
        setState(() => _isSending = false);
      }
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<void> _sendFlowAction(String flowStep, Map<String, dynamic> flowData) async {
    if (_isSending) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: flowStep,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final response = await ref.read(conciergeServiceProvider).sendFlowMessage(
        flowStep: flowStep,
        flowData: flowData,
      );
      if (!mounted) return;
      if (response != null) {
        setState(() {
          _messages = [..._messages, response];
          _isSending = false;
        });
      } else {
        setState(() => _isSending = false);
      }
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(
        title: const Text(
          'CONCIERGE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: CoreSyncColors.accent,
                      strokeWidth: 1.5,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CoreSyncColors.glass,
                shape: BoxShape.circle,
                border:
                    Border.all(color: CoreSyncColors.glassBorder),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 32,
                color: CoreSyncColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Concierge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: CoreSyncColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about your spa experience,\npreferences, or recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CoreSyncColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ChatBubble(
            message: msg,
            onFlowAction: _sendFlowAction,
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 80),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          borderRadius: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: _DotAnimation(delay: i * 200),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        8,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: CoreSyncColors.surface,
        border: Border(
          top: BorderSide(color: CoreSyncColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: CoreSyncColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: CoreSyncColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: CoreSyncColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: CoreSyncColors.glass,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CoreSyncColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_upward,
                size: 20,
                color: CoreSyncColors.bg,
              ),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String flowStep, Map<String, dynamic> flowData)? onFlowAction;

  const _ChatBubble({required this.message, this.onFlowAction});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? CoreSyncColors.accent.withAlpha(20)
                : CoreSyncColors.glass,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isUser ? const Radius.circular(18) : Radius.zero,
              bottomRight:
                  isUser ? Radius.zero : const Radius.circular(18),
            ),
            border: Border.all(
              color: isUser
                  ? CoreSyncColors.accent.withAlpha(40)
                  : CoreSyncColors.glassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: CoreSyncColors.textPrimary,
                  height: 1.5,
                ),
              ),
              if (_hasButtons) ...[
                const SizedBox(height: 10),
                _buildButtons(),
              ],
              const SizedBox(height: 6),
              Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: CoreSyncColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasButtons {
    final ui = message.uiData;
    if (ui == null) return false;
    return ui['buttons'] is List && (ui['buttons'] as List).isNotEmpty;
  }

  Widget _buildButtons() {
    final buttons = (message.uiData!['buttons'] as List)
        .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons.map((btn) {
        final label = btn['label'] as String? ?? '';
        final flowStep = btn['flow_step'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: OutlinedButton(
            onPressed: onFlowAction != null && flowStep.isNotEmpty
                ? () => onFlowAction!(flowStep, {
                      if (btn['value'] != null) btn['field_name'] ?? 'value': btn['value'],
                    })
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: CoreSyncColors.glassBorder),
              foregroundColor: CoreSyncColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: CoreSyncColors.textMuted
                  .withAlpha((120 + 135 * _animation.value).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
