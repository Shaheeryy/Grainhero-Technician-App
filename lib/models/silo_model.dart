class SiloModel {
  final String id;
  final String name; // silo_id
  final double capacity; // capacity_kg
  final double currentLevel; // current_occupancy_kg
  final String status;
  // Nested data
  final double temperature;
  final double humidity;
  final double tvoc;
  final String grainType;

  SiloModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.currentLevel,
    required this.status,
    required this.temperature,
    required this.humidity,
    required this.tvoc,
    required this.grainType,
  });

  factory SiloModel.fromJson(Map<String, dynamic> json) {
    // Read from joined sensor_readings array (from Supabase PostgREST join)
    dynamic conditions = {};
    if (json['sensor_readings'] != null && json['sensor_readings'] is List && (json['sensor_readings'] as List).isNotEmpty) {
      conditions = (json['sensor_readings'] as List).first;
    }
    
    dynamic batch = json['current_batch'] ?? {};
    if (batch is! Map) {
      batch = {};
    }

    return SiloModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Silo',
      capacity: _parseValue(json['capacity_kg']),
      currentLevel: _parseValue(json['current_occupancy_kg']),
      status: json['status'] ?? 'active',
      temperature: _parseValue(conditions['temperature'] ?? conditions['temperature_value']),
      humidity: _parseValue(conditions['humidity'] ?? conditions['humidity_value']),
      tvoc: _parseValue(conditions['tvoc'] ?? conditions['voc_value'] ?? conditions['co2']), 
      grainType: batch['grain_type'] ?? 'Empty',
    );
  }

  static double _parseValue(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is Map) return (val['value'] ?? 0).toDouble();
    return 0.0;
  }
  
  double get fillPercentage => capacity > 0 ? (currentLevel / capacity) : 0.0;
}
