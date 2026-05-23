# AquaVerse — System Architecture & Research Documentation

> **AquaVerse: An AI-Powered Intelligent Beach Safety and Ocean Intelligence System**
> Final Year Engineering Capstone | 2024–25
> Flutter (Android) · INCOIS Data · Google Gemini AI

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Defined Objectives](#2-defined-objectives)
3. [Objectives Alignment Analysis](#3-objectives-alignment-analysis)
4. [System Architecture](#4-system-architecture)
   - 4.1 [High-Level Layered Architecture](#41-high-level-layered-architecture)
   - 4.2 [Component Architecture](#42-component-architecture)
   - 4.3 [Data Flow Diagram](#43-data-flow-diagram)
   - 4.4 [Module Interaction Diagram](#44-module-interaction-diagram)
5. [Layer-by-Layer Breakdown](#5-layer-by-layer-breakdown)
   - 5.1 [External Data Sources](#51-external-data-sources)
   - 5.2 [Data Acquisition Layer](#52-data-acquisition-layer)
   - 5.3 [Intelligent Processing Layer](#53-intelligent-processing-layer)
   - 5.4 [State Management Layer](#54-state-management-layer)
   - 5.5 [Persistence Layer](#55-persistence-layer)
   - 5.6 [Presentation Layer](#56-presentation-layer)
6. [Data Models](#6-data-models)
7. [Risk Assessment Engine](#7-risk-assessment-engine)
8. [Risk Prediction Engine](#8-risk-prediction-engine)
9. [Intelligent Recommendation System](#9-intelligent-recommendation-system)
10. [AI Chatbot — AquaVerse.ai](#10-ai-chatbot--aquaverseai)
11. [Notification System](#11-notification-system)
12. [Scoped Future Features Architecture](#12-scoped-future-features-architecture)
    - 12.1 [Feature 1: Server-Side Personalized Push Notifications](#121-feature-1-server-side-personalized-push-notifications)
    - 12.2 [Feature 2: Enhanced Intelligent Recommendation Engine](#122-feature-2-enhanced-intelligent-recommendation-engine)
    - 12.3 [Feature 3: Data Persistence — Database Layer](#123-feature-3-data-persistence--database-layer)
13. [Objectives Traceability Matrix](#13-objectives-traceability-matrix)
14. [Technology Stack](#14-technology-stack)
15. [API Reference](#15-api-reference)
16. [Project File Structure](#16-project-file-structure)

---

## 1. Project Overview

**AquaVerse** is an AI-powered Android mobile application designed to deliver real-time beach safety intelligence, ocean condition monitoring, and personalized risk guidance to tourists, coastal communities, and maritime authorities. The application integrates authoritative ocean data from the **Indian National Centre for Ocean Information Services (INCOIS)**, a body under the Ministry of Earth Sciences, Government of India, with a conversational AI assistant powered by **Google Gemini 2.0 Flash**.

The system is built with **Flutter 3.x** (Dart), targeting Android devices (API 21+), and covers **170+ INCOIS tide monitoring stations** across the Indian coastline and surrounding regions.

### Core Capabilities

| Capability | Description |
|---|---|
| Real-time Early Warnings | Tsunami, Storm Surge, High Wave, Swell Surge, Coastal Current advisories |
| Tidal Intelligence | 24-hour tide forecasts, High/Low tide predictions, visual waveform chart |
| Risk Assessment | Multi-factor rule-based engine → SAFE / MODERATE / HIGH / DANGER levels |
| Risk Prediction | 2-hour, 6-hour, 12-hour forecast windows with confidence scores |
| Water Quality Monitoring | pH, Temperature, Salinity, Dissolved Oxygen, Chlorophyll, Turbidity, pCO₂ |
| Geospatial Map | Interactive OpenStreetMap with 170+ color-coded station markers |
| Recommendation Engine | Nearest safe beach detection using Haversine distance + risk state |
| AI Safety Assistant | Conversational chatbot with ocean safety domain context |
| Push Notifications | Selective per-warning-type alerts with user preference controls |

---

## 2. Defined Objectives

The following five objectives formally define the scope and purpose of AquaVerse:

**O1 — Enhanced Tourist Safety**
Real-time alerts and risk predictions reduce accidents and drowning incidents at beaches.

**O2 — Data-Driven Tourism**
AI-based insights help tourists plan safe and enjoyable beach visits.

**O3 — Environmental Protection**
Reduces human interference in unsafe or ecologically sensitive coastal areas.

**O4 — Economic Benefits**
Boosts tourism revenue by enabling safe visits and reduces emergency response costs.

**O5 — Informed Decision-Making**
Provides authorities and users with actionable, evidence-based data for managing coastal activities.

---

## 3. Objectives Alignment Analysis

This section maps each defined objective to its implementation in the current codebase, identifies gaps, and specifies the proposed enhancements that close those gaps.

### O1 — Enhanced Tourist Safety

**Implemented:**
- Five parallel INCOIS warning streams polled on every app refresh (`IncoisService`)
- `RiskCalculator` scores threat level using a priority-weighted algorithm (Tsunami > Storm Surge > High Wave > Swell Surge > Coastal Current)
- Color-coded risk levels: GREEN (Safe), YELLOW (Moderate), ORANGE (High), RED (Danger)
- Push notifications via `NotificationService` with per-type user preference toggles
- Risk level displayed prominently on the Home Dashboard via `RiskLevelCard`

**Gap:**
- Notifications fire only when the app is foregrounded or manually refreshed. There is no server-triggered background push mechanism, meaning a user who hasn't opened the app will not receive a warning when conditions deteriorate.

**Proposed Enhancement:**
- Server-side background polling via Firebase Cloud Functions → Firebase Cloud Messaging (FCM) push (see Section 12.1)

---

### O2 — Data-Driven Tourism

**Implemented:**
- `RiskPredictor` generates 2h, 6h, and 12h risk forecasts using a multi-feature rule-based model (tide height, warning state, time-of-day factor, decay factor)
- `GeminiService` integrates Google Gemini 2.0 Flash with a custom ocean safety system prompt for personalized, conversational advice
- `fl_chart` tide waveform chart for visual tide trend understanding
- Water quality grid (12 parameters) per beach station

**Gap:**
- The chatbot operates without awareness of the user's current app state (active warnings, current risk level). Advice cannot be contextually grounded in real-time data unless the user manually describes the situation.
- Risk predictions use a rule-based model; a trained ML model would produce more accurate probabilistic forecasts.

**Proposed Enhancement:**
- Inject current `RiskAssessment` + active `WarningData` into Gemini's prompt context at session start
- Enhanced multi-criteria Recommendation Engine (see Section 12.2)

---

### O3 — Environmental Protection

**Implemented:**
- `RiskCalculator` actively discourages entry into unsafe coastal zones through clear, graduated recommendations
- 170+ INCOIS monitoring station coverage spans the full Indian coastline
- Map markers with risk color-coding visually indicate dangerous zones
- Safety guidelines embedded in every risk level response ("Only experienced swimmers within designated zones")

**Gap:**
- No ecological zone overlay on the map (marine protected areas, turtle nesting zones, coral reef areas). The current system protects users from physical ocean hazards but does not address ecological sensitivity of specific zones.

**Proposed Enhancement (Future Scope):**
- Integrate ecological boundary GeoJSON layers (sourced from MoEFCC / CMFRI) as an optional map overlay

---

### O4 — Economic Benefits

**Implemented:**
- The safety infrastructure indirectly reduces emergency response costs by providing advance warning and deterring unsafe visits
- AI chatbot promotes confident, informed beach tourism by replacing anxiety-driven avoidance with data-grounded decisions

**Gap:**
- No explicit economic/tourism analytics module exists. There is no tracking of app usage patterns, visit counts by beach, or correlation between warnings and tourist behavior.

**Proposed Enhancement (Future Scope):**
- Firebase Firestore remote database for anonymized session and visit analytics (see Section 12.3)
- Authority-facing dashboard to visualize coastal activity patterns vs. risk event frequency

---

### O5 — Informed Decision-Making

**Implemented:**
- Water quality monitoring (12 INCOIS WQNS parameters) per station: pH, Salinity, Temperature, Dissolved Oxygen, Current Speed/Direction, Chlorophyll, Turbidity, Dissolved Methane, pCO₂ Air/Water
- Full warnings dashboard with 5 warning categories in tabbed view
- `BeachRecommendation` object generated when user GPS shows elevated risk — provides nearest safe location, distance, and human-readable reason
- `RiskPrediction` list (2h/6h/12h) available for both home dashboard and beach detail

**Gap:**
- All data is session-only. No historical record of warnings, risk events, or water quality trends is stored. Authorities or researchers cannot query past data through the app.

**Proposed Enhancement:**
- SQLite local database for historical warning logs and tide snapshots (see Section 12.3)
- Firebase Firestore for aggregated, authority-accessible risk event records

---

## 4. System Architecture

### 4.1 High-Level Layered Architecture

AquaVerse follows a **six-layer clean architecture** pattern:

```
╔══════════════════════════════════════════════════════════════════════════╗
║                         EXTERNAL DATA SOURCES                           ║
║                                                                          ║
║   ┌──────────────────────┐  ┌─────────────────┐  ┌───────────────────┐  ║
║   │   INCOIS REST API    │  │  Google Gemini  │  │   OpenStreetMap   │  ║
║   │ gemini.incois.gov.in │  │  2.0 Flash API  │  │   Tile Servers    │  ║
║   │  (Ocean Data / GoI)  │  │  (NLP / AI)     │  │  (No API key)     │  ║
║   └──────────┬───────────┘  └────────┬────────┘  └────────┬──────────┘  ║
╚══════════════╪══════════════════════╪════════════════════╪══════════════╝
               │                      │                    │
╔══════════════▼══════════════════════▼════════════════════▼══════════════╗
║                        DATA ACQUISITION LAYER                           ║
║                                                                          ║
║   ┌─────────────────────────────────────────────────────────────────┐   ║
║   │  IncoisService  •  GeminiService  •  LocationService (GPS)      │   ║
║   └───────────────────────────────┬─────────────────────────────────┘   ║
╚═══════════════════════════════════╪════════════════════════════════════╝
                                    │
╔═══════════════════════════════════▼════════════════════════════════════╗
║                     INTELLIGENT PROCESSING LAYER                        ║
║                                                                          ║
║   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  ║
║   │  RiskCalculator  │  │  RiskPredictor   │  │  RecommendationEngine│  ║
║   └──────────────────┘  └──────────────────┘  └──────────────────────┘  ║
║   ┌──────────────────────────────────────────────────────────────────┐   ║
║   │                    NotificationService                           │   ║
║   └──────────────────────────────────────────────────────────────────┘   ║
╚═══════════════════════════════════╪════════════════════════════════════╝
                                    │
╔═══════════════════════════════════▼════════════════════════════════════╗
║                       STATE MANAGEMENT LAYER                            ║
║                                                                          ║
║   ┌────────────────────────────────────┐  ┌────────────────────────┐    ║
║   │  AppProvider (ChangeNotifier)      │  │  ChatbotProvider       │    ║
║   └────────────────────────────────────┘  └────────────────────────┘    ║
╚═══════════════════════════════════╪════════════════════════════════════╝
                                    │
╔═══════════════════════════════════▼════════════════════════════════════╗
║                          PERSISTENCE LAYER                              ║
║                                                                          ║
║   ┌──────────────────────┐   ┌──────────────────┐  ┌────────────────┐  ║
║   │  SharedPreferences   │   │  SQLite / Hive   │  │   Firebase     │  ║
║   │  (current)           │   │  (proposed)      │  │   Firestore    │  ║
║   └──────────────────────┘   └──────────────────┘  │   (future)     │  ║
║                                                     └────────────────┘  ║
╚═══════════════════════════════════╪════════════════════════════════════╝
                                    │
╔═══════════════════════════════════▼════════════════════════════════════╗
║                         PRESENTATION LAYER                              ║
║                                                                          ║
║   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐  ║
║   │  Home    │ │  Map     │ │ Warnings │ │  Beach   │ │  Chatbot   │  ║
║   │Dashboard │ │ Screen   │ │ Screen   │ │  Detail  │ │ AquaVerse  │  ║
║   └──────────┘ └──────────┘ └──────────┘ └──────────┘ │   .ai      │  ║
║                                           ┌──────────┐ └────────────┘  ║
║                                           │ Settings │                  ║
║                                           └──────────┘                  ║
╚═════════════════════════════════════════════════════════════════════════╝
```

---

### 4.2 Component Architecture

```
AquaVerse Application
│
├── CORE
│   ├── constants/
│   │   ├── AppColors          — Ocean-themed color palette (Safe/Moderate/High/Danger)
│   │   └── ApiConstants       — All INCOIS endpoints, timeout config, storage keys
│   ├── theme/
│   │   └── AppTheme           — Dark ocean MaterialTheme configuration
│   └── utils/
│       ├── RiskCalculator     — Multi-factor threat → RiskAssessment mapping
│       ├── RiskPredictor      — Time-series risk forecast (2h / 6h / 12h)
│       └── LocationUtils      — Haversine distance, nearest safe beach finder
│
├── DATA
│   ├── models/
│   │   ├── BeachLocation      — Station name, lat/lon, riskLevel, isFavorite
│   │   ├── WarningData        — type, ThreatLevel, message, rawData (GeoJSON)
│   │   ├── TideDataPoint      — timestamp, water level (meters)
│   │   ├── HighLowTide        — timestamp, value, TideType (high/low)
│   │   ├── TideLocationData   — collection of points, currentTide, next H/L
│   │   ├── WaterQualityData   — 12 WQNS parameters + safetyRating
│   │   └── ChatMessageModel   — role (user/assistant), content, timestamp
│   ├── services/
│   │   ├── IncoisService      — All INCOIS HTTP calls + mock fallbacks
│   │   ├── GeminiService      — Gemini 2.0 Flash chat session management
│   │   └── NotificationService— Android notification channels, warning alerts
│   └── providers/
│       ├── AppProvider        — Central app state + all data orchestration
│       └── ChatbotProvider    — Chat history, loading state, send/reset
│
└── PRESENTATION
    ├── screens/
    │   ├── SplashScreen       — Animated ocean branding on cold start
    │   ├── MainNavigation     — Bottom nav bar (5 tabs)
    │   ├── HomeScreen         — RiskCard, TideChart, Alerts, Predictions
    │   ├── MapScreen          — flutter_map with 170+ station markers
    │   ├── WarningsScreen     — 5-tab warning detail view
    │   ├── BeachDetailScreen  — Per-location tides, WQ, recommendation card
    │   ├── ChatbotScreen      — Chat UI with Gemini-powered responses
    │   └── SettingsScreen     — API keys, location, notification prefs
    └── widgets/
        ├── RiskLevelCard      — Risk color, title, subtitle, active warnings
        ├── TideChartWidget    — fl_chart 24h tidal waveform
        ├── WarningCard        — Single warning with threat level badge
        └── WaterQualityCard   — Parameter grid with safe/caution indication
```

---

### 4.3 Data Flow Diagram

```
USER OPENS APP
     │
     ▼
AppProvider.initialize()
     │
     ├──[parallel]──► loadLocations()
     │                    └──► assets/data/tide_locations.json
     │                              └──► 170+ BeachLocation objects parsed
     │
     ├──[parallel]──► _loadPreferences()
     │                    └──► SharedPreferences
     │                              └──► API keys, default location, notif prefs
     │
     └──► refreshAll()  [after both above complete]
               │
               ├──[parallel]──► refreshWarnings()
               │                    │
               │                    ├──[5 parallel HTTP calls]──► INCOIS REST API
               │                    │   ├── GET /tsunami
               │                    │   ├── GET /stormsurgelatest
               │                    │   ├── GET /hwalatestgeo
               │                    │   ├── GET /ssalatestgeo
               │                    │   └── GET /currentslatestgeo
               │                    │        │
               │                    │        ├── [200 OK] ──► WarningData.fromJson()
               │                    │        │                   (parse COLOUR field)
               │                    │        └── [Error]   ──► WarningData.noThreat()
               │                    │
               │                    ├──► RiskCalculator.calculate(5 warnings)
               │                    │       └──► RiskAssessment {level, color, title,
               │                    │                           recommendation, warnings}
               │                    │
               │                    ├──► RiskPredictor.predict(tideData, 5 warnings)
               │                    │       └──► [RiskPrediction × 3]
               │                    │            ├── 2h: score(tide + warnings + time)
               │                    │            ├── 6h: score × decay(0.87)
               │                    │            └── 12h: score × decay(0.80)
               │                    │
               │                    ├──► LocationUtils.findSafeAlternative()
               │                    │       ├── Sort 170+ stations by Haversine distance
               │                    │       ├── Filter: riskLevel == safe AND dist ≤ 500km
               │                    │       └──► BeachRecommendation {location, distKm, reason}
               │                    │
               │                    └──► NotificationService (if enabled)
               │                             └── For each activeWarning:
               │                                  └── if notifPrefs[type] == true
               │                                       └──► showWarningNotification()
               │
               └──[parallel]──► refreshTideData(defaultLocation)
                                    │
                                    ├── GET /incoisapi/rest/tidal/{location}
                                    │    └──► List<TideDataPoint> (48h, hourly)
                                    │
                                    └── GET /incoisapi/rest/high-low/{location}
                                         └──► List<HighLowTide> (H/L events)
                                              └──► TideLocationData assembled
                                                   └──► RiskPredictor updated


USER SENDS CHAT MESSAGE
     │
     ▼
ChatbotProvider.sendMessage(text)
     │
     └──► GeminiService.sendMessage(text)
               │
               ├── [if not initialized] ──► return setup instructions
               │
               └── ChatSession.sendMessage(Content.text(text))
                        │
                        └──► Gemini 2.0 Flash API (with ocean safety system prompt)
                                  └──► response.text ──► displayed in ChatScreen


USER VIEWS BEACH DETAIL
     │
     ▼
BeachDetailScreen(location)
     │
     ├──► AppProvider.refreshTideData(location.name)
     └──► AppProvider.refreshWaterQuality(location.name)
               │
               └──[12 parallel HTTP calls]──► INCOIS WQNS API
                    ├── /ph, /salinity, /temperature, /dissolvedoxygen
                    ├── /currentspeed, /currentdirection, /chlorophyll
                    ├── /turbidity, /dissolvedmethane, /pco2air, /pco2water
                    └──► WaterQualityData assembled → safetyRating computed
```

---

### 4.4 Module Interaction Diagram

```
                     ┌─────────────────┐
                     │   AppProvider   │◄──── ChangeNotifier (rebuilds UI)
                     └────────┬────────┘
                              │ orchestrates
           ┌──────────────────┼──────────────────────┐
           │                  │                       │
           ▼                  ▼                       ▼
   ┌───────────────┐  ┌───────────────┐   ┌──────────────────────┐
   │ IncoisService │  │ Notification  │   │   LocationService    │
   │               │  │ Service       │   │   (Geolocator)       │
   │ HTTP client   │  │               │   │                      │
   │ + fallbacks   │  │ Local push    │   │ GPS lat/lon          │
   └───────┬───────┘  └───────────────┘   └──────────┬───────────┘
           │                                          │
           │ raw data                                 │ coordinates
           ▼                                          ▼
   ┌───────────────┐                       ┌──────────────────────┐
   │WarningData ×5 │                       │   LocationUtils      │
   │TideLocationDat│                       │                      │
   │WaterQualityDat│                       │ • sortByDistance()   │
   └───────┬───────┘                       │ • findSafeAlternativ │
           │                               └──────────┬───────────┘
           ▼                                          │
   ┌───────────────┐                                  │
   │RiskCalculator │                                  │
   │               │                                  │
   │ 5 warnings →  │                                  ▼
   │ RiskAssessment│──────────────────────► BeachRecommendation
   └───────┬───────┘
           │
           ▼
   ┌───────────────┐
   │ RiskPredictor │
   │               │
   │ tide + warns  │
   │ → [2h,6h,12h] │
   │ RiskPrediction│
   └───────────────┘


   ┌─────────────────┐       ┌─────────────────────────────┐
   │ ChatbotProvider │──────►│      GeminiService          │
   └─────────────────┘       │                             │
                             │ • GenerativeModel init      │
                             │ • ChatSession management    │
                             │ • Ocean safety system prompt│
                             │ • Gemini 2.0 Flash API      │
                             └─────────────────────────────┘
```

---

## 5. Layer-by-Layer Breakdown

### 5.1 External Data Sources

| Source | Purpose | Auth Required | Fallback |
|---|---|---|---|
| INCOIS REST API (`gemini.incois.gov.in`) | All ocean data — tides, warnings, water quality | API key for early warnings; tidal data is open | Mock/demo data generated locally |
| Google Gemini 2.0 Flash | Conversational AI chatbot | Gemini API key (free via aistudio.google.com) | Static setup instructions shown to user |
| OpenStreetMap Tile Servers | Map tiles for `flutter_map` | None required | Cached tiles / blank map |
| Device GPS (`Geolocator`) | User location for nearest station, recommendation | Android location permission | Location features disabled gracefully |

---

### 5.2 Data Acquisition Layer

**`IncoisService`** (`lib/data/services/incois_service.dart`)

The primary HTTP client for all INCOIS API interactions. All requests include a configurable `Authorization` header when an API key is set. Each method has a mock data fallback triggered on any non-200 response or network error, ensuring the app remains functional in demo mode.

Key methods:
- `getTidalData(location)` — fetches 48h tidal predictions + high/low tide events
- `getTsunamiWarning()` / `getStormSurgeWarning()` / `getHighWaveAlert()` / `getSwellSurgeAlert()` / `getCoastalCurrentAlert()` — each hits a dedicated INCOIS endpoint and parses the GeoJSON `COLOUR` field into `ThreatLevel`
- `getWaterQuality(station)` — fires 12 parallel HTTP requests, one per WQNS parameter, assembled into a `WaterQualityData` object

All warning parsers look for `COLOUR` field values: `RED → ThreatLevel.warning`, `ORANGE → ThreatLevel.alert`, `YELLOW → ThreatLevel.watch`, otherwise `ThreatLevel.noThreat`.

**`GeminiService`** (`lib/data/services/gemini_service.dart`)

Manages a stateful `ChatSession` with Gemini 2.0 Flash. The session is initialized with a domain-specific system prompt covering INCOIS warning levels, beach activity types, and safety-first guidance. API key validation happens at initialization; invalid keys trigger graceful degradation.

**`LocationService`** (via `geolocator` package, managed in `AppProvider`)

Requests `LocationAccuracy.medium` with a 10-second timeout. Permission denial is handled gracefully — the app continues to function using the user's configured default location instead of GPS.

---

### 5.3 Intelligent Processing Layer

#### RiskCalculator (`lib/core/utils/risk_calculator.dart`)

Implements a **priority-weighted multi-factor threat scoring algorithm** aligned with INCOIS standard color codes. Threat categories are evaluated in decreasing priority order:

```
Priority 1: Tsunami       — WARNING → DANGER,  ALERT/WATCH → HIGH
Priority 2: Storm Surge   — WARNING → DANGER,  ALERT → HIGH,  WATCH → MODERATE
Priority 3: High Wave     — WARNING → HIGH,    ALERT/WATCH → MODERATE
Priority 4: Swell Surge   — any active → MODERATE
Priority 5: Coastal Current — any active → MODERATE
```

The overall `RiskLevel` is the maximum level assigned by any active category. Output is a `RiskAssessment` containing: level enum, display title, subtitle, recommendation string, color, icon, and list of active warning labels.

#### RiskPredictor (`lib/core/utils/risk_predictor.dart`)

A **rule-based ML-style prediction engine** producing `RiskPrediction` objects for three forecast windows: 2h, 6h, 12h. For each window:

| Feature | Weight | Logic |
|---|---|---|
| Predicted tide height at target time | Variable | Height > 2.0m: +0.25 score; > 1.5m: +0.15; < 0.5m: -0.05 |
| Upcoming high tide in window | Variable | Max high tide > 2.2m: +0.20; > 1.8m: +0.10 |
| Active tsunami warning | 0.40 max | WARNING: +0.40; ALERT: +0.26; WATCH: +0.12 |
| Active storm surge warning | 0.35 max | WARNING: +0.35; ALERT: +0.23; WATCH: +0.11 |
| Active high wave warning | 0.30 max | WARNING: +0.30; ALERT: +0.20; WATCH: +0.09 |
| Active swell surge warning | 0.20 max | WARNING: +0.20; ALERT: +0.13; WATCH: +0.06 |
| Active coastal current warning | 0.15 max | WARNING: +0.15; ALERT: +0.10; WATCH: +0.05 |
| Night-time factor | +0.05 | Hour 22:00–05:00 |
| Temporal decay factor | Multiplicative | `1.0 - (hoursAhead / 24) × 0.2` |

Score thresholds: `≥ 0.65 → DANGER`, `≥ 0.40 → HIGH`, `≥ 0.20 → MODERATE`, `< 0.20 → SAFE`

Confidence: `(1.0 - (hoursAhead / 24) × 0.3)` → 2h ≈ 97.5%, 6h ≈ 92.5%, 12h ≈ 85%

#### RecommendationEngine (`lib/core/utils/location_utils.dart` — `LocationUtils`)

When the user's GPS-detected risk level is not SAFE, `findSafeAlternative()` is invoked:
1. All 170+ `BeachLocation` objects are sorted by Haversine geodesic distance from the user's coordinates
2. Filtered to: `riskLevel == RiskLevel.safe` AND `distance ≤ 500km`
3. Top-3 candidates taken; nearest is returned as the primary recommendation
4. Output: `BeachRecommendation` with recommended location, distance in km, and a risk-severity-specific reason string

**Haversine formula** used for geodesic distance:
```
d = 2R × arcsin(√(sin²(Δφ/2) + cos φ₁ · cos φ₂ · sin²(Δλ/2)))
R = 6371 km
```

---

### 5.4 State Management Layer

**`AppProvider`** (`lib/data/providers/app_provider.dart`)

The single source of truth for all application state. Extends `ChangeNotifier` and is provided at the root `MaterialApp` widget via the `Provider` package.

State managed:
- User settings (API keys, default location, notification preferences, favorites)
- All 5 `WarningData` streams
- `TideLocationData` for the selected location
- `WaterQualityData` for the selected station
- `RiskAssessment` (current)
- `List<RiskPrediction>` (2h/6h/12h)
- User GPS coordinates and nearest `BeachLocation`
- `BeachRecommendation` object
- Loading and error states for each async operation

**`ChatbotProvider`** (`lib/data/providers/chatbot_provider.dart`)

Manages the chat session state: message history (`List<ChatMessageModel>`), loading indicator, and the `GeminiService` reference. Handles Gemini API key updates by re-initializing the session.

---

### 5.5 Persistence Layer

**Current Implementation — `SharedPreferences`**

Used exclusively for user settings and preferences:
- `aquaverse_incois_key` — INCOIS API key
- `aquaverse_gemini_key` — Gemini API key
- `aquaverse_default_location` — User's preferred location string
- `aquaverse_notifications_enabled` — Master notification toggle
- `aquaverse_favorites` — List of favorited location names
- `aquaverse_notif_<type>` — Per-warning-type notification toggle (5 keys)

**Proposed — SQLite via `sqflite`** *(Future Scope)*

Local structured database for historical data:
```
Tables:
  warning_logs     (id, type, threat_level, message, timestamp)
  tide_snapshots   (id, location, tide_value, recorded_at)
  wq_logs          (id, station, ph, salinity, temp, do, chlorophyll, recorded_at)
  risk_events      (id, level, active_warnings_json, predicted_at)
```

**Proposed — Firebase Firestore** *(Future Scope)*

Remote database for aggregated, anonymized analytics:
```
Collections:
  /risk_events     — anonymized alert occurrences with geographic region
  /user_sessions   — visit patterns (no PII)
  /beach_reports   — crowdsourced ground-truth conditions
```

---

### 5.6 Presentation Layer

| Screen | Route | Key Widgets | Data Source |
|---|---|---|---|
| `SplashScreen` | `/` | Ocean animation, AquaVerse logo | None |
| `HomeScreen` | `/home` | `RiskLevelCard`, `TideChartWidget`, active warnings list, `RiskPrediction` row | `AppProvider` |
| `MapScreen` | `/map` | `FlutterMap` with `MarkerLayer` (170+ markers), `BeachRecommendation` banner | `AppProvider` |
| `WarningsScreen` | `/warnings` | `TabBar` (5 tabs), `WarningCard` per category | `AppProvider` |
| `BeachDetailScreen` | `/beach/:name` | Tide chart, `WaterQualityCard` grid, safety tips, recommendation card | `AppProvider` |
| `ChatbotScreen` | `/chatbot` | `ListView` of messages, text input, send button | `ChatbotProvider` |
| `SettingsScreen` | `/settings` | API key fields, location picker, notification toggles | `AppProvider` |

All screens consume state via `Consumer<AppProvider>` or `Provider.of<AppProvider>(context)`, rebuilding reactively when `notifyListeners()` is called.

---

## 6. Data Models

### `WarningData`
```
WarningData {
  type          : String         // 'tsunami' | 'stormsurge' | 'highwave' | 'swellsurge' | 'coastalcurrents'
  typeName      : String         // Human-readable label
  threatLevel   : ThreatLevel    // noThreat | watch | alert | warning
  message       : String         // Advisory text from INCOIS
  lastUpdated   : DateTime
  rawData       : Map?           // Original GeoJSON from API
}

ThreatLevel enum:
  noThreat → GREEN  (No active advisory)
  watch    → YELLOW (Developing situation)
  alert    → ORANGE (Hazardous conditions)
  warning  → RED    (Life-threatening)
```

### `TideLocationData`
```
TideLocationData {
  locationName  : String
  dataPoints    : List<TideDataPoint>    // 48 hourly points
  highLowTides  : List<HighLowTide>      // H/L tide events
  fetchedAt     : DateTime
  currentTide   : double   (computed — closest point to now)
  nextHighTide  : HighLowTide?  (computed)
  nextLowTide   : HighLowTide?  (computed)
}

TideDataPoint { timestamp: DateTime, value: double (meters) }
HighLowTide   { timestamp: DateTime, value: double, type: TideType (high|low) }
```

### `WaterQualityData`
```
WaterQualityData {
  stationName       : String
  lastReported      : DateTime
  ph                : double?      // Target: 7.8–8.5
  salinity          : double?      // PSU
  temperature       : double?      // °C
  dissolvedOxygen   : double?      // mg/L
  currentSpeed      : double?      // m/s
  currentDirection  : String?      // Compass bearing
  chlorophyll       : double?      // μg/L
  turbidity         : double?      // NTU
  dissolvedMethane  : double?      // nmol/L
  pco2Air           : double?      // μatm
  pco2Water         : double?      // μatm
  safetyRating      : String       // 'Good' | 'Caution' | 'Poor' (computed)
}
```

### `BeachLocation`
```
BeachLocation {
  name       : String     // INCOIS station code (e.g., 'KOCHI')
  latitude   : double
  longitude  : double
  riskLevel  : RiskLevel  // Updated on each warning refresh
  isFavorite : bool
  displayName: String     // computed — hyphens → spaces
  region     : String     // computed — 'India' | 'Sri Lanka' | etc.
}
```

### `RiskAssessment`
```
RiskAssessment {
  level          : RiskLevel         // safe | moderate | high | danger
  title          : String            // 'SAFE' | 'MODERATE RISK' | 'HIGH RISK' | 'DANGER'
  subtitle       : String
  recommendation : String            // Actionable safety guidance
  color          : Color             // Green / Yellow / Orange / Red
  icon           : IconData
  activeWarnings : List<String>      // Labels of contributing warnings
}
```

### `RiskPrediction`
```
RiskPrediction {
  window              : PredictionWindow    // twoHours | sixHours | twelveHours
  predictedLevel      : RiskLevel
  confidence          : double             // 0.0–1.0
  insight             : String             // Human-readable forecast sentence
  predictedTideHeight : double             // meters at target time
  windowLabel         : String             // 'In 2 hours' | 'In 6 hours' | 'In 12 hours'
}
```

### `BeachRecommendation`
```
BeachRecommendation {
  currentNearest         : BeachLocation?   // Nearest station to user
  recommendedLocation    : BeachLocation    // Nearest safe station
  distanceFromUserKm     : double
  currentRisk            : RiskLevel
  reason                 : String           // Risk-severity-specific advisory text
}
```

---

## 7. Risk Assessment Engine

The `RiskCalculator` implements INCOIS-aligned threat prioritization:

```
INPUT:  WarningData × 5  (tsunami, stormSurge, highWave, swellSurge, coastalCurrents)

ALGORITHM:
  level = RiskLevel.safe
  warnings = []

  // Priority 1 — Tsunami
  if tsunami.threatLevel == WARNING  → level = DANGER
  if tsunami.threatLevel == ALERT    → level = max(level, HIGH)
  if tsunami.threatLevel == WATCH    → level = max(level, HIGH)

  // Priority 2 — Storm Surge
  if stormSurge.threatLevel == WARNING → level = max(level, DANGER)
  if stormSurge.threatLevel == ALERT   → level = max(level, HIGH)
  if stormSurge.threatLevel == WATCH   → level = max(level, MODERATE)

  // Priority 3 — High Wave
  if highWave.threatLevel == WARNING   → level = max(level, HIGH)
  if highWave.threatLevel != noThreat  → level = max(level, MODERATE)

  // Priority 4 — Swell Surge
  if swellSurge.threatLevel != noThreat → level = max(level, MODERATE)

  // Priority 5 — Coastal Currents
  if coastalCurrents.threatLevel != noThreat → level = max(level, MODERATE)

OUTPUT: RiskAssessment { level, title, color, recommendation, activeWarnings }
```

**Color Mapping (INCOIS Standard):**

| Level | Color | Hex | Meaning |
|---|---|---|---|
| SAFE | Green | #4CAF50 | No active advisories |
| MODERATE | Yellow/Amber | #FFC107 | Watch-level threats present |
| HIGH | Orange | #FF9800 | Alert-level or High Wave Warning |
| DANGER | Red | #F44336 | Tsunami/Storm Surge WARNING level |

---

## 8. Risk Prediction Engine

The `RiskPredictor` forecasts future conditions across three time windows using a composite scoring model:

```
SCORE COMPUTATION (per window):

  score = 0.0

  // Feature 1: Tide height at target timestamp
  tideHeight = closest TideDataPoint to (now + hoursAhead)
  if tideHeight > 2.0  → score += 0.25
  if tideHeight > 1.5  → score += 0.15
  if tideHeight < 0.5  → score -= 0.05

  // Upcoming high tide within window + 2h buffer
  if maxUpcomingHighTide > 2.2 → score += 0.20
  if maxUpcomingHighTide > 1.8 → score += 0.10

  // Feature 2: Warning persistence factors
  tsunami       WARNING → +0.40 | ALERT → +0.26 | WATCH → +0.12
  stormSurge    WARNING → +0.35 | ALERT → +0.23 | WATCH → +0.11
  highWave      WARNING → +0.30 | ALERT → +0.20 | WATCH → +0.09
  swellSurge    WARNING → +0.20 | ALERT → +0.13 | WATCH → +0.06
  coastalCurrents WARNING→+0.15 | ALERT → +0.10 | WATCH → +0.05

  // Feature 3: Night-time factor (22:00–05:59)
  if nightTime → score += 0.05

  // Feature 4: Temporal decay
  decay = 1.0 - (hoursAhead / 24) × 0.2
  score = clamp(score × decay, 0.0, 1.0)

THRESHOLDS:
  score ≥ 0.65 → DANGER
  score ≥ 0.40 → HIGH
  score ≥ 0.20 → MODERATE
  score  < 0.20 → SAFE

CONFIDENCE:
  confidence = clamp(1.0 - (hoursAhead / 24) × 0.30, 0.0, 1.0)
  → 2h:  ~97.5%
  → 6h:  ~92.5%
  → 12h: ~85.0%
```

---

## 9. Intelligent Recommendation System

### Current Implementation

`LocationUtils.findSafeAlternative()` identifies the nearest safe beach when the user's current coastal area has elevated risk:

```
INPUT:
  allLocations  : List<BeachLocation>  (170+ stations with updated riskLevel)
  userLat/Lon   : double               (from GPS)
  currentRisk   : RiskLevel            (from RiskCalculator)
  searchRadius  : int = 500 km

ALGORITHM:
  1. if currentRisk == safe → return null (user already in safe zone)
  2. Sort allLocations by Haversine distance from user
  3. Filter: loc.riskLevel == RiskLevel.safe AND distance ≤ 500km
  4. Take top 3 candidates
  5. Return nearest as BeachRecommendation

REASON STRING (risk-calibrated):
  DANGER  → "Life-threatening conditions. {dest} is the nearest safe alternative."
  HIGH    → "High risk near you. {dest} offers safer conditions."
  MODERATE→ "Moderate risk. {dest} has calmer conditions."
```

### Proposed Enhancement (Multi-Criteria Scoring)

The current single-factor (distance) approach will be upgraded to a weighted multi-criteria model:

```
SCORING FACTORS per candidate location:
  Distance from user           → weight: 30%   (normalized, inverse: closer = higher)
  Current risk level           → weight: 40%   (SAFE=1.0, MODERATE=0.5, HIGH=0.2, DANGER=0.0)
  Predicted risk next 6h       → weight: 20%   (from RiskPredictor for candidate station)
  Water quality safety rating  → weight: 10%   (Good=1.0, Caution=0.5, Poor=0.0)

COMPOSITE SCORE = Σ(factor × weight)
OUTPUT: Ranked top-3 safe locations + navigation intent (Google Maps deep link)
```

---

## 10. AI Chatbot — AquaVerse.ai

**Model:** Google Gemini 2.0 Flash
**Integration:** `google_generative_ai` Flutter package
**Session:** Stateful `ChatSession` — conversation context preserved within app session

### System Prompt Architecture

The chatbot is initialized with a domain-constrained system prompt covering:
- Role definition: INCOIS-data ocean safety assistant
- INCOIS color code interpretation (GREEN/YELLOW/ORANGE/RED)
- Beach activity recommendations by risk level (swimming, surfing, fishing, snorkeling, diving, kayaking)
- Output constraints: safety-first, concise, ocean-themed tone
- Mandatory closing for safety-critical advice: "Always follow local authority and lifeguard instructions."

### Generation Config
```
temperature      : 0.7   (balanced creativity vs. factual accuracy)
maxOutputTokens  : 512   (concise mobile-appropriate responses)
```

### Proposed Enhancement

Inject live app state into the initial system prompt at session start:
```
"Current conditions at {userLocation}:
 Risk Level: {riskAssessment.title}
 Active Warnings: {activeWarnings.join(', ')}
 Current Tide: {tideData.currentTide}m
 Next High Tide: {nextHighTide.time} at {nextHighTide.value}m"
```
This enables the chatbot to give contextually grounded answers without the user needing to describe current conditions manually.

---

## 11. Notification System

**Package:** `flutter_local_notifications`
**Trigger:** On every `refreshWarnings()` call when active warnings exist

### Android Notification Channels

| Channel ID | Name | Importance |
|---|---|---|
| `aquaverse_warnings` | Beach Safety Warnings | High (heads-up) |

### Notification Flow

```
For each warning in activeWarnings:
  if notificationsEnabled == true
  AND notifPrefs[warning.type] == true:
    → showWarningNotification(warning)
       Title: "{typeName} {threatLevel.label}"
       Body:  warning.message
       Icon:  warning-specific Material icon
```

### User-Configurable Toggles

Users can independently enable/disable notifications for each of the 5 warning categories in the Settings screen. Master toggle disables all notifications. Settings persisted to `SharedPreferences`.

### Proposed Enhancement — Server-Side Push

See Section 12.1. This replaces the foreground-only model with true background push via Firebase Cloud Messaging.

---

## 12. Scoped Future Features Architecture

### 12.1 Feature 1: Server-Side Personalized Push Notifications

**Problem:** Current notifications only fire when the app is open. A user at the beach who has not opened the app will not receive a warning when conditions deteriorate.

**Proposed Architecture:**

```
╔══════════════════════════════════════════════════════════════════════╗
║               SERVER-SIDE NOTIFICATION PIPELINE                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  Firebase Cloud Functions (Node.js / Python)                         ║
║  ┌─────────────────────────────────────────────────────────────┐    ║
║  │  scheduledWarningPoller (runs every 30 minutes via cron)    │    ║
║  │                                                             │    ║
║  │  1. Call INCOIS API for all 5 warning types                 │    ║
║  │  2. Compare to last persisted state in Firestore            │    ║
║  │  3. If any warning ESCALATED (e.g., noThreat → watch):      │    ║
║  │     a. Write new event to /risk_events collection           │    ║
║  │     b. Query /user_tokens for subscribed devices            │    ║
║  │     c. Send FCM multicast push                              │    ║
║  │  4. Persist new warning state to Firestore                  │    ║
║  └─────────────────────────┬───────────────────────────────────┘    ║
║                             │ FCM push payload                       ║
║  ┌──────────────────────────▼──────────────────────────────────┐    ║
║  │  Flutter App (background / terminated state)                │    ║
║  │  firebase_messaging package                                 │    ║
║  │                                                             │    ║
║  │  • FirebaseMessaging.onBackgroundMessage() handler          │    ║
║  │  • Displays heads-up notification via flutter_local_notif.  │    ║
║  │  • Respects per-type user preference stored locally         │    ║
║  └─────────────────────────────────────────────────────────────┘    ║
║                                                                       ║
║  Personalization layer:                                               ║
║  • Device token registered with user's default location preference   ║
║  • Push sent only when relevant to user's coastal region             ║
║  • Respects notification type preferences synced to Firestore        ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Flutter packages required:** `firebase_messaging`, `firebase_core`

---

### 12.2 Feature 2: Enhanced Intelligent Recommendation Engine

**Problem:** Current recommendation uses only distance as the selection criterion. A beach 50km away with a 6h forecast of HIGH risk may be recommended over one 80km away that will remain SAFE.

**Proposed Architecture:**

```
╔══════════════════════════════════════════════════════════════════════╗
║            ENHANCED RECOMMENDATION ENGINE                            ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  INPUT SIGNALS:                                                       ║
║  ┌──────────────────────────────────────────────────────────────┐   ║
║  │  • User GPS coordinates                                      │   ║
║  │  • currentRisk (from RiskCalculator)                         │   ║
║  │  • All BeachLocation objects (170+) with current riskLevel   │   ║
║  │  • RiskPredictor forecasts for candidate stations            │   ║
║  │  • WaterQualityData.safetyRating per station                 │   ║
║  └──────────────────────────┬─────────────────────────────────┘    ║
║                              │                                        ║
║  SCORING (per candidate beach):                                       ║
║  ┌──────────────────────────────────────────────────────────────┐   ║
║  │  distanceScore   = 1 - (distKm / maxSearchRadius)  × 0.30   │   ║
║  │  currentRiskScore = riskToScore(loc.riskLevel)      × 0.40   │   ║
║  │  forecastScore   = riskToScore(6hPrediction.level)  × 0.20   │   ║
║  │  wqScore         = wqRatingToScore(safetyRating)    × 0.10   │   ║
║  │                                                              │   ║
║  │  compositeScore = Σ all weighted scores                     │   ║
║  └──────────────────────────┬─────────────────────────────────┘    ║
║                              │                                        ║
║  OUTPUT:                                                              ║
║  ┌──────────────────────────────────────────────────────────────┐   ║
║  │  Ranked top-3 BeachRecommendation objects                    │   ║
║  │  • Each with: score, distance, current risk, 6h forecast     │   ║
║  │  • Navigation intent: maps.google.com/?daddr={lat},{lon}     │   ║
║  │  • Displayed as a ranked recommendation card on Map & Home   │   ║
║  └──────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

### 12.3 Feature 3: Data Persistence — Database Layer

**Problem:** All fetched data is session-only. No history, no trends, no offline access.

**Proposed Architecture — Two-Tier Database:**

```
╔══════════════════════════════════════════════════════════════════════╗
║                  TIER 1: LOCAL DATABASE (SQLite)                     ║
║                  Package: sqflite                                     ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  warning_logs                                                         ║
║  ┌──────┬─────────────────┬──────────────┬────────────┬───────────┐  ║
║  │  id  │  warning_type   │ threat_level │  message   │ timestamp │  ║
║  └──────┴─────────────────┴──────────────┴────────────┴───────────┘  ║
║  Purpose: View warning history per location; trend visualization      ║
║                                                                       ║
║  tide_snapshots                                                        ║
║  ┌──────┬──────────────┬─────────────┬──────────────────────────────┐ ║
║  │  id  │  location    │ tide_value  │  recorded_at                 │ ║
║  └──────┴──────────────┴─────────────┴──────────────────────────────┘ ║
║  Purpose: Offline tide chart; historical tide trend per station       ║
║                                                                       ║
║  wq_logs                                                              ║
║  ┌──────┬─────────┬─────┬──────────┬──────┬─────┬──────┬───────────┐ ║
║  │  id  │ station │ ph  │ salinity │ temp │ do  │ chl  │ timestamp │ ║
║  └──────┴─────────┴─────┴──────────┴──────┴─────┴──────┴───────────┘ ║
║  Purpose: Water quality trend analysis per monitoring station         ║
║                                                                       ║
║  risk_events                                                          ║
║  ┌──────┬────────────┬──────────────────────┬───────────────────────┐ ║
║  │  id  │ risk_level │ active_warnings_json │   predicted_at        │ ║
║  └──────┴────────────┴──────────────────────┴───────────────────────┘ ║
║  Purpose: Risk event log; frequency analysis; seasonal patterns       ║
╚══════════════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════════════════════════════════╗
║             TIER 2: REMOTE DATABASE (Firebase Firestore)             ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  Collection: /risk_events                                             ║
║  ┌─────────────────────────────────────────────────────────────┐    ║
║  │  { region, risk_level, warning_types[], timestamp, source } │    ║
║  │  Anonymized — no user PII stored                            │    ║
║  │  Purpose: O5 — authority-facing risk frequency dashboard    │    ║
║  └─────────────────────────────────────────────────────────────┘    ║
║                                                                       ║
║  Collection: /user_sessions  (anonymized)                             ║
║  ┌─────────────────────────────────────────────────────────────┐    ║
║  │  { session_id, region, duration_min, screens_visited[] }    │    ║
║  │  Purpose: O4 — tourism pattern analytics                    │    ║
║  └─────────────────────────────────────────────────────────────┘    ║
║                                                                       ║
║  Collection: /beach_reports  (crowdsourced)                           ║
║  ┌─────────────────────────────────────────────────────────────┐    ║
║  │  { station_name, report_type, description, timestamp, lat,  │    ║
║  │    lon, verified: false }                                   │    ║
║  │  Purpose: Ground-truth validation of INCOIS data            │    ║
║  └─────────────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════════╝
```

**Flutter packages required:** `sqflite`, `path`, `firebase_core`, `cloud_firestore`

---

## 13. Objectives Traceability Matrix

| Objective | Current Module | Current File | Proposed Enhancement | Architecture Layer |
|---|---|---|---|---|
| **O1: Enhanced Tourist Safety** | `RiskCalculator`, `NotificationService`, 5 INCOIS warning streams | `risk_calculator.dart`, `notification_service.dart`, `incois_service.dart` | Server-side FCM push (§12.1) | Intelligent Processing + Persistence |
| **O2: Data-Driven Tourism** | `RiskPredictor`, `GeminiService`, `TideChartWidget`, `WaterQualityCard` | `risk_predictor.dart`, `gemini_service.dart` | Multi-criteria RecommendationEngine (§12.2); Gemini context injection | Intelligent Processing + Data Acquisition |
| **O3: Environmental Protection** | `RiskCalculator` (DANGER/HIGH deters access), 170+ station coverage, Map risk colors | `risk_calculator.dart`, `map_screen.dart` | Ecological zone GeoJSON overlay on map | Presentation (Map Screen) |
| **O4: Economic Benefits** | AI chatbot promotes data-informed tourism; safety → reduced incidents | `gemini_service.dart` | Firestore anonymized session analytics; authority dashboard | Persistence (Remote DB) |
| **O5: Informed Decision-Making** | Water quality 12-param grid, 5-category warnings dashboard, `BeachRecommendation` | `incois_service.dart`, `location_utils.dart`, `warnings_screen.dart` | SQLite warning/WQ history logs + Firestore risk event collection (§12.3) | Persistence Layer |

---

## 14. Technology Stack

| Component | Technology | Version | Justification |
|---|---|---|---|
| Mobile Framework | Flutter | 3.x | Single codebase targeting Android; Dart performance; rich widget ecosystem |
| Language | Dart | 3.x | Strongly typed, async-first, null-safe |
| State Management | Provider + ChangeNotifier | 6.x | Lightweight reactive state; no boilerplate; InheritedWidget under the hood |
| Ocean Data API | INCOIS REST API | — | Official Government of India ocean data; free; authoritative for Indian coastal region |
| Maps | flutter_map + OpenStreetMap | 6.x | Zero API key dependency; open-source; customizable marker layers |
| Tide/Data Charts | fl_chart | 0.68.x | Declarative chart API; smooth animations; customizable waveform |
| AI Chatbot | Google Gemini 2.0 Flash | — | Free tier; fast inference; customizable system prompt; stateful chat sessions |
| GPS & Location | geolocator | 12.x | Cross-platform GPS; permission handling; configurable accuracy |
| Push Notifications | flutter_local_notifications | 17.x | Android notification channels; heads-up alerts; rich notification payload |
| Risk Engine | Custom rule-based multi-factor scoring | — | Deterministic; auditable; aligned with INCOIS threat level standard |
| Local Storage | SharedPreferences | 2.x | Key-value settings storage; lightweight; no schema required |
| Proposed: Local DB | sqflite | 2.x | Full SQL on device; structured historical data; trend queries |
| Proposed: Remote DB | Firebase Firestore | — | Real-time sync; NoSQL; scalable; authority analytics |
| Proposed: Background Push | Firebase Cloud Messaging | — | Server-triggered push independent of app lifecycle state |

---

## 15. API Reference

### INCOIS REST API

**Base URL:** `https://gemini.incois.gov.in`

| Service | Method | Endpoint | Auth Required | Response Format |
|---|---|---|---|---|
| Astronomical Tides | GET | `/incoisapi/rest/tidal/{location}` | No | JSON array of `{t, v}` objects |
| High-Low Tides | GET | `/incoisapi/rest/high-low/{location}` | No | JSON array of `{t, v, Type}` objects |
| Tsunami Warning | GET | `/incoisapi/rest/tsunami` | Yes | GeoJSON FeatureCollection |
| Storm Surge | GET | `/incoisapi/rest/stormsurgelatest` | Yes | GeoJSON FeatureCollection |
| High Wave Alerts | GET | `/incoisapi/rest/hwalatestgeo` | Yes | GeoJSON FeatureCollection |
| Swell Surge Alerts | GET | `/incoisapi/rest/ssalatestgeo` | Yes | GeoJSON FeatureCollection |
| Coastal Currents | GET | `/incoisapi/rest/currentslatestgeo` | Yes | GeoJSON FeatureCollection |
| Water Quality (WQNS) | GET | `/OceanDataAPI/api/wqns/{station}/{parameter}` | Yes | JSON with parameter array |

**Water Quality Parameters (WQNS):**
`ph`, `salinity`, `temperature`, `dissolvedoxygen`, `currentspeed`, `currentdirection`, `chlorophyll`, `turbidity`, `dissolvedmethane`, `pco2air`, `pco2water`

**Warning Response Parsing:**
```
GeoJSON feature → properties.COLOUR (or properties.colour)
  "RED"    → ThreatLevel.warning  (life-threatening)
  "ORANGE" → ThreatLevel.alert    (extreme hazard)
  "YELLOW" → ThreatLevel.watch    (developing situation)
  other    → ThreatLevel.noThreat (no active advisory)
```

**Request Timeouts:** Configured in `ApiConstants` — default 8 seconds per request.

**Auth Header:** `Authorization: <INCOIS_API_KEY>` (when key is configured)

---

### Google Gemini API

**Package:** `google_generative_ai`
**Model:** `gemini-2.0-flash`
**API Key Source:** Free via [aistudio.google.com](https://aistudio.google.com) — no billing required

```
GenerativeModel config:
  model              : 'gemini-2.0-flash'
  systemInstruction  : Content.system(oceanSafetySystemPrompt)
  temperature        : 0.7
  maxOutputTokens    : 512
```

---

## 16. Project File Structure

```
E:\capstone\
│
├── lib/
│   ├── main.dart                              # App entry point — Provider setup, initialization
│   ├── app.dart                               # MaterialApp, theme, routes
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart                # Ocean color palette (Safe/Moderate/High/Danger)
│   │   │   └── api_constants.dart             # All INCOIS endpoints, timeouts, SharedPrefs keys
│   │   ├── theme/
│   │   │   └── app_theme.dart                 # Dark ocean MaterialTheme
│   │   └── utils/
│   │       ├── risk_calculator.dart           # Multi-factor threat → RiskAssessment
│   │       ├── risk_predictor.dart            # 2h/6h/12h RiskPrediction engine
│   │       └── location_utils.dart            # Haversine distance + BeachRecommendation
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── beach_location_model.dart      # BeachLocation (name, lat, lon, risk, favorite)
│   │   │   ├── warning_model.dart             # WarningData, ThreatLevel enum
│   │   │   ├── tide_model.dart                # TideDataPoint, HighLowTide, TideLocationData
│   │   │   ├── water_quality_model.dart       # WaterQualityData (12 WQNS parameters)
│   │   │   └── chat_message_model.dart        # ChatMessageModel (role, content, timestamp)
│   │   ├── services/
│   │   │   ├── incois_service.dart            # All INCOIS HTTP calls + mock fallbacks
│   │   │   ├── gemini_service.dart            # Gemini 2.0 Flash chat session
│   │   │   └── notification_service.dart      # Android notification channels + alert dispatch
│   │   └── providers/
│   │       ├── app_provider.dart              # Central app state (ChangeNotifier)
│   │       └── chatbot_provider.dart          # Chat history + GeminiService orchestration
│   │
│   └── presentation/
│       ├── screens/
│       │   ├── splash_screen.dart             # Animated ocean splash
│       │   ├── main_navigation.dart           # BottomNavigationBar (5 tabs)
│       │   ├── home/
│       │   │   └── home_screen.dart           # Risk card, tide chart, alerts, predictions
│       │   ├── map/
│       │   │   └── map_screen.dart            # flutter_map + 170+ markers + recommendation banner
│       │   ├── warnings/
│       │   │   └── warnings_screen.dart       # 5-tab INCOIS warnings view
│       │   ├── beach_detail/
│       │   │   └── beach_detail_screen.dart   # Per-station tides, WQ grid, safety tips
│       │   ├── chatbot/
│       │   │   └── chatbot_screen.dart        # AquaVerse.ai conversational interface
│       │   └── settings/
│       │       └── settings_screen.dart       # API keys, default location, notification prefs
│       └── widgets/
│           ├── risk_level_card.dart           # Risk color/title/recommendations card
│           ├── tide_chart_widget.dart         # fl_chart 24h tidal waveform
│           ├── warning_card.dart              # Single warning with threat level badge
│           └── water_quality_card.dart        # WQ parameter grid with rating
│
├── assets/
│   └── data/
│       └── tide_locations.json               # 170+ INCOIS tide station definitions
│                                              # {TIDE_LOCAT, LATITUDE, LONGITUDE}
│
├── android/
│   ├── app/
│   │   ├── build.gradle                      # compileSdk 34, minSdk 21, multidex
│   │   └── src/main/
│   │       ├── AndroidManifest.xml           # INTERNET, LOCATION, POST_NOTIFICATIONS perms
│   │       └── kotlin/com/aquaverse/app/
│   │           └── MainActivity.kt           # FlutterActivity
│   └── build.gradle                          # Project-level Gradle config
│
├── pubspec.yaml                              # All dependencies and asset declarations
├── analysis_options.yaml                     # Dart linting rules
├── README.md                                 # Setup + build + install instructions
└── ARCHITECTURE.md                           # This document
```

---

*AquaVerse — Built with Flutter · Ocean Data by INCOIS (Ministry of Earth Sciences, GoI) · AI by Google Gemini*
*Capstone Project | Final Year Engineering | 2024–25*
