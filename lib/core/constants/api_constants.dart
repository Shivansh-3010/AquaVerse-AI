class ApiConstants {
  // INCOIS Base URLs
  static const String incoisBase =
      'https://gemini.incois.gov.in/incoisapi/rest';
  static const String oceanDataBase =
      'https://gemini.incois.gov.in/OceanDataAPI/api';

  // Tidal APIs (no auth required)
  static String tidalUrl(String location) => '$incoisBase/tidal/$location';
  static String highLowUrl(String location) => '$incoisBase/high-low/$location';

  // Early Warning APIs (require Authorization: <API_KEY> header)
  static const String tsunamiUrl = '$incoisBase/tsunami';
  static const String stormSurgeLatestUrl = '$incoisBase/stormsurgelatest';
  static const String highWaveUrl = '$incoisBase/hwalatestgeo';
  static const String swellSurgeUrl = '$incoisBase/ssalatestgeo';
  static const String coastalCurrentsUrl = '$incoisBase/currentslatestgeo';

  // Water Quality NowCast (requires Authorization: <API_KEY> header)
  static String waterQualityUrl(String station, String parameter) =>
      '$oceanDataBase/wqns/$station/$parameter';

  // Water Quality Stations
  static const List<String> wqStations = ['Kochi', 'Vizag'];

  // Water Quality Parameters
  static const List<String> wqParameters = [
    'currentspeed',
    'currentdirection',
    'ph',
    'salinity',
    'temperature',
    'dissolvedoxygen',
    'chlorophyll',
    'turbidity',
  ];

  // Timeouts
  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 20000; // ms

  // Groq (free-tier LLM alternative to Gemini)
  static const String groqChatUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.1-8b-instant';

  // SharedPreferences keys
  static const String keyIncoisApiKey = 'incois_api_key';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGroqApiKey = 'groq_api_key';
  static const String keyDefaultLocation = 'default_location';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyFavorites = 'favorite_locations';

  // Per-type notification toggle keys
  static const String keyNotifTsunami = 'notif_tsunami';
  static const String keyNotifStormSurge = 'notif_stormsurge';
  static const String keyNotifHighWave = 'notif_highwave';
  static const String keyNotifSwellSurge = 'notif_swellsurge';
  static const String keyNotifCoastalCurrents = 'notif_coastalcurrents';

  static const Map<String, String> notifPreferenceKeys = {
    'tsunami': keyNotifTsunami,
    'stormsurge': keyNotifStormSurge,
    'highwave': keyNotifHighWave,
    'swellsurge': keyNotifSwellSurge,
    'coastalcurrents': keyNotifCoastalCurrents,
  };
}
