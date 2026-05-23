import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

/// Singleton wrapper around Firebase Auth + Firestore.
/// All methods are silent-fail — if Firebase is unavailable the app
/// continues working using local SharedPreferences as the source of truth.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  // ─────────────────────────────────────────────
  // Auth
  // ─────────────────────────────────────────────

  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // No internet or auth disabled — silently continue
    }
  }

  // ─────────────────────────────────────────────
  // Chat History
  // ─────────────────────────────────────────────

  Future<void> saveChatMessage(ChatMessage message) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .add(message.toMap());
    } catch (_) {}
  }

  Future<List<ChatMessage>> loadChatHistory({int limit = 100}) async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .orderBy('timestamp')
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearChatHistory() async {
    final uid = userId;
    if (uid == null) return;
    try {
      // Firestore batch limit is 500 — cap at 500 for safety
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Location Search History
  // ─────────────────────────────────────────────

  Future<void> logLocationSearch(String locationName) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('search_history')
          .add({
        'location': locationName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<List<String>> loadSearchHistory({int limit = 50}) async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => doc.data()['location'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Favourites
  // ─────────────────────────────────────────────

  Future<void> saveFavorites(List<String> favorites) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'favorites': favorites,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<List<String>> loadFavorites() async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['favorites'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Risk Event Logs (global, for analytics)
  // ─────────────────────────────────────────────

  Future<void> logRiskEvent({
    required String location,
    required String riskLevel,
    required List<String> activeWarnings,
  }) async {
    try {
      await _db.collection('risk_logs').add({
        'location': location,
        'riskLevel': riskLevel,
        'activeWarnings': activeWarnings,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // User Settings Sync
  // ─────────────────────────────────────────────

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'settings': settings,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final uid = userId;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['settings'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
