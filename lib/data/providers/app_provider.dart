import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/location_utils.dart';
import '../../core/utils/risk_calculator.dart';
import '../../core/utils/risk_predictor.dart';
import '../models/beach_location_model.dart';
import '../models/warning_model.dart';
import '../models/tide_model.dart';
import '../models/water_quality_model.dart';
import '../services/firebase_service.dart';
import '../services/incois_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final IncoisService _incoisService = IncoisService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Settings ───
  String _incoisApiKey = '';
  String _geminiApiKey = '';
  String _groqApiKey = '';
  String _defaultLocation = 'Kochi';
  bool _notificationsEnabled = true;
  List<String> _favorites = [];

  final Map<String, bool> _notifPrefs = {
    'tsunami': true,
    'stormsurge': true,
    'highwave': true,
    'swellsurge': true,
    'coastalcurrents': true,
  };

  // ─── Locations ───
  List<BeachLocation> _allLocations = [];
  bool _locationsLoaded = false;

  // ─── User GPS ───
  double? _userLat;
  double? _userLon;
  bool _locationPermissionDenied = false;
  BeachLocation? _nearestLocation;
  BeachRecommendation? _recommendation;
  List<BeachLocation> _nearestLocations = [];

  // ─── Warnings ───
  WarningData? _tsunami;
  WarningData? _stormSurge;
  WarningData? _highWave;
  WarningData? _swellSurge;
  WarningData? _coastalCurrents;
  bool _warningsLoading = false;
  String? _warningsError;

  // ─── Tide & Water Quality ───
  TideLocationData? _tideData;
  WaterQualityData? _waterQuality;
  bool _tideLoading = false;
  bool _wqLoading = false;

  // ─── Risk ───
  RiskAssessment? _riskAssessment;
  List<RiskPrediction> _riskPredictions = [];

  // ─── Alert Tracking ───
  RiskLevel? _previousRiskLevel;
  DateTime? _lastPredictionAlertTime;

  // ─── Auto-refresh ───
  Timer? _refreshTimer;

  // ─────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────

  String get incoisApiKey => _incoisApiKey;
  String get geminiApiKey => _geminiApiKey;
  String get groqApiKey => _groqApiKey;
  String get defaultLocation => _defaultLocation;
  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get favorites => List.unmodifiable(_favorites);
  Map<String, bool> get notifPrefs => Map.unmodifiable(_notifPrefs);

  List<BeachLocation> get allLocations => _allLocations;
  bool get locationsLoaded => _locationsLoaded;

  double? get userLat => _userLat;
  double? get userLon => _userLon;
  bool get hasUserLocation => _userLat != null && _userLon != null;
  bool get locationPermissionDenied => _locationPermissionDenied;
  BeachLocation? get nearestLocation => _nearestLocation;
  BeachRecommendation? get recommendation => _recommendation;

  /// The 3 closest beach stations to the user (or first 3 if no GPS).
  List<BeachLocation> get nearestLocations =>
      List.unmodifiable(_nearestLocations);

  WarningData? get tsunami => _tsunami;
  WarningData? get stormSurge => _stormSurge;
  WarningData? get highWave => _highWave;
  WarningData? get swellSurge => _swellSurge;
  WarningData? get coastalCurrents => _coastalCurrents;
  bool get warningsLoading => _warningsLoading;
  String? get warningsError => _warningsError;

  TideLocationData? get tideData => _tideData;
  WaterQualityData? get waterQuality => _waterQuality;
  bool get tideLoading => _tideLoading;
  bool get wqLoading => _wqLoading;

  RiskAssessment? get riskAssessment => _riskAssessment;
  List<RiskPrediction> get riskPredictions => _riskPredictions;

  List<WarningData> get allWarnings => [
        if (_tsunami != null) _tsunami!,
        if (_stormSurge != null) _stormSurge!,
        if (_highWave != null) _highWave!,
        if (_swellSurge != null) _swellSurge!,
        if (_coastalCurrents != null) _coastalCurrents!,
      ];

  List<WarningData> get activeWarnings =>
      allWarnings.where((w) => w.threatLevel != ThreatLevel.noThreat).toList();

  /// True when live INCOIS data failed and we're showing demo fallback data.
  bool get isUsingDemoData => _warningsError != null;

  /// A plain-text summary of live ocean conditions injected into Gemini
  /// so the chatbot can give location-aware, real-time answers.
  String get liveContextSummary {
    if (_riskAssessment == null) return '';
    final buf = StringBuffer();
    buf.writeln(
        'Location: ${_nearestLocation?.displayName ?? _defaultLocation}');
    buf.writeln('Current Risk Level: ${_riskAssessment!.title}');
    buf.writeln('Risk Detail: ${_riskAssessment!.subtitle}');
    if (_tideData != null) {
      buf.writeln(
          'Current Tide: ${_tideData!.currentTide.toStringAsFixed(2)} m');
      final nextHigh = _tideData!.nextHighTide;
      final nextLow = _tideData!.nextLowTide;
      if (nextHigh != null) {
        buf.writeln(
            'Next High Tide: ${_fmtTime(nextHigh.timestamp)} (${nextHigh.value.toStringAsFixed(2)} m)');
      }
      if (nextLow != null) {
        buf.writeln(
            'Next Low Tide: ${_fmtTime(nextLow.timestamp)} (${nextLow.value.toStringAsFixed(2)} m)');
      }
    }
    if (_waterQuality?.temperature != null) {
      buf.writeln(
          'Sea Temperature: ${_waterQuality!.temperature!.toStringAsFixed(1)} °C');
    }
    if (_riskAssessment!.activeWarnings.isNotEmpty &&
        _riskAssessment!.activeWarnings.first != 'No active warnings') {
      buf.writeln(
          'Active Warnings: ${_riskAssessment!.activeWarnings.join(", ")}');
    } else {
      buf.writeln('Active Warnings: None');
    }
    if (_riskPredictions.isNotEmpty) {
      buf.writeln('Risk Predictions:');
      for (final p in _riskPredictions) {
        buf.writeln(
            '  ${p.windowLabel}: ${p.predictedLevel.name.toUpperCase()} '
            '(${(p.confidence * 100).round()}% confidence) — ${p.insight}');
      }
    }
    return buf.toString();
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────

  Future<void> initialize() async {
    // Load local data only (SharedPreferences + bundled JSON) — fast
    await Future.wait([
      _loadPreferences(),
      loadLocations(),
    ]);
    // UI can render immediately with saved settings and location list
    notifyListeners();

    // Firebase, cloud sync, and INCOIS fetch all run in background
    _loadRemoteData();
  }

  void _loadRemoteData() async {
    await _firebaseService.signInAnonymously();

    final cloudFavs = await _firebaseService.loadFavorites();
    if (cloudFavs.isNotEmpty) {
      _favorites = cloudFavs;
      for (final loc in _allLocations) {
        loc.isFavorite = _favorites.contains(loc.name);
      }
      notifyListeners();
    }

    final cloudSettings = await _firebaseService.loadUserSettings();
    if (cloudSettings != null) {
      final cloudLocation = cloudSettings['defaultLocation'] as String?;
      if (cloudLocation != null && cloudLocation.isNotEmpty) {
        _defaultLocation = cloudLocation;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.keyDefaultLocation, cloudLocation);
        notifyListeners();
      }
    }

    _fetchUserLocation();
    await refreshAll();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      refreshAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // API keys are stored in encrypted secure storage.
    // Migrate from plain SharedPreferences on first run after upgrade.
    _incoisApiKey = await _secureStorage.read(
          key: ApiConstants.keyIncoisApiKey,
        ) ??
        _migratePlainKey(
            prefs, ApiConstants.keyIncoisApiKey, _secureStorage);
    _geminiApiKey = await _secureStorage.read(
          key: ApiConstants.keyGeminiApiKey,
        ) ??
        _migratePlainKey(
            prefs, ApiConstants.keyGeminiApiKey, _secureStorage);
    _groqApiKey = await _secureStorage.read(
          key: ApiConstants.keyGroqApiKey,
        ) ??
        _migratePlainKey(
            prefs, ApiConstants.keyGroqApiKey, _secureStorage);

    // Non-sensitive settings stay in SharedPreferences.
    _defaultLocation =
        prefs.getString(ApiConstants.keyDefaultLocation) ?? 'Kochi';
    _notificationsEnabled =
        prefs.getBool(ApiConstants.keyNotificationsEnabled) ?? true;
    _favorites = prefs.getStringList(ApiConstants.keyFavorites) ?? [];

    for (final entry in ApiConstants.notifPreferenceKeys.entries) {
      _notifPrefs[entry.key] = prefs.getBool(entry.value) ?? true;
    }

    _incoisService.setApiKey(_incoisApiKey);
    notifyListeners();
  }

  /// Migrates a key from plain SharedPreferences to secure storage.
  /// Returns the migrated value, or empty string if not found.
  String _migratePlainKey(
    SharedPreferences prefs,
    String key,
    FlutterSecureStorage secure,
  ) {
    final value = prefs.getString(key) ?? '';
    if (value.isNotEmpty) {
      // Write to secure storage and remove from plain prefs asynchronously.
      secure.write(key: key, value: value);
      prefs.remove(key);
    }
    return value;
  }

  Future<void> loadLocations() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/tide_locations.json');
      final list = jsonDecode(raw) as List;
      _allLocations = list
          .map((e) => BeachLocation.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final loc in _allLocations) {
        loc.isFavorite = _favorites.contains(loc.name);
      }
      _locationsLoaded = true;
    } catch (_) {
      _locationsLoaded = false;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // GPS Location
  // ─────────────────────────────────────────────

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _locationPermissionDenied = true;
        _updateNearestLocations();
        notifyListeners();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _userLat = pos.latitude;
      _userLon = pos.longitude;
      _updateNearestLocations();
      notifyListeners();
    } catch (_) {
      _locationPermissionDenied = true;
      _updateNearestLocations();
      notifyListeners();
    }
  }

  Future<void> requestLocationPermission() async {
    _locationPermissionDenied = false;
    await _fetchUserLocation();
  }

  void _updateNearestLocations() {
    if (_allLocations.isEmpty) return;

    List<BeachLocation> sorted;
    if (_userLat != null && _userLon != null) {
      sorted = LocationUtils.sortByDistance(_allLocations, _userLat!, _userLon!);
    } else {
      sorted = List.from(_allLocations);
    }

    final previousNearest = _nearestLocation?.name;
    _nearestLocation = sorted.first;
    _nearestLocations = sorted.take(3).toList();
    _updateRecommendation();

    // Re-fetch tide and water quality when GPS first resolves or location changes
    if (_nearestLocation != null && _nearestLocation!.name != previousNearest) {
      refreshTideData(_nearestLocation!.name);
      refreshWaterQuality(_nearestLocation!.name);
    }
  }

  void _updateRecommendation() {
    if (_userLat == null || _userLon == null) return;
    if (_riskAssessment == null) return;
    _recommendation = LocationUtils.findSafeAlternative(
      allLocations: _allLocations,
      userLat: _userLat!,
      userLon: _userLon!,
      currentRisk: _riskAssessment!.level,
    );
  }

  // ─────────────────────────────────────────────
  // Data Refresh
  // ─────────────────────────────────────────────

  Future<void> refreshAll() async {
    final location = _nearestLocation?.name ?? _defaultLocation;
    await Future.wait([
      refreshWarnings(),
      refreshTideData(location),
      refreshWaterQuality(location),
    ]);
  }

  Future<void> refreshWarnings() async {
    _warningsLoading = true;
    _warningsError = null;
    notifyListeners();

    // Snapshot the current level before fetching so we can detect escalation
    final previousLevel = _riskAssessment?.level;

    try {
      final results = await Future.wait([
        _incoisService.getTsunamiWarning(),
        _incoisService.getStormSurgeWarning(),
        _incoisService.getHighWaveAlert(),
        _incoisService.getSwellSurgeAlert(),
        _incoisService.getCoastalCurrentAlert(),
      ]);
      _tsunami = results[0];
      _stormSurge = results[1];
      _highWave = results[2];
      _swellSurge = results[3];
      _coastalCurrents = results[4];

      _riskAssessment = RiskCalculator.calculate(
        tsunami: _tsunami,
        stormSurge: _stormSurge,
        highWave: _highWave,
        swellSurge: _swellSurge,
        coastalCurrents: _coastalCurrents,
      );

      _updatePredictions();

      for (final loc in _allLocations) {
        loc.riskLevel = _riskAssessment!.level;
      }
      _updateNearestLocations();

      // ── Notifications ──────────────────────────────────────────────────

      if (_notificationsEnabled) {
        // 1. Per-warning-type alerts (existing behaviour)
        for (final w in activeWarnings) {
          if (_notifPrefs[w.type] == true) {
            await _notificationService.showWarningNotification(w);
          }
        }

        // 2. Risk escalation alert — fires when level goes up
        final newLevel = _riskAssessment!.level;
        if (previousLevel != null &&
            newLevel.index > previousLevel.index) {
          await _notificationService.showRiskEscalationNotification(
            from: previousLevel,
            to: newLevel,
            location:
                _nearestLocation?.displayName ?? _defaultLocation,
          );
        }

        // 3. Predictive alert — fires at most once per hour for 6h/12h HIGH+
        await _checkPredictionAlerts();
      }

      // ── Firebase logging ───────────────────────────────────────────────
      _firebaseService.logRiskEvent(
        location: _nearestLocation?.name ?? _defaultLocation,
        riskLevel: _riskAssessment!.level.name,
        activeWarnings: _riskAssessment!.activeWarnings,
      );
    } catch (e) {
      _warningsError = 'Using demo data — check internet connection.';
      _tsunami = WarningData.noThreat('tsunami', 'Tsunami');
      _stormSurge = WarningData.noThreat('stormsurge', 'Storm Surge');
      _highWave = WarningData.noThreat('highwave', 'High Wave');
      _swellSurge = WarningData.noThreat('swellsurge', 'Swell Surge');
      _coastalCurrents =
          WarningData.noThreat('coastalcurrents', 'Coastal Current');
      _riskAssessment = RiskCalculator.calculate(
        tsunami: _tsunami,
        stormSurge: _stormSurge,
        highWave: _highWave,
        swellSurge: _swellSurge,
        coastalCurrents: _coastalCurrents,
      );
      _updatePredictions();
    } finally {
      _warningsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkPredictionAlerts() async {
    // Throttle: don't send more than one prediction alert per hour
    final now = DateTime.now();
    if (_lastPredictionAlertTime != null &&
        now.difference(_lastPredictionAlertTime!).inMinutes < 60) {
      return;
    }

    for (final pred in _riskPredictions) {
      // Only alert for 6h and 12h windows; the 2h window is too imminent
      if (pred.window == PredictionWindow.twoHours) continue;
      if (pred.predictedLevel.index >= RiskLevel.high.index) {
        await _notificationService.showPredictionAlertNotification(
          window: pred.windowLabel,
          level: pred.predictedLevel,
          location: _nearestLocation?.displayName ?? _defaultLocation,
        );
        _lastPredictionAlertTime = now;
        break; // One prediction alert per cycle is enough
      }
    }
  }

  void _updatePredictions() {
    _riskPredictions = RiskPredictor.predict(
      tideData: _tideData,
      tsunami: _tsunami,
      stormSurge: _stormSurge,
      highWave: _highWave,
      swellSurge: _swellSurge,
      coastalCurrents: _coastalCurrents,
    );
  }

  Future<void> refreshTideData(String location) async {
    _tideLoading = true;
    notifyListeners();
    try {
      _tideData = await _incoisService.getTidalData(location);
      _updatePredictions();
    } catch (_) {}
    _tideLoading = false;
    notifyListeners();
  }

  Future<void> refreshWaterQuality(String station) async {
    _wqLoading = true;
    notifyListeners();
    try {
      _waterQuality = await _incoisService.getWaterQuality(station);
    } catch (_) {
      _waterQuality = WaterQualityData.demo(station);
    }
    _wqLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Settings
  // ─────────────────────────────────────────────

  Future<void> saveSettings({
    String? incoisKey,
    String? geminiKey,
    String? groqKey,
    String? location,
    bool? notifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (incoisKey != null) {
      _incoisApiKey = incoisKey;
      // API keys go to encrypted secure storage only — never plain SharedPrefs.
      await _secureStorage.write(
          key: ApiConstants.keyIncoisApiKey, value: incoisKey);
      _incoisService.setApiKey(incoisKey);
    }
    if (geminiKey != null) {
      _geminiApiKey = geminiKey;
      await _secureStorage.write(
          key: ApiConstants.keyGeminiApiKey, value: geminiKey);
    }
    if (groqKey != null) {
      _groqApiKey = groqKey;
      await _secureStorage.write(
          key: ApiConstants.keyGroqApiKey, value: groqKey);
    }
    if (location != null) {
      _defaultLocation = location;
      await prefs.setString(ApiConstants.keyDefaultLocation, location);
    }
    if (notifications != null) {
      _notificationsEnabled = notifications;
      await prefs.setBool(ApiConstants.keyNotificationsEnabled, notifications);
    }

    // Sync non-sensitive settings to Firestore (no API keys in cloud)
    _firebaseService.saveUserSettings({
      'defaultLocation': _defaultLocation,
      'notificationsEnabled': _notificationsEnabled,
    });

    notifyListeners();
  }

  Future<void> setNotifPreference(String type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _notifPrefs[type] = enabled;
    final key = ApiConstants.notifPreferenceKeys[type];
    if (key != null) await prefs.setBool(key, enabled);
    notifyListeners();
  }

  Future<void> toggleFavorite(String locationName) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(locationName)) {
      _favorites.remove(locationName);
    } else {
      _favorites.add(locationName);
    }
    await prefs.setStringList(ApiConstants.keyFavorites, _favorites);
    for (final loc in _allLocations) {
      loc.isFavorite = _favorites.contains(loc.name);
    }
    // Sync favorites to Firestore
    _firebaseService.saveFavorites(_favorites);
    notifyListeners();
  }

  bool isFavorite(String name) => _favorites.contains(name);
}
