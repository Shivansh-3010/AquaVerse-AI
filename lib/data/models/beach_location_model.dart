import '../../core/utils/risk_calculator.dart';

class BeachLocation {
  final String name;
  final double latitude;
  final double longitude;
  RiskLevel riskLevel;
  bool isFavorite;

  BeachLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.riskLevel = RiskLevel.safe,
    this.isFavorite = false,
  });

  factory BeachLocation.fromJson(Map<String, dynamic> json) {
    return BeachLocation(
      name: json['TIDE_LOCAT'] as String,
      latitude: (json['LATITUDE'] as num).toDouble(),
      longitude: (json['LONGITUDE'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'TIDE_LOCAT': name,
        'LATITUDE': latitude,
        'LONGITUDE': longitude,
      };

  /// Clean display name (replace hyphens with spaces)
  String get displayName => name.replaceAll('-', ' ');

  /// Two-letter country / region hint based on coords
  String get region {
    if (longitude < 68.5) return 'Pakistan';
    if (longitude > 92.0 && latitude > 20.0) return 'Myanmar / Bangladesh';
    if (longitude > 79.5 && latitude < 10.0) return 'Sri Lanka';
    if (latitude < 0) return 'Indian Ocean';
    return 'India';
  }

  @override
  bool operator ==(Object other) =>
      other is BeachLocation && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
