import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/tide_model.dart';

class TideChartWidget extends StatelessWidget {
  final TideLocationData tideData;
  final double height;

  const TideChartWidget({
    super.key,
    required this.tideData,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (tideData.dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No tide data available',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    // Use next 24 hours of data
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    final points = tideData.dataPoints
        .where((p) => p.timestamp.isAfter(now.subtract(const Duration(hours: 2))) &&
            p.timestamp.isBefore(cutoff))
        .toList();

    if (points.isEmpty) return const SizedBox.shrink();

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = (points.map((p) => p.value).reduce((a, b) => a < b ? a : b) - 0.2)
        .clamp(0.0, 10.0);
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b) + 0.2;

    // Find "now" index
    int nowIdx = 0;
    int minDiff = 999999;
    for (int i = 0; i < points.length; i++) {
      final diff = (points[i].timestamp.difference(now).inMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nowIdx = i;
      }
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 6).floorToDouble().clamp(1, 100),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox();
                  return Text(
                    DateFormat('HH:mm').format(points[idx].timestamp),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: nowIdx.toDouble(),
                color: AppColors.accent.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [4, 4],
                label: VerticalLineLabel(
                  show: true,
                  labelResolver: (_) => 'Now',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  alignment: Alignment.topRight,
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.secondary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.secondary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardDark,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(2)} m\n',
                      const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      children: [
                        TextSpan(
                          text: DateFormat('HH:mm')
                              .format(points[s.x.toInt()].timestamp),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
