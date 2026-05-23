import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/beach_location_model.dart';
import '../../../data/providers/app_provider.dart';
import '../../widgets/risk_level_card.dart';
import '../../widgets/tide_chart_widget.dart';
import '../../widgets/water_quality_card.dart';

class BeachDetailScreen extends StatefulWidget {
  final BeachLocation location;

  const BeachDetailScreen({super.key, required this.location});

  @override
  State<BeachDetailScreen> createState() => _BeachDetailScreenState();
}

class _BeachDetailScreenState extends State<BeachDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.refreshTideData(widget.location.name);

      // Load water quality for stations near supported locations
      final station = _getNearestWQStation(widget.location.name);
      if (station != null) provider.refreshWaterQuality(station);
    });
  }

  String? _getNearestWQStation(String location) {
    // INCOIS WQNS only supports Kochi and Vizag
    const kochiNearby = [
      'Kochi', 'Alleppey', 'Trivandrum', 'Quilon', 'Nindakara',
      'Calicut', 'Beypore', 'Cannanore', 'Tellicherry', 'Mangalore',
    ];
    const vizagNearby = [
      'Vishakapatnam', 'Kakinada', 'Gopalpur', 'Bhimunipatnam',
      'Baruva', 'Kalingapatnam',
    ];
    if (kochiNearby.contains(location)) return 'Kochi';
    if (vizagNearby.contains(location)) return 'Vizag';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, provider),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    // Risk Level
                    if (provider.riskAssessment != null)
                      RiskLevelCard(assessment: provider.riskAssessment!),
                    const SizedBox(height: 20),
                    // Tide Chart
                    _buildTideSection(provider),
                    const SizedBox(height: 20),
                    // High/Low Tides
                    if (provider.tideData != null)
                      _buildHighLowTides(provider),
                    const SizedBox(height: 20),
                    // Water Quality
                    if (provider.waterQuality != null)
                      _buildWaterQuality(provider),
                    const SizedBox(height: 20),
                    // Safety Tips
                    _buildSafetyTips(),
                    const SizedBox(height: 20),
                    // Location Info
                    _buildLocationInfo(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: Stack(
            children: [
              // Wave decoration
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: CustomPaint(painter: _SimpleWavePainter()),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.location.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.location.region} • ${widget.location.latitude.toStringAsFixed(3)}°N, ${widget.location.longitude.toStringAsFixed(3)}°E',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Consumer<AppProvider>(
          builder: (_, prov, __) => IconButton(
            icon: Icon(
              prov.isFavorite(widget.location.name)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: prov.isFavorite(widget.location.name)
                  ? AppColors.danger
                  : Colors.white,
            ),
            onPressed: () => prov.toggleFavorite(widget.location.name),
          ),
        ),
      ],
    );
  }

  Widget _buildTideSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Tide Forecast (24h)',
          icon: Icons.water_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: provider.tideLoading
              ? const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondary, strokeWidth: 2),
                  ),
                )
              : provider.tideData != null
                  ? TideChartWidget(
                      tideData: provider.tideData!,
                      height: 150,
                    )
                  : const SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(
                          'Tide data unavailable',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHighLowTides(AppProvider provider) {
    final tides = provider.tideData!.highLowTides;
    final today = tides
        .where((t) => t.timestamp.day == DateTime.now().day ||
            t.timestamp.isAfter(DateTime.now()))
        .take(6)
        .toList();

    if (today.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'High & Low Tides',
          icon: Icons.compare_arrows_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: today.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (_, i) {
              final tide = today[i];
              final isHigh = tide.isHigh;
              final color = isHigh ? AppColors.secondary : AppColors.accent;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHigh
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHigh ? 'High Tide' : 'Low Tide',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(tide.timestamp),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${tide.value.toStringAsFixed(2)} m',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaterQuality(AppProvider provider) {
    if (provider.wqLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.secondary, strokeWidth: 2),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: WaterQualityGrid(data: provider.waterQuality!),
    );
  }

  Widget _buildSafetyTips() {
    const tips = [
      ('Swim near lifeguards', Icons.supervisor_account_rounded),
      ('Check warnings before entering water', Icons.warning_amber_rounded),
      ('Never swim alone', Icons.people_rounded),
      ('Heed rip current warning flags', Icons.flag_rounded),
      ('Stay hydrated in hot weather', Icons.water_drop_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Safety Guidelines',
          icon: Icons.health_and_safety_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.safe.withOpacity(0.3)),
          ),
          child: Column(
            children: tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(tip.$2, color: AppColors.safe, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      tip.$1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Station Information',
            icon: Icons.info_rounded,
          ),
          const SizedBox(height: 12),
          _InfoRow(
              label: 'Station Name', value: widget.location.name),
          _InfoRow(
              label: 'Latitude',
              value: '${widget.location.latitude.toStringAsFixed(4)}° N'),
          _InfoRow(
              label: 'Longitude',
              value: '${widget.location.longitude.toStringAsFixed(4)}° E'),
          _InfoRow(label: 'Region', value: widget.location.region),
          const SizedBox(height: 8),
          const Text(
            'Tidal data sourced from INCOIS (Indian National Centre for Ocean Information Services)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SimpleWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.background.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.9,
        size.width, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
