import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/app_provider.dart';
import '../../../data/providers/chatbot_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _incoisKeyCtrl = TextEditingController();
  final _geminiKeyCtrl = TextEditingController();
  final _groqKeyCtrl = TextEditingController();
  bool _incoisObscured = true;
  bool _geminiObscured = true;
  bool _groqObscured = true;
  bool _saved = false;
  AppProvider? _appProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appProvider = context.read<AppProvider>();
      _syncControllersFromProvider();
      _appProvider!.addListener(_syncControllersFromProvider);
    });
  }

  void _syncControllersFromProvider() {
    if (!mounted || _appProvider == null) return;
    if (_incoisKeyCtrl.text.isEmpty && _appProvider!.incoisApiKey.isNotEmpty) {
      _incoisKeyCtrl.text = _appProvider!.incoisApiKey;
    }
    if (_geminiKeyCtrl.text.isEmpty && _appProvider!.geminiApiKey.isNotEmpty) {
      _geminiKeyCtrl.text = _appProvider!.geminiApiKey;
    }
    if (_groqKeyCtrl.text.isEmpty && _appProvider!.groqApiKey.isNotEmpty) {
      _groqKeyCtrl.text = _appProvider!.groqApiKey;
    }
  }

  @override
  void dispose() {
    _appProvider?.removeListener(_syncControllersFromProvider);
    _incoisKeyCtrl.dispose();
    _geminiKeyCtrl.dispose();
    _groqKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer2<AppProvider, ChatbotProvider>(
        builder: (context, provider, chatProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // API Keys
              const _SectionHeader(title: 'API Configuration'),
              const SizedBox(height: 12),
              _buildApiKeysCard(provider, chatProvider),
              const SizedBox(height: 20),

              // Preferences
              const _SectionHeader(title: 'Preferences'),
              const SizedBox(height: 12),
              _buildPreferencesCard(context, provider),
              const SizedBox(height: 20),

              // Favourites
              const _SectionHeader(title: 'Favourite Locations'),
              const SizedBox(height: 12),
              _buildFavouritesCard(provider),
              const SizedBox(height: 20),

              // About
              const _SectionHeader(title: 'About'),
              const SizedBox(height: 12),
              _buildAboutCard(),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApiKeysCard(
      AppProvider provider, ChatbotProvider chatProvider) {
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
          // INCOIS Key
          const Text(
            'INCOIS API Key',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _incoisKeyCtrl,
            obscureText: _incoisObscured,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter INCOIS API key (for warning data)',
              suffixIcon: IconButton(
                icon: Icon(
                    _incoisObscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18),
                onPressed: () =>
                    setState(() => _incoisObscured = !_incoisObscured),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Register at incois.gov.in to get an INCOIS API key. Tidal data works without a key.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Gemini Key
          const Text(
            'Gemini API Key (AquaVerse.ai)',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _geminiKeyCtrl,
            obscureText: _geminiObscured,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter Gemini API key (free from aistudio.google.com)',
              suffixIcon: IconButton(
                icon: Icon(
                    _geminiObscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18),
                onPressed: () =>
                    setState(() => _geminiObscured = !_geminiObscured),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.safe, size: 14),
              SizedBox(width: 4),
              Text(
                'Free API key available — no billing required',
                style: TextStyle(color: AppColors.safe, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Groq Key
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Groq API Key (Recommended)',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.safe.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NO QUOTA ISSUES',
                  style: TextStyle(
                      color: AppColors.safe,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _groqKeyCtrl,
            obscureText: _groqObscured,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter Groq API key (free from console.groq.com)',
              suffixIcon: IconButton(
                icon: Icon(
                    _groqObscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18),
                onPressed: () =>
                    setState(() => _groqObscured = !_groqObscured),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Groq is free with no billing. Sign up at console.groq.com → API Keys. Used as fallback if Gemini quota is exceeded.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                  _saved ? Icons.check_rounded : Icons.save_rounded,
                  size: 18),
              label: Text(_saved ? 'Saved!' : 'Save API Keys'),
              onPressed: () async {
                await provider.saveSettings(
                  incoisKey: _incoisKeyCtrl.text.trim(),
                  geminiKey: _geminiKeyCtrl.text.trim(),
                  groqKey: _groqKeyCtrl.text.trim(),
                );
                if (_geminiKeyCtrl.text.trim().isNotEmpty) {
                  chatProvider
                      .initializeGemini(_geminiKeyCtrl.text.trim());
                }
                if (_groqKeyCtrl.text.trim().isNotEmpty) {
                  chatProvider.setGroqKey(_groqKeyCtrl.text.trim());
                }
                setState(() => _saved = true);
                Future.delayed(
                    const Duration(seconds: 2),
                    () => mounted
                        ? setState(() => _saved = false)
                        : null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _saved ? AppColors.safe : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
      BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Default location
          ListTile(
            leading: const Icon(Icons.location_on_rounded,
                color: AppColors.secondary),
            title: const Text('Default Location',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
            subtitle: Text(
              provider.defaultLocation,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
            onTap: () => _showLocationPicker(context, provider),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Master notifications toggle
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded,
                color: AppColors.secondary),
            title: const Text('Enable Notifications',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text(
              'Master toggle for all ocean warning alerts',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: provider.notificationsEnabled,
            activeThumbColor: AppColors.secondary,
            onChanged: (v) => provider.saveSettings(notifications: v),
          ),
          // Per-type toggles (only visible when master is on)
          if (provider.notificationsEnabled) ...[
            const Divider(color: AppColors.divider, height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'ALERT TYPES',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600),
              ),
            ),
            ..._notifTypes.map((t) {
              return SwitchListTile(
                dense: true,
                secondary: Icon(t.icon, color: t.color, size: 20),
                title: Text(t.label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                value: provider.notifPrefs[t.type] ?? true,
                activeThumbColor: t.color,
                onChanged: (v) =>
                    provider.setNotifPreference(t.type, v),
              );
            }),
          ],
        ],
      ),
    );
  }

  static const _notifTypes = [
    _NotifType(type: 'tsunami', label: 'Tsunami Warnings',
        icon: Icons.waves_rounded, color: AppColors.danger),
    _NotifType(type: 'stormsurge', label: 'Storm Surge Alerts',
        icon: Icons.storm_rounded, color: AppColors.high),
    _NotifType(type: 'highwave', label: 'High Wave Alerts',
        icon: Icons.water_rounded, color: AppColors.moderate),
    _NotifType(type: 'swellsurge', label: 'Swell Surge Alerts',
        icon: Icons.waterfall_chart_rounded, color: AppColors.secondary),
    _NotifType(type: 'coastalcurrents', label: 'Coastal Current Alerts',
        icon: Icons.air_rounded, color: AppColors.accent),
  ];

  Widget _buildFavouritesCard(AppProvider provider) {
    final favs = provider.favorites;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.favorite_border_rounded,
                color: AppColors.textMuted, size: 20),
            SizedBox(width: 12),
            Text(
              'No favourites yet. Tap ♥ on any beach to save it.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: favs.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.favorite_rounded,
              color: AppColors.danger, size: 18),
          title: Text(
            favs[i].replaceAll('-', ' '),
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
            onPressed: () => provider.toggleFavorite(favs[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_rounded,
                  color: AppColors.secondary, size: 24),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AquaVerse',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Version 1.0.0 • AquaVerse AI 2026',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.divider),
          SizedBox(height: 12),
          _AboutRow(
            icon: Icons.data_usage_rounded,
            title: 'Data Source',
            subtitle:
                'Indian National Centre for Ocean Information Services (INCOIS), Ministry of Earth Sciences, Govt. of India',
          ),
          SizedBox(height: 8),
          _AboutRow(
            icon: Icons.smart_toy_rounded,
            title: 'AI Chatbot',
            subtitle: 'Powered by Google Gemini AI',
          ),
          SizedBox(height: 8),
          _AboutRow(
            icon: Icons.map_rounded,
            title: 'Maps',
            subtitle: 'OpenStreetMap contributors',
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.divider),
          SizedBox(height: 8),
          Text(
            'AquaVerse is a capstone project for Final Year Engineering. It provides real-time beach safety information using INCOIS ocean data for educational and safety awareness purposes.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context, AppProvider provider) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setModalState) {
          final query = searchCtrl.text;
          final allLocs = provider.allLocations;
          final locs = query.isEmpty
              ? allLocs
              : allLocs
                  .where((l) =>
                      l.displayName
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      l.region
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                  .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (_, sc) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Select Default Location',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or region...',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.cardDark,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.secondary),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  if (locs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No locations found',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: sc,
                        itemCount: locs.length,
                        itemBuilder: (_, i) {
                          final loc = locs[i];
                          final isSelected =
                              loc.name == provider.defaultLocation;
                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            title: Text(
                              loc.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              loc.region,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                            ),
                            onTap: () async {
                              await provider.saveSettings(location: loc.name);
                              await provider.refreshTideData(loc.name);
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotifType {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  const _NotifType(
      {required this.type,
      required this.label,
      required this.icon,
      required this.color});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AboutRow(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
