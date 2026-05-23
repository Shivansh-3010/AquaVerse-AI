import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/warning_model.dart';

class WarningCard extends StatelessWidget {
  final WarningData warning;
  final bool expanded;

  const WarningCard({
    super.key,
    required this.warning,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning.threatLevel.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(warning.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning.typeName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Updated: ${DateFormat('dd MMM, HH:mm').format(warning.lastUpdated)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _ThreatBadge(level: warning.threatLevel),
              ],
            ),
          ),
          // Body
          if (expanded || warning.threatLevel != ThreatLevel.noThreat)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                warning.message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreatBadge extends StatelessWidget {
  final ThreatLevel level;
  const _ThreatBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withOpacity(0.6)),
      ),
      child: Text(
        level.label.toUpperCase(),
        style: TextStyle(
          color: level.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
