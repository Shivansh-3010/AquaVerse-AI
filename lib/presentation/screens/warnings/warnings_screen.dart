import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/warning_model.dart';
import '../../../data/providers/app_provider.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/warning_card.dart';

class WarningsScreen extends StatefulWidget {
  const WarningsScreen({super.key});

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (label: 'All', icon: Icons.list_rounded),
    (label: 'Tsunami', icon: Icons.waves_rounded),
    (label: 'Storm', icon: Icons.storm_rounded),
    (label: 'Wave', icon: Icons.water_rounded),
    (label: 'Swell', icon: Icons.waterfall_chart_rounded),
    (label: 'Current', icon: Icons.air_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Early Warnings'),
        actions: [
          Consumer<AppProvider>(
            builder: (_, provider, __) => IconButton(
              icon: provider.warningsLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed:
                  provider.warningsLoading ? null : provider.refreshWarnings,
              tooltip: 'Refresh',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs
              .map((t) => Tab(
                    child: Row(
                      children: [
                        Icon(t.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(t.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.warningsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }

          final all = provider.allWarnings;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildWarningList(context, provider, all),
              _buildSingleWarning(context, provider, provider.tsunami),
              _buildSingleWarning(context, provider, provider.stormSurge),
              _buildSingleWarning(context, provider, provider.highWave),
              _buildSingleWarning(context, provider, provider.swellSurge),
              _buildSingleWarning(context, provider, provider.coastalCurrents),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarningList(
      BuildContext context, AppProvider provider, List<WarningData> warnings) {
    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: AppColors.cardDark,
      onRefresh: provider.refreshWarnings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DemoBanner(),
          _buildSummaryCard(provider),
          const SizedBox(height: 16),
          ...warnings.map((w) => WarningCard(warning: w, expanded: true)),
          const SizedBox(height: 20),
          _buildIncoisCredit(),
        ],
      ),
    );
  }

  Widget _buildSingleWarning(
      BuildContext context, AppProvider provider, WarningData? warning) {
    if (warning == null) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: AppColors.cardDark,
      onRefresh: provider.refreshWarnings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WarningCard(warning: warning, expanded: true),
          const SizedBox(height: 12),
          _buildDetailCard(warning),
          const SizedBox(height: 20),
          _buildIncoisCredit(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider provider) {
    final active = provider.activeWarnings;
    final riskColor = provider.riskAssessment?.color ?? AppColors.safe;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withOpacity(0.15),
            riskColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: riskColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${active.isEmpty ? 'No Active' : active.length} Warning${active.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: riskColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            active.isEmpty
                ? 'All clear! Ocean conditions are currently safe. Always stay vigilant and follow lifeguard instructions.'
                : 'Active advisories have been issued by INCOIS. Exercise appropriate caution.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(WarningData warning) {
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
          const Text(
            'What is this warning?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getWarningExplanation(warning.type),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncoisCredit() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textMuted, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data sourced from Indian National Centre for Ocean Information Services (INCOIS), Ministry of Earth Sciences, Govt. of India.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getWarningExplanation(String type) {
    switch (type) {
      case 'tsunami':
        return 'A Tsunami Warning is issued when an earthquake or underwater landslide may have generated dangerous waves. Tsunamis can travel hundreds of kilometers and arrive with little warning. Evacuate immediately to higher ground if a warning is issued.';
      case 'stormsurge':
        return 'Storm Surge occurs when strong winds from a cyclone or storm push ocean water onto land, causing abnormally high water levels along the coast. This can cause flooding of low-lying coastal areas.';
      case 'highwave':
        return 'High Wave Alerts indicate that unusually large ocean waves are expected or occurring. These waves can be dangerous for swimmers, fishermen, and vessels near the coast.';
      case 'swellsurge':
        return 'Swell Surge Alerts indicate the arrival of long-period ocean swell waves that may be dangerous even in calm local weather. These swells can catch beachgoers off-guard with sudden powerful surges.';
      case 'coastalcurrents':
        return 'Coastal Current Alerts warn about strong, potentially dangerous currents along the shoreline. These include rip currents which can quickly pull swimmers away from shore. Do not attempt to swim against the current.';
      default:
        return 'This is an advisory issued by INCOIS regarding ocean safety conditions in the region.';
    }
  }
}
