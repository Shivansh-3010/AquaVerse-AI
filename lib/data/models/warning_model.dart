import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ThreatLevel { noThreat, watch, alert, warning }

extension ThreatLevelExtension on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.noThreat:
        return 'No Threat';
      case ThreatLevel.watch:
        return 'Watch';
      case ThreatLevel.alert:
        return 'Alert';
      case ThreatLevel.warning:
        return 'Warning';
    }
  }

  Color get color {
    switch (this) {
      case ThreatLevel.noThreat:
        return AppColors.safe;
      case ThreatLevel.watch:
        return AppColors.moderate;
      case ThreatLevel.alert:
        return AppColors.high;
      case ThreatLevel.warning:
        return AppColors.danger;
    }
  }
}

class WarningData {
  final String type;       // 'tsunami', 'stormsurge', 'highwave', 'swellsurge', 'coastalcurrents'
  final String typeName;   // Human-readable type name
  final ThreatLevel threatLevel;
  final String message;
  final DateTime lastUpdated;
  final Map<String, dynamic>? rawData;

  const WarningData({
    required this.type,
    required this.typeName,
    required this.threatLevel,
    required this.message,
    required this.lastUpdated,
    this.rawData,
  });

  factory WarningData.noThreat(String type, String typeName) {
    return WarningData(
      type: type,
      typeName: typeName,
      threatLevel: ThreatLevel.noThreat,
      message: 'No active $typeName advisory.',
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse from INCOIS GeoJSON / REST response
  factory WarningData.fromJson(
      Map<String, dynamic> json, String type, String typeName) {
    // INCOIS uses colour codes: GREEN, YELLOW, ORANGE, RED
    ThreatLevel level = ThreatLevel.noThreat;
    String msg = 'No active advisory.';

    try {
      // The response varies by API — look for common fields
      final dynamic features = json['features'];
      if (features is List && features.isNotEmpty) {
        final props = features[0]['properties'] as Map<String, dynamic>?;
        if (props != null) {
          final colour = (props['COLOUR'] ?? props['colour'] ?? '').toString().toUpperCase();
          msg = props['ADVISORY'] ?? props['advisory'] ?? props['message'] ?? msg;
          if (colour == 'RED') {
            level = ThreatLevel.warning;
          } else if (colour == 'ORANGE') {
            level = ThreatLevel.alert;
          } else if (colour == 'YELLOW') {
            level = ThreatLevel.watch;
          }
        }
      }
    } catch (_) {}

    return WarningData(
      type: type,
      typeName: typeName,
      threatLevel: level,
      message: msg.isNotEmpty ? msg : 'No active $typeName advisory.',
      lastUpdated: DateTime.now(),
      rawData: json,
    );
  }

  IconData get icon {
    switch (type) {
      case 'tsunami':
        return Icons.waves_rounded;
      case 'stormsurge':
        return Icons.storm_rounded;
      case 'highwave':
        return Icons.water_rounded;
      case 'swellsurge':
        return Icons.waterfall_chart_rounded;
      case 'coastalcurrents':
        return Icons.air_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
