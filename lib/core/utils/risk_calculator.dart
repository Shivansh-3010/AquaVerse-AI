import 'package:flutter/material.dart';
import '../../data/models/warning_model.dart';
import '../constants/app_colors.dart';

enum RiskLevel { safe, moderate, high, danger }

class RiskAssessment {
  final RiskLevel level;
  final String title;
  final String subtitle;
  final String recommendation;
  final Color color;
  final IconData icon;
  final List<String> activeWarnings;

  const RiskAssessment({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.recommendation,
    required this.color,
    required this.icon,
    required this.activeWarnings,
  });
}

class RiskCalculator {
  static RiskAssessment calculate({
    required WarningData? tsunami,
    required WarningData? stormSurge,
    required WarningData? highWave,
    required WarningData? swellSurge,
    required WarningData? coastalCurrents,
  }) {
    final List<String> warnings = [];
    RiskLevel level = RiskLevel.safe;

    // Tsunami — highest priority
    if (tsunami != null && tsunami.threatLevel != ThreatLevel.noThreat) {
      warnings.add('Tsunami ${tsunami.threatLevel.label}');
      if (tsunami.threatLevel == ThreatLevel.warning) {
        level = RiskLevel.danger;
      } else if (level.index < RiskLevel.high.index) {
        level = RiskLevel.high;
      }
    }

    // Storm Surge
    if (stormSurge != null && stormSurge.threatLevel != ThreatLevel.noThreat) {
      warnings.add('Storm Surge ${stormSurge.threatLevel.label}');
      if (stormSurge.threatLevel == ThreatLevel.warning &&
          level.index < RiskLevel.danger.index) {
        level = RiskLevel.danger;
      } else if (stormSurge.threatLevel == ThreatLevel.alert &&
          level.index < RiskLevel.high.index) {
        level = RiskLevel.high;
      } else if (level.index < RiskLevel.moderate.index) {
        level = RiskLevel.moderate;
      }
    }

    // High Wave
    if (highWave != null && highWave.threatLevel != ThreatLevel.noThreat) {
      warnings.add('High Wave ${highWave.threatLevel.label}');
      if (highWave.threatLevel == ThreatLevel.warning &&
          level.index < RiskLevel.high.index) {
        level = RiskLevel.high;
      } else if (level.index < RiskLevel.moderate.index) {
        level = RiskLevel.moderate;
      }
    }

    // Swell Surge
    if (swellSurge != null && swellSurge.threatLevel != ThreatLevel.noThreat) {
      warnings.add('Swell Surge ${swellSurge.threatLevel.label}');
      if (level.index < RiskLevel.moderate.index) {
        level = RiskLevel.moderate;
      }
    }

    // Coastal Currents
    if (coastalCurrents != null &&
        coastalCurrents.threatLevel != ThreatLevel.noThreat) {
      warnings.add('Coastal Current ${coastalCurrents.threatLevel.label}');
      if (level.index < RiskLevel.moderate.index) {
        level = RiskLevel.moderate;
      }
    }

    return _buildAssessment(level, warnings);
  }

  static RiskAssessment _buildAssessment(
      RiskLevel level, List<String> warnings) {
    switch (level) {
      case RiskLevel.danger:
        return RiskAssessment(
          level: level,
          title: 'DANGER',
          subtitle: 'Do NOT Enter Water',
          recommendation:
              'Severe ocean hazards detected. Stay away from the beach and coastal areas. Follow local authority instructions immediately.',
          color: AppColors.danger,
          icon: Icons.dangerous_rounded,
          activeWarnings: warnings,
        );
      case RiskLevel.high:
        return RiskAssessment(
          level: level,
          title: 'HIGH RISK',
          subtitle: 'Extreme Caution Required',
          recommendation:
              'High ocean threat detected. Avoid water activities. Keep children away from the shore. Monitor updates closely.',
          color: AppColors.high,
          icon: Icons.warning_rounded,
          activeWarnings: warnings,
        );
      case RiskLevel.moderate:
        return RiskAssessment(
          level: level,
          title: 'MODERATE RISK',
          subtitle: 'Exercise Caution',
          recommendation:
              'Some ocean hazards present. Only experienced swimmers should enter water. Stay within designated swimming zones.',
          color: AppColors.moderate,
          icon: Icons.info_rounded,
          activeWarnings: warnings,
        );
      case RiskLevel.safe:
        return RiskAssessment(
          level: level,
          title: 'SAFE',
          subtitle: 'Conditions Favorable',
          recommendation:
              'No active ocean threats detected. Enjoy the beach safely. Always swim near lifeguards and follow posted guidelines.',
          color: AppColors.safe,
          icon: Icons.check_circle_rounded,
          activeWarnings: ['No active warnings'],
        );
    }
  }

  static Color getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return AppColors.safe;
      case RiskLevel.moderate:
        return AppColors.moderate;
      case RiskLevel.high:
        return AppColors.high;
      case RiskLevel.danger:
        return AppColors.danger;
    }
  }
}
