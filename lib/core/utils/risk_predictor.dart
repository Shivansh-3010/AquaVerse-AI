import '../../data/models/tide_model.dart';
import '../../data/models/warning_model.dart';
import 'risk_calculator.dart';

enum PredictionWindow { twoHours, sixHours, twelveHours }

class RiskPrediction {
  final PredictionWindow window;
  final RiskLevel predictedLevel;
  final double confidence; // 0.0 – 1.0
  final String insight;
  final double predictedTideHeight;

  const RiskPrediction({
    required this.window,
    required this.predictedLevel,
    required this.confidence,
    required this.insight,
    required this.predictedTideHeight,
  });

  String get windowLabel {
    switch (window) {
      case PredictionWindow.twoHours:
        return 'In 2 hours';
      case PredictionWindow.sixHours:
        return 'In 6 hours';
      case PredictionWindow.twelveHours:
        return 'In 12 hours';
    }
  }
}

/// Rule-based ML risk prediction engine.
/// Uses tide forecast data + current warning state to predict
/// future risk levels for 2h, 6h and 12h windows.
class RiskPredictor {
  static List<RiskPrediction> predict({
    required TideLocationData? tideData,
    required WarningData? tsunami,
    required WarningData? stormSurge,
    required WarningData? highWave,
    required WarningData? swellSurge,
    required WarningData? coastalCurrents,
  }) {
    return [
      _predictWindow(
        PredictionWindow.twoHours,
        2,
        tideData: tideData,
        tsunami: tsunami,
        stormSurge: stormSurge,
        highWave: highWave,
        swellSurge: swellSurge,
        coastalCurrents: coastalCurrents,
      ),
      _predictWindow(
        PredictionWindow.sixHours,
        6,
        tideData: tideData,
        tsunami: tsunami,
        stormSurge: stormSurge,
        highWave: highWave,
        swellSurge: swellSurge,
        coastalCurrents: coastalCurrents,
      ),
      _predictWindow(
        PredictionWindow.twelveHours,
        12,
        tideData: tideData,
        tsunami: tsunami,
        stormSurge: stormSurge,
        highWave: highWave,
        swellSurge: swellSurge,
        coastalCurrents: coastalCurrents,
      ),
    ];
  }

  static RiskPrediction _predictWindow(
    PredictionWindow window,
    int hoursAhead, {
    required TideLocationData? tideData,
    required WarningData? tsunami,
    required WarningData? stormSurge,
    required WarningData? highWave,
    required WarningData? swellSurge,
    required WarningData? coastalCurrents,
  }) {
    final targetTime = DateTime.now().add(Duration(hours: hoursAhead));
    double tideHeight = 1.0;
    double riskScore = 0.0; // 0.0 = safe, 1.0 = maximum danger

    // ── Feature 1: Predicted tide height at target time ──────────────
    if (tideData != null && tideData.dataPoints.isNotEmpty) {
      TideDataPoint closest = tideData.dataPoints.first;
      int minDiff = (closest.timestamp.difference(targetTime).inMinutes).abs();
      for (final dp in tideData.dataPoints) {
        final diff = (dp.timestamp.difference(targetTime).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = dp;
        }
      }
      tideHeight = closest.value;

      // High tide (>1.5m) increases risk score
      if (tideHeight > 2.0) {
        riskScore += 0.25;
      } else if (tideHeight > 1.5) {
        riskScore += 0.15;
      } else if (tideHeight < 0.5) {
        riskScore -= 0.05; // Low tide is somewhat safer
      }

      // Check if a HIGH tide is approaching within the window
      final upcomingHighTides = tideData.highLowTides.where((t) =>
          t.isHigh &&
          t.timestamp.isAfter(DateTime.now()) &&
          t.timestamp.isBefore(targetTime.add(const Duration(hours: 2))));
      if (upcomingHighTides.isNotEmpty) {
        final maxHighTide = upcomingHighTides
            .map((t) => t.value)
            .reduce((a, b) => a > b ? a : b);
        if (maxHighTide > 2.2) riskScore += 0.2;
        if (maxHighTide > 1.8) riskScore += 0.1;
      }
    }

    // ── Feature 2: Active warnings (persist into prediction) ─────────
    riskScore += _warningContribution(tsunami, 0.40);
    riskScore += _warningContribution(stormSurge, 0.35);
    riskScore += _warningContribution(highWave, 0.30);
    riskScore += _warningContribution(swellSurge, 0.20);
    riskScore += _warningContribution(coastalCurrents, 0.15);

    // ── Feature 3: Time of day factor ────────────────────────────────
    final hour = targetTime.hour;
    if (hour >= 22 || hour <= 5) {
      riskScore += 0.05; // Night swimming inherently riskier
    }

    // ── Feature 4: Decay factor — farther predictions are less certain ─
    final decayFactor = 1.0 - (hoursAhead / 24) * 0.2;
    riskScore = (riskScore * decayFactor).clamp(0.0, 1.0);

    // ── Map score to risk level ───────────────────────────────────────
    RiskLevel level;
    if (riskScore >= 0.65) {
      level = RiskLevel.danger;
    } else if (riskScore >= 0.40) {
      level = RiskLevel.high;
    } else if (riskScore >= 0.20) {
      level = RiskLevel.moderate;
    } else {
      level = RiskLevel.safe;
    }

    final confidence = ((1.0 - (hoursAhead / 24) * 0.3) * 100).round() / 100;

    return RiskPrediction(
      window: window,
      predictedLevel: level,
      confidence: confidence.clamp(0.0, 1.0),
      insight: _buildInsight(level, tideHeight, hoursAhead),
      predictedTideHeight: tideHeight,
    );
  }

  static double _warningContribution(WarningData? warning, double max) {
    if (warning == null) return 0.0;
    switch (warning.threatLevel) {
      case ThreatLevel.warning:
        return max;
      case ThreatLevel.alert:
        return max * 0.65;
      case ThreatLevel.watch:
        return max * 0.3;
      case ThreatLevel.noThreat:
        return 0.0;
    }
  }

  static String _buildInsight(
      RiskLevel level, double tideHeight, int hoursAhead) {
    final timeStr = hoursAhead == 2
        ? 'the next 2 hours'
        : hoursAhead == 6
            ? '6 hours from now'
            : '12 hours from now';

    switch (level) {
      case RiskLevel.safe:
        return 'Conditions expected to remain favorable in $timeStr. Tide at ~${tideHeight.toStringAsFixed(1)}m.';
      case RiskLevel.moderate:
        return 'Moderate risk expected in $timeStr. Exercise caution. Predicted tide ~${tideHeight.toStringAsFixed(1)}m.';
      case RiskLevel.high:
        return 'High risk forecast for $timeStr. Avoid water activities. Tide predicted at ~${tideHeight.toStringAsFixed(1)}m.';
      case RiskLevel.danger:
        return 'Dangerous conditions expected in $timeStr. Stay away from coastal areas.';
    }
  }
}
