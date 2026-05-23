import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';

class ChatbotProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _error;
  bool _historyLoaded = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get error => _error;
  bool get isReady => _geminiService.isReady;

  void initializeGemini(String apiKey) {
    _geminiService.initialize(apiKey);
    notifyListeners();
  }

  void setGroqKey(String apiKey) {
    _geminiService.setGroqKey(apiKey);
    notifyListeners();
  }

  bool get usingGroq => _geminiService.usingGroq;

  /// Loads the last 100 messages from Firestore on first open.
  Future<void> loadHistoryIfNeeded() async {
    if (_historyLoaded) return;
    _historyLoaded = true;
    final history = await _firebaseService.loadChatHistory();
    if (history.isNotEmpty && _messages.isEmpty) {
      _messages.addAll(history);
      notifyListeners();
    }
  }

  void addGreeting() {
    if (_messages.isNotEmpty) return;
    _messages.add(ChatMessage(
      content: "Hello! I'm AquaVerse.ai 🌊\n\n"
          "I'm your intelligent ocean safety companion, powered by INCOIS data and Google Gemini AI.\n\n"
          "I can help you with:\n"
          "• Beach safety assessments\n"
          "• Understanding tide patterns\n"
          "• Interpreting wave and storm warnings\n"
          "• Water quality information\n"
          "• Safe coastal activity recommendations\n\n"
          "How can I help you stay safe today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Sends [text] to Gemini. Pass [liveContext] (from AppProvider.liveContextSummary)
  /// so the AI can answer location-aware, conditions-aware questions.
  Future<void> sendMessage(String text, {String? liveContext}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    _error = null;
    notifyListeners();

    // Persist user message to Firestore
    await _firebaseService.saveChatMessage(userMsg);

    try {
      final response = await _geminiService.sendMessage(
        text.trim(),
        liveContext: liveContext,
      );
      final aiMsg = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);

      // Persist AI response to Firestore
      await _firebaseService.saveChatMessage(aiMsg);
    } catch (e) {
      _error = 'Failed to get response. Please try again.';
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    _messages.clear();
    _geminiService.resetSession();
    // Clear Firestore history for this user
    await _firebaseService.clearChatHistory();
    notifyListeners();
  }
}
