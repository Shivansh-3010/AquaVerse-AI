class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        content: map['content'] as String? ?? '',
        isUser: map['isUser'] as bool? ?? false,
        timestamp: map['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
            : DateTime.now(),
      );
}

/// Pre-defined quick suggestion chips for the chatbot
class ChatSuggestions {
  static const List<String> initial = [
    'Is it safe to swim today?',
    'What are the current tide times?',
    'Explain the wave warnings',
    'Best beaches near me?',
    'What is a swell surge?',
    'How do I read the risk levels?',
  ];
}
