# AquaVerse — AI-Powered Beach Safety & Ocean Intelligence

> Real-time beach safety powered by INCOIS ocean data + Google Gemini AI  
> Final Year Engineering Capstone Project · Version 1.0.0

---

## What is AquaVerse?

AquaVerse is a Flutter mobile app that keeps coastal users safe by aggregating live ocean data from INCOIS (Indian National Centre for Ocean Information Services) into an easy-to-understand risk dashboard. It tells you whether it is safe to swim, surf, fish, or dive — right now, and in the next 2 / 6 / 12 hours.

**Target Users:** Swimmers, surfers, fishermen, tourists, and coastal community members across India, Sri Lanka, Bangladesh, Myanmar, and Pakistan.

---

## Core Features

| Feature | Description |
|---|---|
| **Live Risk Dashboard** | SAFE / MODERATE / HIGH / DANGER assessment from 5 INCOIS warning feeds |
| **5 Warning Types** | Tsunami, Storm Surge, High Wave, Swell Surge, Coastal Currents |
| **AI Risk Forecast** | Rule-based ML predicts risk at +2h, +6h, +12h using tide & warning data |
| **Tide Chart** | 24h tidal forecast as a line chart; next High/Low tide times & heights |
| **Coastal Watch Map** | OpenStreetMap with ~160 Indian Ocean stations, colour-coded by risk |
| **Water Quality** | pH, salinity, temperature, dissolved oxygen, turbidity, chlorophyll (Kochi & Vizag) |
| **AquaVerse.ai Chatbot** | Gemini-powered ocean safety assistant with live context injection |
| **Smart Recommendation** | Suggests nearest safe beach when current area has elevated risk |
| **Push Notifications** | Alerts for active warnings, risk escalation, and advance predictions |
| **Favourites & Cloud Sync** | Firebase Firestore syncs favourites and settings across devices |

---

## Tech Stack

```
Flutter 3.x  (Dart SDK >=3.0.0 <4.0.0)

State Management    provider: ^6.1.2
HTTP                http: ^1.2.1
Maps                flutter_map: ^6.1.0 (OpenStreetMap, no API key needed)
Charts              fl_chart: ^0.68.0
Location            geolocator: ^11.0.0
Storage             shared_preferences: ^2.3.0
Firebase            firebase_core + firebase_auth + cloud_firestore
Notifications       flutter_local_notifications: ^17.2.2
AI Chatbot          google_generative_ai: ^0.4.3 (Gemini)
Utilities           intl, shimmer, url_launcher, percent_indicator
```

---

## Project Structure

```
AquaVerse_AI/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── app.dart                     ← MaterialApp + theme + root widget
│   ├── firebase_options.dart        ← Auto-generated Firebase config
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart   ← All INCOIS API URLs + SharedPrefs keys
│   │   │   └── app_colors.dart      ← Ocean colour palette (deep blue theme)
│   │   ├── theme/
│   │   │   └── app_theme.dart       ← Global dark MaterialTheme
│   │   └── utils/
│   │       ├── location_utils.dart  ← Haversine distance + safe beach finder
│   │       ├── risk_calculator.dart ← Warning → RiskLevel enum mapper
│   │       └── risk_predictor.dart  ← Rule-based ML for 2h/6h/12h forecast
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── beach_location_model.dart   ← Station name + lat/lon + risk
│   │   │   ├── warning_model.dart          ← ThreatLevel enum + WarningData
│   │   │   ├── tide_model.dart             ← TideDataPoint, HighLowTide
│   │   │   ├── water_quality_model.dart    ← WaterQualityData (8 parameters)
│   │   │   └── chat_message_model.dart     ← ChatMessage for Gemini chat
│   │   ├── providers/
│   │   │   ├── app_provider.dart    ← Master ChangeNotifier (all data state)
│   │   │   └── chatbot_provider.dart← Chat state, Gemini session management
│   │   └── services/
│   │       ├── incois_service.dart  ← HTTP calls to INCOIS REST API
│   │       ├── gemini_service.dart  ← Google Generative AI chat session
│   │       ├── firebase_service.dart← Singleton: Auth + Firestore CRUD
│   │       └── notification_service.dart ← Local push notifications
│   │
│   └── presentation/
│       ├── screens/
│       │   ├── splash_screen.dart       ← 3s animated splash → MainNavigation
│       │   ├── main_navigation.dart     ← BottomNavigationBar shell (5 tabs)
│       │   ├── home/home_screen.dart    ← Map background + draggable panel
│       │   ├── map/map_screen.dart      ← Full map + search + location sheet
│       │   ├── warnings/warnings_screen.dart  ← Tabbed warning detail view
│       │   ├── chatbot/chatbot_screen.dart     ← Gemini chat UI
│       │   ├── beach_detail/beach_detail_screen.dart ← Tide + WQ + safety tips
│       │   └── settings/settings_screen.dart  ← API keys + preferences
│       └── widgets/
│           ├── risk_level_card.dart     ← Reusable coloured risk banner
│           ├── warning_card.dart        ← Expandable warning tile
│           ├── tide_chart_widget.dart   ← fl_chart line chart
│           └── water_quality_card.dart  ← Parameter grid
│
├── assets/
│   └── data/tide_locations.json    ← ~160 pre-bundled INCOIS station coords
│
├── android/app/google-services.json ← Firebase Android config
└── pubspec.yaml
```

---

## App Flow — Step by Step

### Boot sequence

```
main()
  ├─ Flutter binding, portrait lock, status bar style
  ├─ Firebase.initializeApp()
  ├─ NotificationService.initialize()     [Android only]
  └─ runApp → MultiProvider(AppProvider, ChatbotProvider)
                └─ AquaVerseApp → SplashScreen

SplashScreen (3 seconds)
  └─ FadeTransition → MainNavigation

MainNavigation.initState() [postFrameCallback]
  ├─ AppProvider.initialize()
  │     ├─ FAST (sync): SharedPreferences + bundled JSON → notifyListeners()
  │     └─ BACKGROUND: Firebase anon auth → Firestore sync → GPS → INCOIS fetch
  └─ ChatbotProvider.initializeGemini(key from AppProvider)
```

### Data refresh cycle (AppProvider.refreshAll)

```
refreshWarnings()
  ├─ 5 parallel INCOIS calls (tsunami, stormsurge, highwave, swellsurge, currents)
  ├─ RiskCalculator.calculate() → RiskAssessment
  ├─ RiskPredictor.predict()    → List<RiskPrediction> (2h/6h/12h)
  ├─ Assign riskLevel to all beach locations
  ├─ LocationUtils.findSafeAlternative() → BeachRecommendation
  ├─ NotificationService → push alerts (warnings + escalation + predictions)
  └─ FirebaseService.logRiskEvent() → analytics

refreshTideData(location)
  └─ INCOIS tidal + high-low endpoints → TideLocationData
```

### Chatbot message flow

```
User types → ChatbotProvider.sendMessage(text, liveContext)
  ├─ AppProvider.liveContextSummary injected (location, risk, tide, warnings)
  ├─ Firestore: save user message
  ├─ GeminiService.sendMessage(payload)
  │     └─ Model fallback chain: flash-latest → flash-8b → pro-latest → pro
  ├─ Firestore: save AI response
  └─ UI rebuilds via Consumer<ChatbotProvider>
```

---

## Screens Explained

### Home Screen (`home_screen.dart`)
Full-screen OpenStreetMap + draggable bottom panel.

- **Top overlay** — app name, current location, live time, risk badge
- **Map** — dark-tinted OSM tiles; up to 25 nearest stations colour-coded; user GPS dot
- **FABs** — Refresh data, Centre on my location
- **Draggable panel** snaps to 16% / 38% / 88% height:
  - Quick stats: Tide height, Sea temp, Active alerts, Current speed
  - **Risk Level Card** — coloured banner with recommendation text
  - **Smart Recommendation** — nearest safe beach when risk is elevated (tappable)
  - **Nearby Locations** — 3 closest stations with distance + risk badge (tappable)
  - **AI Risk Forecast** — 2h / 6h / 12h prediction tiles with confidence %
  - **Early Warnings** — active cards or "All Clear" state
  - **Tide Forecast** — mini 24h line chart

### Map Screen (`map_screen.dart`)
Interactive map with all ~160 stations.

- Search bar filters stations by name in real-time
- Tap marker → bottom sheet with station info → "View" → BeachDetailScreen
- Risk legend always visible bottom-right

### Warnings Screen (`warnings_screen.dart`)
Tabbed: All | Tsunami | Storm Surge | High Wave | Swell Surge | Coastal Currents

- Summary card with active count and risk colour
- Educational explanation card per warning type
- Pull-to-refresh on all tabs

### AquaVerse.ai Chatbot (`chatbot_screen.dart`)
Gemini-powered chat with live ocean context.

- Requires Gemini API key (free, from aistudio.google.com)
- Live conditions (risk, tide, temp, active warnings, predictions) injected into every prompt
- Chat history persisted to Firestore per anonymous user
- Quick-suggestion chips shown on first open
- Banner prompt if Gemini key not configured

### Beach Detail Screen (`beach_detail_screen.dart`)
Pushed when tapping any station on Home or Map.

- Collapsing hero header with name, coordinates, region
- Favourite heart toggle synced to Firestore
- Full 24h tide chart
- High/Low tide times table for the day
- Water Quality grid (live for Kochi & Vizag; demo data for all others)
- 5 safety guidelines
- Station info card (coordinates, data source credit)

### Settings Screen (`settings_screen.dart`)
- INCOIS API Key (obscured text field)
- Gemini API Key (obscured text field)
- Default location picker (searchable bottom sheet from all ~160 stations)
- Master notifications toggle + 5 per-type toggles
- Favourites list
- About section

---

## API Reference

### INCOIS REST API

```
Base: https://gemini.incois.gov.in/incoisapi/rest
Base: https://gemini.incois.gov.in/OceanDataAPI/api
```

| Endpoint | Auth | Notes |
|---|---|---|
| `GET /tidal/{location}` | No | Hourly tide heights for 48h |
| `GET /high-low/{location}` | No | Next High/Low tide events |
| `GET /tsunami` | Yes | Tsunami warning GeoJSON |
| `GET /stormsurgelatest` | Yes | Storm surge warning GeoJSON |
| `GET /hwalatestgeo` | Yes | High wave alert GeoJSON |
| `GET /ssalatestgeo` | Yes | Swell surge alert GeoJSON |
| `GET /currentslatestgeo` | Yes | Coastal current alert GeoJSON |
| `GET /wqns/{station}/{param}` | Yes | Water quality nowcast |

**Auth header:** `Authorization: <your-key>` (no "Bearer" prefix)

**Warning colour → risk mapping:**

| INCOIS Colour | ThreatLevel | Resulting RiskLevel |
|---|---|---|
| GREEN | noThreat | SAFE |
| YELLOW | watch | MODERATE |
| ORANGE | alert | HIGH (most types) |
| RED | warning | DANGER (tsunami/storm), HIGH (wave) |

### Water Quality Parameters
`currentspeed`, `currentdirection`, `ph`, `salinity`, `temperature`,
`dissolvedoxygen`, `chlorophyll`, `turbidity`

Water quality is **only available** for stations: `Kochi`, `Vizag`.  
All other stations display demo data.

---

## Risk Calculation Logic

**RiskCalculator** — deterministic priority chain:

```
Tsunami WARNING      → DANGER
Storm Surge WARNING  → DANGER
Tsunami ALERT        → HIGH
Storm Surge ALERT    → HIGH
High Wave WARNING    → HIGH
High Wave WATCH/ALERT → MODERATE
Swell Surge (any)    → MODERATE
Coastal Current (any) → MODERATE
```

Final level = highest triggered. Severity cannot decrease.

**RiskPredictor** — weighted score model (0.0 – 1.0):

```
Feature                         Max contribution
Tide height > 2.0m              +0.25
Tide height > 1.5m              +0.15
Upcoming high tide > 2.2m       +0.20
Tsunami WARNING                 +0.40
Storm Surge WARNING             +0.35
High Wave WARNING               +0.30
Swell Surge WARNING             +0.20
Coastal Current WARNING         +0.15
Night time (22:00–05:00)        +0.05
Decay factor (farther = lower)  ×(1.0 - hours/24 × 0.2)

Score → Level:  ≥0.65 DANGER  |  ≥0.40 HIGH  |  ≥0.20 MODERATE  |  else SAFE
Confidence:     100% at 0h → 70% at 12h (linear)
```

---

## Setup Instructions

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.x (Dart ≥3.0.0) |
| Android Studio / VS Code | Latest |
| Java | 11 or 17 |
| Android emulator or device | API 21+ |

### 1. Clone and install

```bash
git clone <repo-url>
cd AquaVerse_AI
flutter pub get
```

### 2. Firebase setup

The repo ships with a pre-configured `android/app/google-services.json` for the original project.

To use your own Firebase project:
1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.aquaverse.app`
3. Download `google-services.json` → replace `android/app/google-services.json`
4. Enable **Anonymous Authentication** in Firebase → Authentication
5. Enable **Cloud Firestore** in Firebase → Firestore Database (Start in test mode)
6. Regenerate `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 3. Get API keys

#### INCOIS API Key
- Register at [incois.gov.in](https://incois.gov.in) (look for API registration)
- Enter the key in the app: Settings → INCOIS API Key
- Tidal data works **without** a key. All 5 warning feeds require it.

#### Gemini API Key (free)
- Visit [aistudio.google.com](https://aistudio.google.com) → Get API key
- No billing required on the free tier
- Enter in the app: Settings → Gemini API Key

### 4. Run

```bash
# Debug (Android emulator or device)
flutter run

# Target a specific device
flutter devices
flutter run -d <device-id>

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

> The app enforces **portrait orientation** on mobile. Web is supported but push notifications are disabled on web.

---

## Configuration Reference

All config is entered in-app (Settings screen) and stored in `SharedPreferences`. No `.env` files.

| SharedPrefs Key | Set via | Unlocks |
|---|---|---|
| `incois_api_key` | Settings | 5 warning data types |
| `gemini_api_key` | Settings | AquaVerse.ai chatbot |
| `default_location` | Settings + Firestore sync | Default tide chart location |
| `notifications_enabled` | Settings | Master notification toggle |
| `notif_tsunami` etc. | Settings | Per-type notification toggles |
| `favorite_locations` | Heart tap on beach | Favourites list |

**API keys are never sent to Firestore.** Only `defaultLocation` and `notificationsEnabled` sync to the cloud.

---

## Push Notification Channels (Android)

| Channel | Trigger |
|---|---|
| `aquaverse_warnings` | Any INCOIS warning with threat level > noThreat |
| `aquaverse_risk` | Risk level escalates (e.g. SAFE → HIGH) |
| `aquaverse_predictions` | 6h or 12h forecast ≥ HIGH (max once per hour) |
| `aquaverse_reminders` | Manual safety check-in reminder |

> **iOS notifications are not configured** in this codebase. No `UNUserNotificationCenter` setup exists.

---

## Architecture & Design Patterns

### Layer diagram

```
┌─────────────────────────────────────────────────────┐
│  Presentation (Screens + Widgets)                   │
│  Consumer<AppProvider>  Consumer<ChatbotProvider>   │
└───────────────────┬─────────────────────────────────┘
                    │ reads state, calls methods
┌───────────────────▼─────────────────────────────────┐
│  Providers (ChangeNotifier)                         │
│  AppProvider          ChatbotProvider               │
└──────┬───────────────────────────┬──────────────────┘
       │ calls                     │ calls
┌──────▼──────┐  ┌───────────┐  ┌─▼────────────┐
│IncoisService│  │FirebaseSvc│  │GeminiService │
└──────┬──────┘  └─────┬─────┘  └─────┬────────┘
       │               │              │
   INCOIS API      Firestore      Gemini API
```

### State management
**Provider / ChangeNotifier** — two providers at root level.  
All UI rebuilds happen inside `Consumer<T>` wrappers, not `context.watch` in `build()`.

### Firebase design
`FirebaseService` is a **singleton** with silent-fail on every method.  
If Firebase is unavailable, the app continues from local `SharedPreferences` without crashing.

### Demo data fallback
Every INCOIS call has a silent-fail path:
- Warnings → `WarningData.noThreat(...)` (all-clear state)
- Tide data → realistic sine-wave mock (12.4h semi-diurnal cycle)
- Water quality → `WaterQualityData.demo(station)` (typical Indian Ocean values)

---

## Known Issues & Limitations

| Issue | Impact | Fix |
|---|---|---|
| API keys stored in plain SharedPreferences | Security risk on rooted devices | Use `flutter_secure_storage` |
| iOS push notifications not configured | iOS users get no alerts | Add `UNUserNotificationCenter` in `AppDelegate.swift` |
| `google-services.json` committed to git | Firebase keys exposed in repo | Gitignore it; inject via CI |
| Release build uses debug keystore | APK cannot be published to Play Store | Create a proper release keystore |
| Water quality limited to Kochi & Vizag | All other stations show demo data | INCOIS API limitation; document clearly in UI |
| No periodic background refresh | Data only refreshes on app open or manual pull | Add `workmanager` for background polling |
| Risk score accumulation bug in `RiskPredictor` | Warning contributions may not stack correctly | Use local accumulator in `_applyWarningFactor` |
| No offline banner | User doesn't know they're seeing demo data | Add a visible "demo data" indicator |

---

## Improvement Roadmap

**High priority**
1. Replace `SharedPreferences` API key storage with `flutter_secure_storage`
2. Configure iOS notification permissions (`UNUserNotificationCenter`)
3. Add background refresh with `workmanager`
4. Fix risk score accumulation in `RiskPredictor._applyWarningFactor`

**Medium priority**
5. Add shimmer loading skeletons (package already installed, unused)
6. Add a `Repository` layer between providers and services
7. Write unit tests for `RiskCalculator`, `RiskPredictor`, `LocationUtils`
8. Add an "offline / demo data" banner in the UI

**Nice to have**
9. Support more water quality stations when INCOIS adds them
10. Extend tide forecast beyond 48h
11. Web PWA notification support via Firebase Cloud Messaging

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| All warnings show "No Threat" | No INCOIS API key | Settings → Enter INCOIS API Key |
| AquaVerse.ai shows setup instructions | No Gemini API key | Settings → Enter Gemini API Key |
| "Using demo data" banner appears | INCOIS unreachable or wrong key | Check internet; verify key in Settings |
| Map has no markers | JSON asset not loaded | Ensure `assets/data/tide_locations.json` is in `pubspec.yaml` |
| Firebase errors on startup | Mismatched `google-services.json` | Verify file matches your Firebase project |
| Notifications not working (Android) | System permission not granted | App Settings → Notifications → Allow |
| Build fails on `desugar_jdk_libs` | Gradle cache stale | `cd android && ./gradlew clean && cd .. && flutter run` |
| Water quality always shows demo data | Station not Kochi or Vizag | Expected; INCOIS WQNS API only supports those two |

---

## Data Attribution

- **Ocean Data**: [INCOIS](https://incois.gov.in) — Indian National Centre for Ocean Information Services, Ministry of Earth Sciences, Government of India
- **Maps**: © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright)
- **AI Chatbot**: Powered by [Google Gemini](https://ai.google.dev)

---

*AquaVerse is a capstone project for Final Year Engineering. It provides real-time beach safety information using INCOIS ocean data for educational and safety awareness purposes.*


## PPT Link 

https://gamma.app/docs/AquaVerse-4b54t2zvkasfqkz
