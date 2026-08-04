/// Complete sensor device model mapping ALL backend fields.
/// Backend returns nested value objects like `temperature: { value: 28.5, unit: "celsius" }`.
class SensorDevice {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String category;
  final List<String> sensorTypes;
  final String status;
  final String? siloId;
  final String? siloName;
  final String? siloCode;
  final int? batteryLevel;
  final int? signalStrength;
  final String connectionStatus;
  final String healthStatus;
  final String calibrationStatus;
  final bool isEnabled;
  final String? model;
  final String? manufacturer;
  final String? firmwareVersion;
  final SensorThresholds? thresholds;
  final SensorHealthMetrics? healthMetrics;
  final SensorDataStats? dataStats;
  final DateTime? lastCalibrationDate;
  final DateTime? calibrationDueDate;
  final DateTime? createdAt;
  final List<SensorReading> recentReadings;

  SensorDevice({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.deviceType = 'sensor',
    this.category = 'environmental',
    this.sensorTypes = const [],
    required this.status,
    this.siloId,
    this.siloName,
    this.siloCode,
    this.batteryLevel,
    this.signalStrength,
    this.connectionStatus = 'unknown',
    this.healthStatus = 'unknown',
    this.calibrationStatus = 'unknown',
    this.isEnabled = true,
    this.model,
    this.manufacturer,
    this.firmwareVersion,
    this.thresholds,
    this.healthMetrics,
    this.dataStats,
    this.lastCalibrationDate,
    this.calibrationDueDate,
    this.createdAt,
    this.recentReadings = const [],
  });

  factory SensorDevice.fromJson(Map<String, dynamic> json) {
    // Handle Supabase PostgREST joined silo object
    String? siloId;
    String? siloName;
    String? siloCode;
    if (json['silos'] is Map) {
      siloId = json['silos']['id']?.toString();
      siloName = json['silos']['name']?.toString();
      siloCode = json['silos']['silo_id']?.toString();
    } else {
      siloId = json['silo_id']?.toString();
      siloName = json['silo_name']?.toString();
    }

    return SensorDevice(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? json['name']?.toString() ?? 'Unknown Sensor',
      deviceType: json['device_type']?.toString() ?? 'sensor',
      category: json['category']?.toString() ?? 'environmental',
      sensorTypes: _parseStringList(json['sensor_types']),
      status: (json['status'] == 'unknown') ? 'active' : (json['status']?.toString() ?? 'active'),
      siloId: siloId,
      siloName: siloName,
      siloCode: siloCode,
      batteryLevel: _parseInt(json['battery_level']),
      signalStrength: _parseInt(json['signal_strength']),
      connectionStatus: json['connection_status']?.toString() ?? 'unknown',
      healthStatus: json['health_status']?.toString() ?? 'unknown',
      calibrationStatus: json['calibration_status']?.toString() ?? 'unknown',
      isEnabled: json['is_enabled'] ?? true,
      model: json['model']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      firmwareVersion: json['firmware_version']?.toString(),
      thresholds: json['thresholds'] is Map
          ? SensorThresholds.fromJson(Map<String, dynamic>.from(json['thresholds']))
          : null,
      healthMetrics: json['health_metrics'] is Map
          ? SensorHealthMetrics.fromJson(Map<String, dynamic>.from(json['health_metrics']))
          : null,
      dataStats: json['data_stats'] is Map
          ? SensorDataStats.fromJson(Map<String, dynamic>.from(json['data_stats']))
          : null,
      lastCalibrationDate: _parseDate(json['last_calibration_date']),
      calibrationDueDate: _parseDate(json['calibration_due_date']),
      createdAt: _parseDate(json['created_at']),
      recentReadings: _parseReadings(json['recent_readings']),
    );
  }

  /// Get latest reading values from recentReadings or return null
  SensorReading? get latestReading =>
      recentReadings.isNotEmpty ? recentReadings.first : null;

  double? get latestTemperature => latestReading?.temperature;
  double? get latestHumidity => latestReading?.humidity;
  double? get latestVoc => latestReading?.voc;
  double? get latestMoisture => latestReading?.moisture;

  DateTime? get lastReadingTime =>
      dataStats?.lastReadingDate ?? latestReading?.timestamp;

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<SensorReading> _parseReadings(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((r) => SensorReading.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    }
    return [];
  }
}

/// Sensor reading with nested value objects matching backend schema.
class SensorReading {
  final DateTime? timestamp;
  final double? temperature;
  final String? temperatureUnit;
  final double? humidity;
  final String? humidityUnit;
  final double? voc;
  final String? vocUnit;
  final double? moisture;
  final String? moistureUnit;
  final double? co2;
  final String? co2Unit;
  final AmbientData? ambient;
  final ActuationState? actuationState;
  final DerivedMetrics? derivedMetrics;
  final int? batteryLevel;
  final int? signalStrength;

  SensorReading({
    this.timestamp,
    this.temperature,
    this.temperatureUnit,
    this.humidity,
    this.humidityUnit,
    this.voc,
    this.vocUnit,
    this.moisture,
    this.moistureUnit,
    this.co2,
    this.co2Unit,
    this.ambient,
    this.actuationState,
    this.derivedMetrics,
    this.batteryLevel,
    this.signalStrength,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : (json['reading_timestamp'] != null 
              ? DateTime.tryParse(json['reading_timestamp'].toString())
              : null),
      temperature: _extractNestedValue(json['temperature'] ?? json['temperature_value']),
      temperatureUnit: _extractNestedUnit(json['temperature'], 'celsius'),
      humidity: _extractNestedValue(json['humidity'] ?? json['humidity_value']),
      humidityUnit: _extractNestedUnit(json['humidity'], 'percent'),
      voc: _extractNestedValue(json['voc'] ?? json['voc_value']),
      vocUnit: _extractNestedUnit(json['voc'], 'ppb'),
      moisture: _extractNestedValue(json['moisture'] ?? json['moisture_value']),
      moistureUnit: _extractNestedUnit(json['moisture'], 'percent'),
      co2: _extractNestedValue(json['co2'] ?? json['co2_value']),
      co2Unit: _extractNestedUnit(json['co2'], 'ppm'),
      ambient: json['ambient'] is Map
          ? AmbientData.fromJson(Map<String, dynamic>.from(json['ambient']))
          : null,
      actuationState: json['actuation_state'] is Map
          ? ActuationState.fromJson(Map<String, dynamic>.from(json['actuation_state']))
          : null,
      derivedMetrics: json['derived_metrics'] is Map
          ? DerivedMetrics.fromJson(Map<String, dynamic>.from(json['derived_metrics']))
          : null,
      batteryLevel: json['device_metrics'] is Map
          ? (json['device_metrics']['battery_level'] as num?)?.toInt()
          : (json['battery_level'] as num?)?.toInt(),
      signalStrength: json['device_metrics'] is Map
          ? (json['device_metrics']['signal_strength'] as num?)?.toInt()
          : (json['signal_strength'] as num?)?.toInt(),
    );
  }

  /// Extract value from nested `{ value: 28.5, unit: "celsius" }` or plain number.
  static double? _extractNestedValue(dynamic field) {
    if (field == null) return null;
    if (field is num) return field.toDouble();
    if (field is Map) {
      final val = field['value'];
      if (val is num) return val.toDouble();
    }
    return null;
  }

  static String? _extractNestedUnit(dynamic field, String fallback) {
    if (field is Map && field['unit'] != null) {
      return field['unit'].toString();
    }
    return fallback;
  }
}

/// Ambient environmental conditions outside the silo.
class AmbientData {
  final double? temperature;
  final double? humidity;
  final double? light;

  AmbientData({this.temperature, this.humidity, this.light});

  factory AmbientData.fromJson(Map<String, dynamic> json) {
    return AmbientData(
      temperature: _extractVal(json['temperature']),
      humidity: _extractVal(json['humidity']),
      light: _extractVal(json['light']),
    );
  }

  static double? _extractVal(dynamic field) {
    if (field == null) return null;
    if (field is num) return field.toDouble();
    if (field is Map) {
      final val = field['value'];
      if (val is num) return val.toDouble();
    }
    return null;
  }
}

/// Actuation state from sensor readings (fan status, etc.).
class ActuationState {
  final int? fanState;
  final String? fanStatus;
  final int? fanDutyCycle;
  final int? fanRpm;

  ActuationState({this.fanState, this.fanStatus, this.fanDutyCycle, this.fanRpm});

  factory ActuationState.fromJson(Map<String, dynamic> json) {
    return ActuationState(
      fanState: (json['fan_state'] as num?)?.toInt(),
      fanStatus: json['fan_status']?.toString(),
      fanDutyCycle: (json['fan_duty_cycle'] as num?)?.toInt(),
      fanRpm: (json['fan_rpm'] as num?)?.toInt(),
    );
  }
}

/// ML-derived metrics computed server-side.
class DerivedMetrics {
  final double? dewPoint;
  final double? dewPointGap;
  final bool? condensationRisk;
  final String? mlRiskClass;
  final double? mlRiskScore;
  final String? fanRecommendation;
  final double? vocRelative5min;
  final double? vocRate5min;
  final bool? pestPresenceFlag;

  DerivedMetrics({
    this.dewPoint,
    this.dewPointGap,
    this.condensationRisk,
    this.mlRiskClass,
    this.mlRiskScore,
    this.fanRecommendation,
    this.vocRelative5min,
    this.vocRate5min,
    this.pestPresenceFlag,
  });

  factory DerivedMetrics.fromJson(Map<String, dynamic> json) {
    return DerivedMetrics(
      dewPoint: (json['dew_point'] as num?)?.toDouble(),
      dewPointGap: (json['dew_point_gap'] as num?)?.toDouble(),
      condensationRisk: json['condensation_risk'] as bool?,
      mlRiskClass: json['ml_risk_class']?.toString(),
      mlRiskScore: (json['ml_risk_score'] as num?)?.toDouble(),
      fanRecommendation: json['fan_recommendation']?.toString(),
      vocRelative5min: (json['voc_relative_5min'] as num?)?.toDouble(),
      vocRate5min: (json['voc_rate_5min'] as num?)?.toDouble(),
      pestPresenceFlag: json['pest_presence_flag'] as bool?,
    );
  }
}

/// Threshold configuration for each metric.
class MetricThreshold {
  final double? min;
  final double? max;
  final double? criticalMin;
  final double? criticalMax;

  MetricThreshold({this.min, this.max, this.criticalMin, this.criticalMax});

  factory MetricThreshold.fromJson(Map<String, dynamic> json) {
    return MetricThreshold(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      criticalMin: (json['critical_min'] as num?)?.toDouble(),
      criticalMax: (json['critical_max'] as num?)?.toDouble(),
    );
  }

  /// Returns 'normal', 'warning', or 'critical' for a given value.
  String getStatus(double value) {
    if (criticalMin != null && value <= criticalMin!) return 'critical';
    if (criticalMax != null && value >= criticalMax!) return 'critical';
    if (min != null && value <= min!) return 'warning';
    if (max != null && value >= max!) return 'warning';
    return 'normal';
  }
}

/// Thresholds for all sensor metrics.
class SensorThresholds {
  final MetricThreshold? temperature;
  final MetricThreshold? humidity;
  final MetricThreshold? voc;
  final MetricThreshold? moisture;
  final MetricThreshold? co2;

  SensorThresholds({this.temperature, this.humidity, this.voc, this.moisture, this.co2});

  factory SensorThresholds.fromJson(Map<String, dynamic> json) {
    return SensorThresholds(
      temperature: json['temperature'] is Map
          ? MetricThreshold.fromJson(Map<String, dynamic>.from(json['temperature']))
          : null,
      humidity: json['humidity'] is Map
          ? MetricThreshold.fromJson(Map<String, dynamic>.from(json['humidity']))
          : null,
      voc: json['voc'] is Map
          ? MetricThreshold.fromJson(Map<String, dynamic>.from(json['voc']))
          : null,
      moisture: json['moisture'] is Map
          ? MetricThreshold.fromJson(Map<String, dynamic>.from(json['moisture']))
          : null,
      co2: json['co2'] is Map
          ? MetricThreshold.fromJson(Map<String, dynamic>.from(json['co2']))
          : null,
    );
  }
}

/// Sensor health metrics.
class SensorHealthMetrics {
  final double? uptimePercentage;
  final DateTime? lastHeartbeat;
  final int? errorCount;

  SensorHealthMetrics({this.uptimePercentage, this.lastHeartbeat, this.errorCount});

  factory SensorHealthMetrics.fromJson(Map<String, dynamic> json) {
    return SensorHealthMetrics(
      uptimePercentage: (json['uptime_percentage'] as num?)?.toDouble(),
      lastHeartbeat: json['last_heartbeat'] != null
          ? DateTime.tryParse(json['last_heartbeat'].toString())
          : null,
      errorCount: (json['error_count'] as num?)?.toInt(),
    );
  }
}

/// Sensor data statistics.
class SensorDataStats {
  final int? totalReadings;
  final DateTime? lastReadingDate;
  final int? readingsToday;

  SensorDataStats({this.totalReadings, this.lastReadingDate, this.readingsToday});

  factory SensorDataStats.fromJson(Map<String, dynamic> json) {
    return SensorDataStats(
      totalReadings: (json['total_readings'] as num?)?.toInt(),
      lastReadingDate: json['last_reading_date'] != null
          ? DateTime.tryParse(json['last_reading_date'].toString())
          : null,
      readingsToday: (json['readings_today'] as num?)?.toInt(),
    );
  }
}

// ============================================
// BACKWARD COMPATIBILITY ALIAS
// ============================================
/// Alias for backward compatibility with existing code referencing SensorModel.
typedef SensorModel = SensorDevice;
