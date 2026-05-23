import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _initialized = false;
  String _apiKey = '';
  int _modelIndex = 0;

  // Groq fallback state
  String _groqApiKey = '';
  final List<Map<String, String>> _groqHistory = [];
  bool _usingGroq = false;

  // Model list confirmed from ListModels response for this project.
  // gemini-1.5-x models are not available in newer AI Studio projects.
  static const List<String> _models = [
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  static const String _systemPrompt = '''
You are AquaVerse.ai, the intelligent ocean safety assistant for the AquaVerse mobile app.

Your role:
- Help users understand beach and ocean safety based on INCOIS (Indian National Centre for Ocean Information Services) data
- Explain risk levels, tide data, wave warnings, storm surges, and water quality parameters
- Provide personalized safety recommendations for coastal activities
- Educate users about ocean phenomena

Key guidelines:
- Always prioritize user safety above all else
- When warnings are active (especially RED/WARNING level), strongly advise against water activities
- Be friendly, concise, and use ocean-themed language naturally
- Cite INCOIS as the data source when relevant
- If asked about current conditions, remind users that real-time data is shown in the app's dashboard

INCOIS Warning Levels:
- GREEN (No Threat): Conditions favorable, normal activities possible
- YELLOW (Watch): Developing situation, monitor closely
- ORANGE (Alert): Hazardous conditions likely, exercise extreme caution
- RED (Warning): Life-threatening conditions, stay away from water

Common beach activities you can advise on: swimming, surfing, fishing, snorkeling, diving, kayaking, beachwalking

Always end safety-critical advice with: "Always follow local authority and lifeguard instructions."
''';

  bool get isReady => _initialized || _groqApiKey.isNotEmpty;
  bool get usingGroq => _usingGroq;

  void initialize(String apiKey) {
    if (apiKey.trim().isEmpty) {
      _initialized = false;
      return;
    }
    try {
      _apiKey = apiKey.trim();
      _modelIndex = 0;
      _usingGroq = false;
      _model = _buildModel(_models[_modelIndex]);
      _chatSession = _model!.startChat();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  void setGroqKey(String key) {
    _groqApiKey = key.trim();
    if (_groqApiKey.isNotEmpty && !_initialized) {
      _usingGroq = true;
    }
  }

  GenerativeModel _buildModel(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
      ),
    );
  }

  Future<String> sendMessage(String userMessage, {String? liveContext}) async {
    final payload = (liveContext != null && liveContext.isNotEmpty)
        ? '[LIVE OCEAN CONDITIONS — use this for context only, do not repeat it verbatim]\n'
            '$liveContext\n'
            '[USER QUESTION]\n$userMessage'
        : userMessage;

    // Route to Groq if Gemini is not configured but Groq key is set
    if (!_initialized && _groqApiKey.isNotEmpty) {
      return _sendViaGroq(userMessage, liveContext: liveContext);
    }

    if (!_initialized || _chatSession == null) {
      if (_groqApiKey.isEmpty) {
        return "AquaVerse.ai is not configured yet.\n\n"
            "To enable the AI chatbot, go to **Settings → API Configuration** and enter either:\n"
            "• **Gemini API key** — free from [aistudio.google.com](https://aistudio.google.com)\n"
            "• **Groq API key** — free from [console.groq.com](https://console.groq.com) (recommended, no quota issues)\n\n"
            "The rest of the app works without an API key.";
      }
      return _sendViaGroq(userMessage, liveContext: liveContext);
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(payload));
      return response.text ?? "I couldn't generate a response. Please try again.";
    } on GenerativeAIException catch (e) {
      if (e.message.contains('API_KEY_INVALID') ||
          e.message.contains('API key not valid')) {
        _initialized = false;
        if (_groqApiKey.isNotEmpty) {
          _usingGroq = true;
          return _sendViaGroq(userMessage, liveContext: liveContext);
        }
        return "Invalid Gemini API key. Please check your key in Settings, or add a Groq API key as an alternative.";
      }
      // Quota / model unavailable — try next Gemini model, then fall back to Groq
      if ((e.message.contains('not found') ||
              e.message.contains('not supported') ||
              e.message.contains('RESOURCE_EXHAUSTED') ||
              e.message.contains('quota') ||
              e.message.contains('Quota') ||
              e.message.contains('exceeded')) &&
          _modelIndex < _models.length - 1) {
        _modelIndex++;
        _model = _buildModel(_models[_modelIndex]);
        _chatSession = _model!.startChat();
        try {
          final response =
              await _chatSession!.sendMessage(Content.text(payload));
          return response.text ??
              "I couldn't generate a response. Please try again.";
        } catch (_) {}
      }
      // All Gemini models exhausted — try Groq
      if (_groqApiKey.isNotEmpty) {
        _usingGroq = true;
        return _sendViaGroq(userMessage, liveContext: liveContext);
      }
      return "Gemini quota reached. Add a Groq API key in Settings for uninterrupted chat (free at console.groq.com).";
    } catch (_) {
      if (_groqApiKey.isNotEmpty) {
        return _sendViaGroq(userMessage, liveContext: liveContext);
      }
      return "Something went wrong. Please check your internet connection and try again.";
    }
  }

  Future<String> _sendViaGroq(String userMessage,
      {String? liveContext}) async {
    if (_groqApiKey.isEmpty) {
      return "Groq API key not configured. Please add it in Settings.";
    }

    final userContent = (liveContext != null && liveContext.isNotEmpty)
        ? '[LIVE OCEAN CONDITIONS — use this for context only]\n$liveContext\n[USER QUESTION]\n$userMessage'
        : userMessage;

    _groqHistory.add({'role': 'user', 'content': userContent});

    // Keep history to last 20 turns to stay within token limits
    if (_groqHistory.length > 20) {
      _groqHistory.removeRange(0, _groqHistory.length - 20);
    }

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._groqHistory,
    ];

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.groqChatUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': ApiConstants.groqModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            data['choices']?[0]?['message']?['content'] as String? ?? '';
        if (text.isNotEmpty) {
          _groqHistory.add({'role': 'assistant', 'content': text});
          return text;
        }
        return "I couldn't generate a response. Please try again.";
      } else if (response.statusCode == 401) {
        return "Invalid Groq API key. Please check your key in Settings.";
      } else if (response.statusCode == 429) {
        return "Groq rate limit reached. Please wait a moment and try again.";
      } else {
        return "Groq error (${response.statusCode}). Please try again.";
      }
    } catch (_) {
      return "Unable to reach Groq. Please check your internet connection.";
    }
  }

  void resetSession() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
    _groqHistory.clear();
  }
}
