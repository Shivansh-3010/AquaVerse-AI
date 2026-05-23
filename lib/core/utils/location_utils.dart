import 'dart:math';
import '../../data/models/beach_location_model.dart';
import '../../core/utils/risk_calculator.dart';

class LocationUtils {
  /// Haversine formula — returns distance in km between two lat/lon points
  static double distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Returns locations sorted by distance from given lat/lon
  static List<BeachLocation> sortByDistance(
    List<BeachLocation> locations,
    double userLat,
    double userLon,
  ) {
    final sorted = [...locations];
    sorted.sort((a, b) {
      final dA = distanceKm(userLat, userLon, a.latitude, a.longitude);
      final dB = distanceKm(userLat, userLon, b.latitude, b.longitude);
      return dA.compareTo(dB);
    });
    return sorted;
  }

  /// Find the nearest safe beach when current area has elevated risk.
  /// Returns null if current location is already safe.
  static BeachRecommendation? findSafeAlternative({
    required List<BeachLocation> allLocations,
    required double userLat,
    required double userLon,
    required RiskLevel currentRisk,
    int searchRadiusKm = 500,
  }) {
    if (currentRisk == RiskLevel.safe) return null;

    final sorted = sortByDistance(allLocations, userLat, userLon);
    final nearest = sorted.isNotEmpty ? sorted.first : null;

    // Find nearest safe location within radius
    final safeOptions = sorted
        .where((loc) =>
            loc.riskLevel == RiskLevel.safe &&
            distanceKm(userLat, userLon, loc.latitude, loc.longitude) <=
                searchRadiusKm)
        .take(3)
        .toList();

    if (safeOptions.isEmpty) return null;

    final best = safeOptions.first;
    final distKm =
        distanceKm(userLat, userLon, best.latitude, best.longitude);

    return BeachRecommendation(
      currentNearest: nearest,
      recommendedLocation: best,
      distanceFromUserKm: distKm,
      currentRisk: currentRisk,
      reason: _buildReason(currentRisk, best.displayName),
    );
  }

  static String _buildReason(RiskLevel risk, String destName) {
    switch (risk) {
      case RiskLevel.danger:
        return 'Life-threatening conditions in your area. $destName has safe conditions and is the nearest alternative.';
      case RiskLevel.high:
        return 'High ocean risk near you. $destName offers significantly safer conditions for coastal activities.';
      case RiskLevel.moderate:
        return 'Moderate risk in your area. $destName has calmer conditions for a safer beach experience.';
      case RiskLevel.safe:
        return '';
    }
  }
}

class BeachRecommendation {
  final BeachLocation? currentNearest;
  final BeachLocation recommendedLocation;
  final double distanceFromUserKm;
  final RiskLevel currentRisk;
  final String reason;

  const BeachRecommendation({
    required this.currentNearest,
    required this.recommendedLocation,
    required this.distanceFromUserKm,
    required this.currentRisk,
    required this.reason,
  });
}
