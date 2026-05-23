class TideDataPoint {
  final DateTime timestamp;
  final double value; // meters

  const TideDataPoint({required this.timestamp, required this.value});

  factory TideDataPoint.fromJson(Map<String, dynamic> json) {
    return TideDataPoint(
      timestamp: DateTime.parse(json['t'].toString().replaceAll(' ', 'T')),
      value: double.tryParse(json['v'].toString()) ?? 0.0,
    );
  }
}

enum TideType { high, low }

class HighLowTide {
  final DateTime timestamp;
  final double value;
  final TideType type;

  const HighLowTide({
    required this.timestamp,
    required this.value,
    required this.type,
  });

  factory HighLowTide.fromJson(Map<String, dynamic> json) {
    return HighLowTide(
      timestamp: DateTime.parse(json['t'].toString().replaceAll(' ', 'T')),
      value: double.tryParse(json['v'].toString()) ?? 0.0,
      type: json['Type'] == 'H' ? TideType.high : TideType.low,
    );
  }

  bool get isHigh => type == TideType.high;
}

class TideLocationData {
  final String locationName;
  final List<TideDataPoint> dataPoints;
  final List<HighLowTide> highLowTides;
  final DateTime fetchedAt;

  const TideLocationData({
    required this.locationName,
    required this.dataPoints,
    required this.highLowTides,
    required this.fetchedAt,
  });

  double get currentTide {
    if (dataPoints.isEmpty) return 0.0;
    final now = DateTime.now();
    // Find the closest data point to now
    TideDataPoint closest = dataPoints.first;
    int minDiff = (closest.timestamp.difference(now).inMinutes).abs();
    for (final dp in dataPoints) {
      final diff = (dp.timestamp.difference(now).inMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = dp;
      }
    }
    return closest.value;
  }

  HighLowTide? get nextHighTide {
    final now = DateTime.now();
    final upcoming = highLowTides
        .where((t) => t.isHigh && t.timestamp.isAfter(now))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return upcoming.first;
  }

  HighLowTide? get nextLowTide {
    final now = DateTime.now();
    final upcoming = highLowTides
        .where((t) => !t.isHigh && t.timestamp.isAfter(now))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return upcoming.first;
  }
}
