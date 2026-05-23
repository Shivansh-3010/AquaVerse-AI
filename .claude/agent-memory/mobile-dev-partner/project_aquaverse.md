---
name: AquaVerse Project Details
description: Full technical profile of the AquaVerse Flutter capstone project — stack, structure, platform targets, known issues, and improvement areas
type: project
---

AquaVerse is a Flutter (Dart) Android beach safety app at E:\capstone. Final year capstone 2024-25.

**Why:** Instructor demo requires an Android APK. Daily iteration goal is Flutter Web preview on Windows PC.

**How to apply:** When suggesting features or fixes, always keep in mind the dual goal: APK for demo, web for fast iteration. Verify plugin web compatibility before recommending new packages.

## Core Stack
- Flutter 3.x / Dart 3.x, Provider + ChangeNotifier state management
- Firebase: Auth (anonymous), Firestore (chat history, favorites, risk logs), no FCM yet
- INCOIS REST API for all ocean data (tides, 5 warning types, water quality)
- Google Gemini 2.0 Flash via google_generative_ai package (user supplies own API key)
- flutter_map + OpenStreetMap (no API key needed)
- fl_chart for tide waveform charts
- geolocator for GPS (has web + windows support via geolocator_web / geolocator_windows)
- flutter_local_notifications — ANDROID ONLY, guarded with kIsWeb check
- geocoding package — declared in pubspec.yaml but NOT USED anywhere in lib/

## Architecture: Clean 6-layer
core/ → constants, theme, utils (RiskCalculator, RiskPredictor, LocationUtils)
data/ → models, services (IncoisService, GeminiService, NotificationService, FirebaseService), providers (AppProvider, ChatbotProvider)
presentation/ → screens (5 tabs via BottomNav), widgets

## Platform Targets
- android/ folder: YES, fully configured with google-services.json
- web/ folder: YES, basic scaffold exists (index.html, manifest.json, icons/)
- ios/ folder: NO (not present)
- windows/ folder: NO (not present)
- firebase_options.dart has Android config + web config stub (web keys are REPLACE_WITH placeholders)

## Web Blockers (for flutter run -d chrome)
1. firebase_options.dart web config has placeholder apiKey/appId — must run `flutterfire configure` to fill real values, OR manually add web app in Firebase Console and paste keys
2. flutter_local_notifications: already guarded with kIsWeb check — NOT a blocker
3. geocoding: declared but unused — NOT a blocker
4. geolocator: has geolocator_web — NOT a blocker
5. SystemChrome.setPreferredOrientations: already guarded with !kIsWeb — NOT a blocker
6. firebase_auth_web and firebase_core_web are in pubspec.lock — Firebase web support IS present

## Known Bugs / Issues Found
- risk_predictor.dart _applyWarningFactor: uses a setter callback pattern but `current` parameter is passed by value, not captured by reference — the setter IS used correctly via the lambda, but the variable `riskScore` in _predictWindow is local. This is actually correct Dart — the setter mutates the local via closure. No bug here.
- AppProvider.appBarTheme uses deprecated .withOpacity() extensively (Flutter 3.27+ deprecates Color.withOpacity in favor of Color.withValues()) — affects all files. Low priority for capstone.
- home_screen.dart: _buildMarkers uses `List<dynamic> locs` instead of `List<BeachLocation>` — untyped cast. Minor.
- main_navigation.dart: chatbot greeting fires twice (once in initState via addGreeting(), once via addPostFrameCallback). addGreeting() has an `if (messages.isEmpty) return` guard so it's harmless but redundant.
- settings_screen.dart: "Configure" button in chatbot API key banner has empty onPressed (just a comment, no navigation). Dead code.
- Chatbot greeting contains emoji (wave emoji) — minor, cosmetic.

## Features Implemented
Home: full-screen OSM map + draggable bottom panel (risk card, stats row, predictions, warnings, mini tide chart)
Map: dedicated map screen
Warnings: 5-tab INCOIS warning detail view
BeachDetail: tide chart, high/low tides, water quality grid (12 params), safety tips, station info, favorite toggle
Chatbot: Gemini 2.0 Flash with live ocean context injection, Firebase chat history, typing animation
Settings: API key management, default location picker, per-type notification toggles, favorites management

## Future Features Documented in ARCHITECTURE.md
- Server-side FCM push via Firebase Cloud Functions
- Enhanced multi-criteria recommendation engine (distance 30% + risk 40% + 6h forecast 20% + WQ 10%)
- SQLite local DB for historical warning/tide/WQ logs
- Ecological zone GeoJSON overlay on map
