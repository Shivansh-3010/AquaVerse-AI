import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/water_quality_model.dart';

class WaterQualityGrid extends StatelessWidget {
  final WaterQualityData data;

  const WaterQualityGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final params = _buildParams();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science_rounded, color: AppColors.secondary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Water Quality',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _ratingColor(data.safetyRating).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _ratingColor(data.safetyRating).withOpacity(0.5)),
              ),
              child: Text(
                data.safetyRating,
                style: TextStyle(
                  color: _ratingColor(data.safetyRating),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Station: ${data.stationName}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: params.length,
          itemBuilder: (_, i) => _ParamTile(param: params[i]),
        ),
      ],
    );
  }

  List<_WQParam> _buildParams() {
    return [
      if (data.temperature != null)
        _WQParam(
          icon: Icons.thermostat_rounded,
          label: 'Temperature',
          value: '${data.temperature!.toStringAsFixed(1)} °C',
          color: AppColors.high,
        ),
      if (data.ph != null)
        _WQParam(
          icon: Icons.water_drop_rounded,
          label: 'pH Level',
          value: data.ph!.toStringAsFixed(2),
          color: AppColors.secondary,
        ),
      if (data.salinity != null)
        _WQParam(
          icon: Icons.grain_rounded,
          label: 'Salinity',
          value: '${data.salinity!.toStringAsFixed(1)} ppt',
          color: AppColors.accent,
        ),
      if (data.dissolvedOxygen != null)
        _WQParam(
          icon: Icons.bubble_chart_rounded,
          label: 'Dissolved O₂',
          value: '${data.dissolvedOxygen!.toStringAsFixed(1)} mg/L',
          color: AppColors.safe,
        ),
      if (data.currentSpeed != null)
        _WQParam(
          icon: Icons.speed_rounded,
          label: 'Current',
          value: '${data.currentSpeed!.toStringAsFixed(2)} m/s',
          color: AppColors.primary,
        ),
      if (data.chlorophyll != null)
        _WQParam(
          icon: Icons.eco_rounded,
          label: 'Chlorophyll',
          value: '${data.chlorophyll!.toStringAsFixed(2)} µg/L',
          color: const Color(0xFF52B788),
        ),
      if (data.turbidity != null)
        _WQParam(
          icon: Icons.blur_on_rounded,
          label: 'Turbidity',
          value: '${data.turbidity!.toStringAsFixed(1)} NTU',
          color: const Color(0xFFF4A261),
        ),
      if (data.pco2Air != null)
        _WQParam(
          icon: Icons.air_rounded,
          label: 'pCO₂ Air',
          value: '${data.pco2Air!.toStringAsFixed(0)} µatm',
          color: const Color(0xFF9D8DF1),
        ),
    ];
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Good':
        return AppColors.safe;
      case 'Caution':
        return AppColors.moderate;
      case 'Poor':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }
}

class _WQParam {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WQParam(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
}

class _ParamTile extends StatelessWidget {
  final _WQParam param;
  const _ParamTile({required this.param});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: param.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: param.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(param.icon, color: param.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  param.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  param.value,
                  style: TextStyle(
                    color: param.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
