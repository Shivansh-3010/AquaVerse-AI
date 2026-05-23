import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/risk_calculator.dart';
import '../../../data/models/beach_location_model.dart';
import '../../../data/providers/app_provider.dart';
import '../beach_detail/beach_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  BeachLocation? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final locations = provider.allLocations
              .where((l) =>
                  _query.isEmpty ||
                  l.displayName.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(15.0, 80.0),
                  initialZoom: 4.5,
                  minZoom: 3.0,
                  maxZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aquaverse.app',
                    tileBuilder: (context, widget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          // Dark mode matrix
                          -0.5, -0.5, -0.5, 0, 230,
                          -0.5, -0.5, -0.5, 0, 230,
                          -0.5, -0.5, -0.5, 0, 230,
                          0, 0, 0, 1, 0,
                        ]),
                        child: widget,
                      );
                    },
                  ),
                  MarkerLayer(
                    markers: locations
                        .map((loc) => _buildMarker(loc))
                        .toList(),
                  ),
                  // Live user location dot
                  if (provider.hasUserLocation)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                              provider.userLat!, provider.userLon!),
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.55),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.my_location_rounded,
                                color: AppColors.primary, size: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Search bar + title
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // Title bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded,
                              color: AppColors.secondary, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Coastal Watch Map',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (provider.riskAssessment != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: provider.riskAssessment!.color
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                provider.riskAssessment!.title,
                                style: TextStyle(
                                  color: provider.riskAssessment!.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search ${provider.allLocations.length} locations...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textMuted, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textMuted, size: 18),
                                  onPressed: () => setState(() {
                                    _query = '';
                                    _searchController.clear();
                                  }),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    // Search results
                    if (_query.isNotEmpty && locations.length < 20)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: locations.length,
                          itemBuilder: (_, i) {
                            final loc = locations[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_rounded,
                                  color: AppColors.secondary, size: 18),
                              title: Text(
                                loc.displayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                loc.region,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () {
                                _mapController.move(
                                  LatLng(loc.latitude, loc.longitude),
                                  10.0,
                                );
                                setState(() {
                                  _selectedLocation = loc;
                                  _query = '';
                                  _searchController.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // My Location FAB
              Positioned(
                bottom: 100,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    if (provider.hasUserLocation) {
                      _mapController.move(
                        LatLng(provider.userLat!, provider.userLon!),
                        12.0,
                      );
                    } else {
                      provider.requestLocationPermission();
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.hasUserLocation
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.divider,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      provider.hasUserLocation
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      color: provider.hasUserLocation
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Legend
              Positioned(
                bottom: 100,
                right: 12,
                child: _buildLegend(),
              ),

              // Selected location bottom sheet
              if (_selectedLocation != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildLocationSheet(context, _selectedLocation!),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(BeachLocation loc) {
    final color = RiskCalculator.getRiskColor(loc.riskLevel);
    return Marker(
      point: LatLng(loc.latitude, loc.longitude),
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLocation = loc);
          _mapController.move(LatLng(loc.latitude, loc.longitude), 9.0);
        },
        child: Container(
          decoration: BoxDecoration(
            color: _selectedLocation?.name == loc.name
                ? AppColors.accent
                : color.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.place_rounded,
            size: _selectedLocation?.name == loc.name ? 18 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const levels = [
      ('Safe', AppColors.safe),
      ('Moderate', AppColors.moderate),
      ('High', AppColors.high),
      ('Danger', AppColors.danger),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Level',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          ...levels.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: l.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.$1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSheet(BuildContext context, BeachLocation loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.waves_rounded,
                color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${loc.region} • ${loc.latitude.toStringAsFixed(2)}°N, ${loc.longitude.toStringAsFixed(2)}°E',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BeachDetailScreen(location: loc),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('View'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            onPressed: () => setState(() => _selectedLocation = null),
          ),
        ],
      ),
    );
  }
}
