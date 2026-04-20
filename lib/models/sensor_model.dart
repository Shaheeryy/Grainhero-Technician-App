class SensorModel {
  final String id;
  final String name;
  final String type;
  final String siteName;
  final double? temperature;
  final double? humidity;
  final double? spoilageRisk;
  final String status;
  final DateTime lastReading;
  final List<SensorReading> readings;

  SensorModel({
    required this.id,
    required this.name,
    required this.type,
    required this.siteName,
    this.temperature,
    this.humidity,
    this.spoilageRisk,
    required this.status,
    required this.lastReading,
    this.readings = const [],
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      siteName: json['siteName'] ?? json['site']?['name'] ?? '',
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      spoilageRisk: json['spoilageRisk']?.toDouble(),
      status: json['status'] ?? 'unknown',
      lastReading: json['lastReading'] != null
          ? DateTime.parse(json['lastReading'])
          : DateTime.now(),
      readings: json['readings'] != null
          ? (json['readings'] as List)
                .map((r) => SensorReading.fromJson(r))
                .toList()
          : [],
    );
  }
}

class SensorReading {
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  SensorReading({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
    );
  }
}
