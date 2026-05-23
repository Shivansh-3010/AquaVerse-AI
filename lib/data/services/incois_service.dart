import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/tide_model.dart';
import '../models/warning_model.dart';
import '../models/water_quality_model.dart';

class IncoisService {
  String? _apiKey;

  void setApiKey(String key) => _apiKey = key.trim().isEmpty ? null : key.trim();

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_apiKey != null) {
      h['Authorization'] = _apiKey!;
    }
    return h;
  }

  // ─────────────────────────────────────────────
  // Tidal Data
  // ─────────────────────────────────────────────

  Future<TideLocationData> getTidalData(String location) async {
    try {
      final url = ApiConstants.tidalUrl(location);
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(milliseconds: ApiConstants.receiveTimeout));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded.containsKey('predictions')) {
          list = decoded['predictions'] as List;
        }
        final points = list
            .map((e) => TideDataPoint.fromJson(e as Map<String, dynamic>))
            .toList();
        final highLow = await _getHighLowTides(location);
        return TideLocationData(
          locationName: location,
          dataPoints: points,
          highLowTides: highLow,
          fetchedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // fall through to demo data
    }
    return _mockTideData(location);
  }

  Future<List<HighLowTide>> _getHighLowTides(String location) async {
    try {
      final url = ApiConstants.highLowUrl(location);
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(milliseconds: ApiConstants.receiveTimeout));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = decoded is List ? decoded : [];
        return list
            .map((e) => HighLowTide.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _mockHighLowTides();
  }

  // ─────────────────────────────────────────────
  // Early Warnings
  // ─────────────────────────────────────────────

  Future<WarningData> getTsunamiWarning() =>
      _fetchWarning(ApiConstants.tsunamiUrl, 'tsunami', 'Tsunami');

  Future<WarningData> getStormSurgeWarning() =>
      _fetchWarning(ApiConstants.stormSurgeLatestUrl, 'stormsurge', 'Storm Surge');

  Future<WarningData> getHighWaveAlert() =>
      _fetchWarning(ApiConstants.highWaveUrl, 'highwave', 'High Wave');

  Future<WarningData> getSwellSurgeAlert() =>
      _fetchWarning(ApiConstants.swellSurgeUrl, 'swellsurge', 'Swell Surge');

  Future<WarningData> getCoastalCurrentAlert() =>
      _fetchWarning(ApiConstants.coastalCurrentsUrl, 'coastalcurrents', 'Coastal Current');

  Future<WarningData> _fetchWarning(
      String url, String type, String typeName) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(milliseconds: ApiConstants.receiveTimeout));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return WarningData.fromJson(json, type, typeName);
      }
    } catch (_) {}
    return WarningData.noThreat(type, typeName);
  }

  // ─────────────────────────────────────────────
  // Water Quality
  // ─────────────────────────────────────────────

  Future<WaterQualityData> getWaterQuality(String station) async {
    final params = <String, dynamic>{};
    // Fetch each parameter in parallel
    await Future.wait(ApiConstants.wqParameters.map((param) async {
      try {
        final url = ApiConstants.waterQualityUrl(station, param);
        final res = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(milliseconds: ApiConstants.receiveTimeout));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          params[param] = WaterQualityData.parseLatestValue(json, param);
        }
      } catch (_) {}
    }));

    if (params.isEmpty) return WaterQualityData.demo(station);
    return WaterQualityData.fromParameterMap(station, params);
  }

  // ─────────────────────────────────────────────
  // Mock / Demo Data Fallbacks
  // ─────────────────────────────────────────────

  TideLocationData _mockTideData(String location) {
    final now = DateTime.now().copyWith(minute: 0, second: 0, millisecond: 0);
    final points = List.generate(48, (i) {
      final t = now.add(Duration(hours: i - 12));
      // Realistic tidal sine wave (semi-diurnal, ~12.4h period)
      final rad = (i * 2 * pi) / 12.4;
      final v = 1.2 + 0.9 * sin(rad) + 0.15 * sin(2 * rad);
      return TideDataPoint(timestamp: t, value: double.parse(v.toStringAsFixed(2)));
    });

    return TideLocationData(
      locationName: location,
      dataPoints: points,
      highLowTides: _mockHighLowTides(),
      fetchedAt: DateTime.now(),
    );
  }

  List<HighLowTide> _mockHighLowTides() {
    final now = DateTime.now();
    return [
      HighLowTide(
          timestamp: now.add(const Duration(hours: 2)),
          value: 2.10,
          type: TideType.high),
      HighLowTide(
          timestamp: now.add(const Duration(hours: 8)),
          value: 0.35,
          type: TideType.low),
      HighLowTide(
          timestamp: now.add(const Duration(hours: 14)),
          value: 1.85,
          type: TideType.high),
      HighLowTide(
          timestamp: now.add(const Duration(hours: 20)),
          value: 0.42,
          type: TideType.low),
    ];
  }
}
