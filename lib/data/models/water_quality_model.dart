class WaterQualityData {
  final String stationName;
  final DateTime lastReported;
  final double? ph;
  final double? salinity;
  final double? temperature;
  final double? dissolvedOxygen;
  final double? currentSpeed;
  final String? currentDirection;
  final double? chlorophyll;
  final double? turbidity;
  final double? dissolvedMethane;
  final double? pco2Air;
  final double? pco2Water;

  const WaterQualityData({
    required this.stationName,
    required this.lastReported,
    this.ph,
    this.salinity,
    this.temperature,
    this.dissolvedOxygen,
    this.currentSpeed,
    this.currentDirection,
    this.chlorophyll,
    this.turbidity,
    this.dissolvedMethane,
    this.pco2Air,
    this.pco2Water,
  });

  factory WaterQualityData.fromParameterMap(
      String station, Map<String, dynamic> params) {
    return WaterQualityData(
      stationName: station,
      lastReported: DateTime.now(),
      ph: params['ph'] as double?,
      salinity: params['salinity'] as double?,
      temperature: params['temperature'] as double?,
      dissolvedOxygen: params['dissolvedoxygen'] as double?,
      currentSpeed: params['currentspeed'] as double?,
      currentDirection: params['currentdirection'] as String?,
      chlorophyll: params['chlorophyll'] as double?,
      turbidity: params['turbidity'] as double?,
      dissolvedMethane: params['dissolvedmethane'] as double?,
      pco2Air: params['pco2air'] as double?,
      pco2Water: params['pco2water'] as double?,
    );
  }

  /// Parse a single parameter API response to get latest value
  static double? parseLatestValue(Map<String, dynamic> json, String parameter) {
    try {
      final values = json[parameter] as List?;
      if (values != null && values.isNotEmpty) {
        return double.tryParse(values.first.toString());
      }
    } catch (_) {}
    return null;
  }

  /// Mock demo data for when API is unavailable
  factory WaterQualityData.demo(String station) {
    return WaterQualityData(
      stationName: station,
      lastReported: DateTime.now(),
      ph: 8.1,
      salinity: 35.2,
      temperature: 28.4,
      dissolvedOxygen: 6.8,
      currentSpeed: 0.45,
      currentDirection: 'NE',
      chlorophyll: 0.82,
      turbidity: 1.2,
      dissolvedMethane: 2.3,
      pco2Air: 412.0,
      pco2Water: 398.5,
    );
  }

  String get safetyRating {
    if (ph == null) return 'Unknown';
    if (ph! < 7.8 || ph! > 8.5) return 'Caution';
    if (turbidity != null && turbidity! > 5.0) return 'Poor';
    return 'Good';
  }
}
