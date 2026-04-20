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
    // DEBUG: Print raw conditions to check if we are receiving mock data
    print('DEBUG RAW SILO JSON (${json['silo_id']}): ${json['current_conditions']}');
    
    final conditions = json['current_conditions'] ?? {};
    final batch = json['current_batch_id'] is Map ? json['current_batch_id'] : {};

    return SiloModel(
      id: json['_id'] ?? '',
      name: json['silo_id'] ?? 'Unknown Silo',
      capacity: (json['capacity_kg'] ?? 0).toDouble(),
      currentLevel: (json['current_occupancy_kg'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      temperature: _parseValue(conditions['temperature']),
      humidity: _parseValue(conditions['humidity']),
      tvoc: _parseValue(conditions['tvoc'] ?? conditions['co2']), // Fallback to CO2 if TVOC is missing
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
