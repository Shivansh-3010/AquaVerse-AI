import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/risk_calculator.dart';
import '../../../core/utils/risk_predictor.dart';
import '../../../data/models/warning_model.dart';
import '../../../data/providers/app_provider.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/risk_level_card.dart';
import '../../widgets/warning_card.dart';
import '../beach_detail/beach_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // ── Animated Ocean Background ─────────────────────────
              _buildOceanBackground(provider),

              // ── Top overlay: header card ───────────────────────────
              _buildTopOverlay(context, provider),

              // ── Floating action buttons ────────────────────────────
              _buildFabColumn(context, provider),

              // ── Bottom draggable panel ─────────────────────────────
              _buildBottomPanel(context, provider),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Animated Ocean Background
  // ─────────────────────────────────────────────

  Widget _buildOceanBackground(AppProvider provider) {
    final riskColor = provider.riskAssessment?.color ?? AppColors.safe;
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _OceanWavePainter(
          progress: _waveController.value,
          riskColor: riskColor,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Top Overlay
  // ─────────────────────────────────────────────

  Widget _buildTopOverlay(BuildContext context, AppProvider provider) {
    final riskColor = provider.riskAssessment?.color ?? AppColors.safe;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: riskColor.withOpacity(0.4), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Wave icon + title
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_rounded,
                    color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AquaVerse',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.textMuted, size: 11),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            provider.nearestLocation?.displayName ??
                                provider.defaultLocation,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Risk badge + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (provider.riskAssessment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.riskAssessment!.title,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Floating Action Buttons
  // ─────────────────────────────────────────────

  Widget _buildFabColumn(BuildContext context, AppProvider provider) {
    return Positioned(
      right: 14,
      bottom: 300,
      child: _MapFab(
        icon: Icons.refresh_rounded,
        tooltip: 'Refresh data',
        onTap: provider.warningsLoading ? null : provider.refreshAll,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Bottom Panel
  // ─────────────────────────────────────────────

  Widget _buildBottomPanel(BuildContext context, AppProvider provider) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.38,
      minChildSize: 0.16,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.96),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
                top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: RefreshIndicator(
            color: AppColors.secondary,
            backgroundColor: AppColors.cardDark,
            onRefresh: provider.refreshAll,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80),
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Demo data banner ──────────────────────────
                      const DemoBanner(),
                      // ── Shimmer while initial load ────────────────
                      if (provider.warningsLoading &&
                          provider.riskAssessment == null)
                        _buildLoadingPlaceholder()
                      else ...[
                        // ── Stats row ─────────────────────────────────
                        _buildStatsRow(provider),
                        const SizedBox(height: 16),
                        // ── Risk card ─────────────────────────────────
                        if (provider.riskAssessment != null) ...[
                          RiskLevelCard(assessment: provider.riskAssessment!),
                          const SizedBox(height: 16),
                        ],
                        // ── Smart recommendation ──────────────────────
                        if (provider.recommendation != null) ...[
                          _buildRecommendationCard(context, provider),
                          const SizedBox(height: 16),
                        ],
                        // ── Nearby locations ──────────────────────────
                        if (provider.nearestLocations.isNotEmpty) ...[
                          _buildNearbySpotsSection(context, provider),
                          const SizedBox(height: 16),
                        ],
                        // ── Risk predictions ──────────────────────────
                        if (provider.riskPredictions.isNotEmpty) ...[
                          _buildPredictionsSection(provider),
                          const SizedBox(height: 16),
                        ],
                        // ── Active warnings ───────────────────────────
                        _buildWarningsSection(provider),
                        const SizedBox(height: 16),
                        // ── Mini tide chart ───────────────────────────
                        _buildMiniTideChart(provider),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(AppProvider provider) {
    final tide = provider.tideData;
    final wq = provider.waterQuality;
    final activeCount = provider.activeWarnings.length;

    return Row(
      children: [
        Expanded(
          child: _GlassStat(
            icon: Icons.water_rounded,
            label: 'Tide',
            value: tide != null ? '${tide.currentTide.toStringAsFixed(1)}m' : '--',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassStat(
            icon: Icons.thermostat_rounded,
            label: 'Temp',
            value: wq?.temperature != null
                ? '${wq!.temperature!.toStringAsFixed(0)}°C'
                : '--',
            color: AppColors.high,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassStat(
            icon: Icons.warning_amber_rounded,
            label: 'Alerts',
            value: '$activeCount',
            color: activeCount > 0 ? AppColors.danger : AppColors.safe,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlassStat(
            icon: Icons.speed_rounded,
            label: 'Current',
            value: wq?.currentSpeed != null
                ? '${wq!.currentSpeed!.toStringAsFixed(1)}m/s'
                : '--',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, AppProvider provider) {
    final rec = provider.recommendation!;
    final riskColor = RiskCalculator.getRiskColor(rec.currentRisk);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            BeachDetailScreen(location: rec.recommendedLocation),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.safe.withOpacity(0.15),
              AppColors.safe.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.safe.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.near_me_rounded,
                      color: AppColors.safe, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Smart Recommendation',
                  style: TextStyle(
                    color: AppColors.safe,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rec.currentRisk.name.toUpperCase(),
                    style: TextStyle(
                        color: riskColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              rec.reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.place_rounded,
                    color: AppColors.safe, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.recommendedLocation.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${rec.distanceFromUserKm.toStringAsFixed(0)} km away',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_graph_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            const Text(
              'AI Risk Forecast',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ML',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: provider.riskPredictions
              .map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PredictionTile(prediction: p),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildWarningsSection(AppProvider provider) {
    final warnings = provider.allWarnings;
    if (warnings.isEmpty) return const SizedBox.shrink();

    final active =
        warnings.where((w) => w.threatLevel != ThreatLevel.noThreat).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Early Warnings',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (active.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.4)),
                ),
                child: Text(
                  '${active.length} ACTIVE',
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (active.isNotEmpty)
          ...active.map((w) => WarningCard(warning: w, expanded: true))
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.safe.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.safe, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No active ocean advisories. Conditions are currently safe.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMiniTideChart(AppProvider provider) {
    if (provider.tideData == null || provider.tideData!.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = provider.tideData!.dataPoints;
    final now = DateTime.now();
    final next24 = points
        .where((p) =>
            p.timestamp.isAfter(now.subtract(const Duration(hours: 2))) &&
            p.timestamp
                .isBefore(now.add(const Duration(hours: 22))))
        .toList();

    if (next24.length < 3) return const SizedBox.shrink();

    final spots = next24
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            Text(
              'Tide Forecast — ${provider.nearestLocation?.displayName ?? provider.defaultLocation}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 110,
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.5,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.5,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (next24.length / 4).floorToDouble().clamp(1, 50),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= next24.length) {
                        return const SizedBox();
                      }
                      return Text(
                        DateFormat('HH:mm').format(next24[i].timestamp),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 8),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.secondary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.secondary.withOpacity(0.25),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Nearby Safe Spots
  // ─────────────────────────────────────────────

  Widget _buildNearbySpotsSection(
      BuildContext context, AppProvider provider) {
    final spots = provider.nearestLocations;
    if (spots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Nearby Locations',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: spots.map((loc) {
            final riskColor = RiskCalculator.getRiskColor(loc.riskLevel);
            final hasGps = provider.hasUserLocation;
            final distKm = hasGps
                ? LocationUtils.distanceKm(
                    provider.userLat!, provider.userLon!,
                    loc.latitude, loc.longitude)
                : null;

            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => BeachDetailScreen(location: loc)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (distKm != null)
                      Text(
                        '${distKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.riskLevel.name.toUpperCase(),
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 16),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Shimmer Loading Placeholder
  // ─────────────────────────────────────────────

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 72, height: 56),
              const SizedBox(width: 8),
              _shimmerBox(width: 72, height: 56),
              const SizedBox(width: 8),
              _shimmerBox(width: 72, height: 56),
              const SizedBox(width: 8),
              _shimmerBox(width: 72, height: 56),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(width: double.infinity, height: 100),
          const SizedBox(height: 16),
          _shimmerBox(width: 140, height: 16),
          const SizedBox(height: 10),
          Row(
            children: [
              _shimmerBox(width: 120, height: 80),
              const SizedBox(width: 8),
              _shimmerBox(width: 120, height: 80),
              const SizedBox(width: 8),
              _shimmerBox(width: 120, height: 80),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(width: double.infinity, height: 72),
          const SizedBox(height: 8),
          _shimmerBox(width: double.infinity, height: 72),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────

class _GlassStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _MapFab(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon,
              color: onTap == null
                  ? AppColors.textMuted
                  : AppColors.secondary,
              size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Ocean Wave Background Painter
// ─────────────────────────────────────────────────────

class _OceanWavePainter extends CustomPainter {
  final double progress;
  final Color riskColor;

  const _OceanWavePainter({required this.progress, required this.riskColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep ocean gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040D1A),
          Color(0xFF071527),
          Color(0xFF0B1E38),
          Color(0xFF0E2448),
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle radial glow in the upper-mid area (light source effect)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.1),
        radius: 0.65,
        colors: [
          AppColors.secondary.withOpacity(0.07),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Risk-tinted accent glow (top-right corner)
    final riskGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 0.5,
        colors: [
          riskColor.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, riskGlowPaint);

    // Wave layer 1 — wide, slow, deep
    _drawWave(
      canvas: canvas,
      size: size,
      phase: progress * 2 * pi,
      amplitude: size.height * 0.040,
      frequency: 1.4,
      yBase: size.height * 0.62,
      color: AppColors.secondary.withOpacity(0.10),
    );

    // Wave layer 2 — medium, medium speed
    _drawWave(
      canvas: canvas,
      size: size,
      phase: progress * 2 * pi * 1.4 + pi * 0.6,
      amplitude: size.height * 0.032,
      frequency: 2.0,
      yBase: size.height * 0.57,
      color: AppColors.secondary.withOpacity(0.14),
    );

    // Wave layer 3 — narrow, fast, risk-colored
    _drawWave(
      canvas: canvas,
      size: size,
      phase: progress * 2 * pi * 0.9 + pi * 1.2,
      amplitude: size.height * 0.022,
      frequency: 2.8,
      yBase: size.height * 0.52,
      color: riskColor.withOpacity(0.07),
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double phase,
    required double amplitude,
    required double frequency,
    required double yBase,
    required Color color,
  }) {
    final path = Path();
    final steps = size.width.toInt() + 1;
    for (int i = 0; i <= steps; i++) {
      final x = i.toDouble();
      final y = yBase + amplitude * sin(frequency * x / size.width * 2 * pi + phase);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_OceanWavePainter old) =>
      old.progress != progress || old.riskColor != riskColor;
}

class _PredictionTile extends StatelessWidget {
  final RiskPrediction prediction;
  const _PredictionTile({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color =
        RiskCalculator.getRiskColor(prediction.predictedLevel);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            prediction.windowLabel,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Icon(
            _levelIcon(prediction.predictedLevel),
            color: color,
            size: 20,
          ),
          const SizedBox(height: 3),
          Text(
            prediction.predictedLevel.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${(prediction.confidence * 100).round()}% conf.',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  IconData _levelIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Icons.check_circle_outline_rounded;
      case RiskLevel.moderate:
        return Icons.info_outline_rounded;
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.danger:
        return Icons.dangerous_rounded;
    }
  }
}
