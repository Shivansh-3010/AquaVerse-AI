import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/providers/app_provider.dart';
import '../../../data/providers/chatbot_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<ChatbotProvider>();
      final appProvider = context.read<AppProvider>();
      // Restore Gemini session if key exists but session wasn't restored
      if (appProvider.geminiApiKey.isNotEmpty) {
        chatProvider.initializeGemini(appProvider.geminiApiKey);
      }
      // Restore Groq key if set
      if (appProvider.groqApiKey.isNotEmpty) {
        chatProvider.setGroqKey(appProvider.groqApiKey);
      }
      await chatProvider.loadHistoryIfNeeded();
      if (chatProvider.messages.isEmpty) {
        chatProvider.addGreeting();
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    setState(() => _showSuggestions = false);
    final chatProvider = context.read<ChatbotProvider>();
    final appProvider = context.read<AppProvider>();
    // Pass live ocean conditions so Gemini can give context-aware answers
    await chatProvider.sendMessage(
      text,
      liveContext: appProvider.liveContextSummary,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AquaVerse.ai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Ocean Safety Assistant',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<ChatbotProvider>(
            builder: (_, provider, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Clear chat',
              onPressed: () {
                provider.clearChat();
                provider.addGreeting();
                setState(() => _showSuggestions = true);
              },
            ),
          ),
        ],
      ),
      body: Consumer2<ChatbotProvider, AppProvider>(
        builder: (context, chatProvider, appProvider, _) {
          // Keep Gemini key up-to-date
          if (appProvider.geminiApiKey.isNotEmpty && !chatProvider.isReady) {
            chatProvider.initializeGemini(appProvider.geminiApiKey);
          }

          return Column(
            children: [
              // API key banner if not configured
              if (!chatProvider.isReady)
                _buildApiKeyBanner(context),
              // Messages list
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        itemCount: chatProvider.messages.length +
                            (chatProvider.isTyping ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == chatProvider.messages.length) {
                            return _buildTypingIndicator();
                          }
                          return _MessageBubble(
                              message: chatProvider.messages[i]);
                        },
                      ),
              ),
              // Suggestions
              if (_showSuggestions && chatProvider.messages.length <= 1)
                _buildSuggestions(),
              // Input bar
              _buildInputBar(chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApiKeyBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Configure Gemini API key in Settings to enable AI responses',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to the Settings tab to configure your Gemini API key.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Configure',
                style: TextStyle(color: AppColors.secondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: AppColors.secondary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'AquaVerse.ai',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Ocean Safety Companion',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ChatSuggestions.initial.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final suggestion = ChatSuggestions.initial[i];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => _sendMessage(suggestion),
            backgroundColor: AppColors.cardDark,
            side: const BorderSide(color: AppColors.divider),
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(ChatbotProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: provider.isTyping ? null : _sendMessage,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ask about beach safety, tides, warnings...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.cardDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: provider.isTyping
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: _ThreeDotAnimation(),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.secondary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.divider),
              ),
              child: isUser
                  ? SelectableText(
                      message.content,
                      cursorColor: Colors.white70,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        em: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        code: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        listBullet: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      selectable: true,
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThreeDotAnimation extends StatefulWidget {
  @override
  State<_ThreeDotAnimation> createState() => _ThreeDotAnimationState();
}

class _ThreeDotAnimationState extends State<_ThreeDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
          final scale = 0.5 + 0.5 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6 * scale + 2,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.5 + 0.5 * scale),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
