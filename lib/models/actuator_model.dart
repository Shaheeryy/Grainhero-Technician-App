import 'package:flutter/material.dart';

/// Complete actuator model mapping ALL backend fields from GET /api/actuators.
class ActuatorModel {
  final String id;
  final String actuatorId;
  final String name;
  final String actuatorType;
  final String? siloId;
  final String? siloName;
  final String? siloCode;
  final String status;
  final bool isEnabled;
  final bool isOn;
  final String controlMode;
  final int powerLevel;
  final bool mlRequestedFan;
  final bool humanRequestedFan;
  final int targetFanSpeed;
  final String mlDecision;
  final ActuatorAiControl aiControl;
  final ActuatorCurrentOperation? currentOperation;
  final ActuatorHealthMetrics healthMetrics;
  final ActuatorPerformanceMetrics performanceMetrics;
  final ActuatorSafetyLimits safetyLimits;
  final ActuatorSchedule schedule;
  final String operationStatus;
  final String healthStatus;
  final String maintenanceStatus;

  ActuatorModel({
    required this.id,
    required this.actuatorId,
    required this.name,
    required this.actuatorType,
    this.siloId,
    this.siloName,
    this.siloCode,
    required this.status,
    this.isEnabled = true,
    this.isOn = false,
    this.controlMode = 'manual',
    this.powerLevel = 0,
    this.mlRequestedFan = false,
    this.humanRequestedFan = false,
    this.targetFanSpeed = 0,
    this.mlDecision = 'idle',
    this.aiControl = const ActuatorAiControl(),
    this.currentOperation,
    this.healthMetrics = const ActuatorHealthMetrics(),
    this.performanceMetrics = const ActuatorPerformanceMetrics(),
    this.safetyLimits = const ActuatorSafetyLimits(),
    this.schedule = const ActuatorSchedule(),
    this.operationStatus = 'idle',
    this.healthStatus = 'unknown',
    this.maintenanceStatus = 'unknown',
  });

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    // Handle populated silo_id object
    String? siloId;
    String? siloName;
    String? siloCode;
    if (json['silo_id'] is Map) {
      siloId = json['silo_id']['_id']?.toString();
      siloName = json['silo_id']['name']?.toString();
      siloCode = json['silo_id']['silo_id']?.toString();
    } else {
      siloId = json['silo_id']?.toString();
      siloName = json['silo_name']?.toString();
    }

    return ActuatorModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      actuatorId: json['actuator_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Actuator',
      actuatorType: json['actuator_type']?.toString() ?? json['type']?.toString() ?? 'fan',
      siloId: siloId,
      siloName: siloName,
      siloCode: siloCode,
      status: json['status']?.toString() ?? 'active',
      isEnabled: json['is_enabled'] ?? true,
      isOn: json['is_on'] ?? false,
      controlMode: json['control_mode']?.toString() ?? 'manual',
      powerLevel: (json['power_level'] as num?)?.toInt() ?? 0,
      mlRequestedFan: json['ml_requested_fan'] ?? false,
      humanRequestedFan: json['human_requested_fan'] ?? false,
      targetFanSpeed: (json['target_fan_speed'] as num?)?.toInt() ?? 0,
      mlDecision: json['ml_decision']?.toString() ?? 'idle',
      aiControl: json['ai_control'] is Map
          ? ActuatorAiControl.fromJson(Map<String, dynamic>.from(json['ai_control']))
          : const ActuatorAiControl(),
      currentOperation: json['current_operation'] is Map
          ? ActuatorCurrentOperation.fromJson(
              Map<String, dynamic>.from(json['current_operation']))
          : null,
      healthMetrics: json['health_metrics'] is Map
          ? ActuatorHealthMetrics.fromJson(
              Map<String, dynamic>.from(json['health_metrics']))
          : const ActuatorHealthMetrics(),
      performanceMetrics: json['performance_metrics'] is Map
          ? ActuatorPerformanceMetrics.fromJson(
              Map<String, dynamic>.from(json['performance_metrics']))
          : const ActuatorPerformanceMetrics(),
      safetyLimits: json['safety_limits'] is Map
          ? ActuatorSafetyLimits.fromJson(
              Map<String, dynamic>.from(json['safety_limits']))
          : const ActuatorSafetyLimits(),
      schedule: json['schedule'] is Map
          ? ActuatorSchedule.fromJson(Map<String, dynamic>.from(json['schedule']))
          : const ActuatorSchedule(),
      operationStatus: json['operation_status']?.toString() ?? 'idle',
      healthStatus: json['health_status']?.toString() ?? 'unknown',
      maintenanceStatus: json['maintenance_status']?.toString() ?? 'unknown',
    );
  }

  ActuatorModel copyWith({
    String? id,
    String? actuatorId,
    String? name,
    String? actuatorType,
    String? siloId,
    String? siloName,
    String? siloCode,
    String? status,
    bool? isEnabled,
    bool? isOn,
    String? controlMode,
    int? powerLevel,
    bool? mlRequestedFan,
    bool? humanRequestedFan,
    int? targetFanSpeed,
    String? mlDecision,
    ActuatorAiControl? aiControl,
    ActuatorCurrentOperation? currentOperation,
    ActuatorHealthMetrics? healthMetrics,
    ActuatorPerformanceMetrics? performanceMetrics,
    ActuatorSafetyLimits? safetyLimits,
    ActuatorSchedule? schedule,
    String? operationStatus,
    String? healthStatus,
    String? maintenanceStatus,
  }) {
    return ActuatorModel(
      id: id ?? this.id,
      actuatorId: actuatorId ?? this.actuatorId,
      name: name ?? this.name,
      actuatorType: actuatorType ?? this.actuatorType,
      siloId: siloId ?? this.siloId,
      siloName: siloName ?? this.siloName,
      siloCode: siloCode ?? this.siloCode,
      status: status ?? this.status,
      isEnabled: isEnabled ?? this.isEnabled,
      isOn: isOn ?? this.isOn,
      controlMode: controlMode ?? this.controlMode,
      powerLevel: powerLevel ?? this.powerLevel,
      mlRequestedFan: mlRequestedFan ?? this.mlRequestedFan,
      humanRequestedFan: humanRequestedFan ?? this.humanRequestedFan,
      targetFanSpeed: targetFanSpeed ?? this.targetFanSpeed,
      mlDecision: mlDecision ?? this.mlDecision,
      aiControl: aiControl ?? this.aiControl,
      currentOperation: currentOperation ?? this.currentOperation,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      safetyLimits: safetyLimits ?? this.safetyLimits,
      schedule: schedule ?? this.schedule,
      operationStatus: operationStatus ?? this.operationStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
    );
  }

  // ============================================
  // HELPER GETTERS
  // ============================================

  String get typeLabel {
    switch (actuatorType.toLowerCase()) {
      case 'fan':
        return 'Fan';
      case 'vent':
        return 'Ventilation';
      case 'heater':
        return 'Heater';
      case 'cooler':
        return 'Cooler';
      case 'alarm':
        return 'Alarm';
      case 'light':
        return 'Light';
      default:
        return actuatorType;
    }
  }

  IconData get typeIcon {
    switch (actuatorType.toLowerCase()) {
      case 'fan':
        return Icons.air;
      case 'vent':
        return Icons.door_sliding_outlined;
      case 'heater':
        return Icons.local_fire_department_outlined;
      case 'cooler':
        return Icons.ac_unit;
      case 'alarm':
        return Icons.notification_important_outlined;
      case 'light':
        return Icons.lightbulb_outline;
      default:
        return Icons.settings_input_component;
    }
  }

  String get controlModeLabel {
    switch (controlMode.toLowerCase()) {
      case 'manual':
        return 'Manual';
      case 'ai':
      case 'automatic':
        return 'AI Controlled';
      case 'scheduled':
        return 'Scheduled';
      default:
        return controlMode;
    }
  }

  /// Runtime since current operation started.
  Duration? get currentRuntime {
    if (!isOn || currentOperation?.startedAt == null) return null;
    return DateTime.now().difference(currentOperation!.startedAt!);
  }

  String get runtimeDisplay {
    final runtime = currentRuntime;
    if (runtime == null) return '--';
    if (runtime.inMinutes < 60) return '${runtime.inMinutes}m';
    if (runtime.inHours < 24) return '${runtime.inHours}h ${runtime.inMinutes % 60}m';
    return '${runtime.inDays}d ${runtime.inHours % 24}h';
  }
}

// ============================================
// NESTED DATA CLASSES
// ============================================

class ActuatorAiControl {
  final bool enabled;
  final double riskScoreThreshold;
  final double predictionConfidenceThreshold;

  const ActuatorAiControl({
    this.enabled = false,
    this.riskScoreThreshold = 70,
    this.predictionConfidenceThreshold = 0.8,
  });

  factory ActuatorAiControl.fromJson(Map<String, dynamic> json) {
    return ActuatorAiControl(
      enabled: json['enabled'] ?? false,
      riskScoreThreshold: (json['risk_score_threshold'] as num?)?.toDouble() ?? 70,
      predictionConfidenceThreshold:
          (json['prediction_confidence_threshold'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

class ActuatorCurrentOperation {
  final DateTime? startedAt;
  final String? triggeredBy;
  final String? triggerType;
  final Map<String, dynamic>? targetConditions;

  const ActuatorCurrentOperation({
    this.startedAt,
    this.triggeredBy,
    this.triggerType,
    this.targetConditions,
  });

  factory ActuatorCurrentOperation.fromJson(Map<String, dynamic> json) {
    return ActuatorCurrentOperation(
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      triggeredBy: json['triggered_by']?.toString(),
      triggerType: json['trigger_type']?.toString(),
      targetConditions: json['target_conditions'] is Map
          ? Map<String, dynamic>.from(json['target_conditions'])
          : null,
    );
  }
}

class ActuatorHealthMetrics {
  final DateTime? lastHeartbeat;
  final double uptimePercentage;
  final int errorCount;
  final int totalOperations;
  final double totalRuntimeHours;

  const ActuatorHealthMetrics({
    this.lastHeartbeat,
    this.uptimePercentage = 0,
    this.errorCount = 0,
    this.totalOperations = 0,
    this.totalRuntimeHours = 0,
  });

  factory ActuatorHealthMetrics.fromJson(Map<String, dynamic> json) {
    return ActuatorHealthMetrics(
      lastHeartbeat: json['last_heartbeat'] != null
          ? DateTime.tryParse(json['last_heartbeat'].toString())
          : null,
      uptimePercentage: (json['uptime_percentage'] as num?)?.toDouble() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      totalOperations: (json['total_operations'] as num?)?.toInt() ?? 0,
      totalRuntimeHours: (json['total_runtime_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ActuatorPerformanceMetrics {
  final ActuatorEnergyConsumption? energyConsumption;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenanceDue;
  final int maintenanceIntervalDays;

  const ActuatorPerformanceMetrics({
    this.energyConsumption,
    this.lastMaintenance,
    this.nextMaintenanceDue,
    this.maintenanceIntervalDays = 30,
  });

  factory ActuatorPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return ActuatorPerformanceMetrics(
      energyConsumption: json['energy_consumption'] is Map
          ? ActuatorEnergyConsumption.fromJson(
              Map<String, dynamic>.from(json['energy_consumption']))
          : null,
      lastMaintenance: json['last_maintenance'] != null
          ? DateTime.tryParse(json['last_maintenance'].toString())
          : null,
      nextMaintenanceDue: json['next_maintenance_due'] != null
          ? DateTime.tryParse(json['next_maintenance_due'].toString())
          : null,
      maintenanceIntervalDays:
          (json['maintenance_interval_days'] as num?)?.toInt() ?? 30,
    );
  }
}

class ActuatorEnergyConsumption {
  final double current;
  final double average;
  final double totalKwh;

  const ActuatorEnergyConsumption({
    this.current = 0,
    this.average = 0,
    this.totalKwh = 0,
  });

  factory ActuatorEnergyConsumption.fromJson(Map<String, dynamic> json) {
    return ActuatorEnergyConsumption(
      current: (json['current'] as num?)?.toDouble() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0,
      totalKwh: (json['total_kwh'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ActuatorSafetyLimits {
  final int maxRuntimeHours;
  final int cooldownPeriodMinutes;

  const ActuatorSafetyLimits({
    this.maxRuntimeHours = 24,
    this.cooldownPeriodMinutes = 5,
  });

  factory ActuatorSafetyLimits.fromJson(Map<String, dynamic> json) {
    return ActuatorSafetyLimits(
      maxRuntimeHours: (json['max_runtime_hours'] as num?)?.toInt() ?? 24,
      cooldownPeriodMinutes:
          (json['cooldown_period_minutes'] as num?)?.toInt() ?? 5,
    );
  }
}

class ActuatorSchedule {
  final bool enabled;
  final String? cronExpression;
  final Map<String, dynamic>? activeHours;
  final List<int>? daysOfWeek;

  const ActuatorSchedule({
    this.enabled = false,
    this.cronExpression,
    this.activeHours,
    this.daysOfWeek,
  });

  factory ActuatorSchedule.fromJson(Map<String, dynamic> json) {
    return ActuatorSchedule(
      enabled: json['enabled'] ?? false,
      cronExpression: json['cron_expression']?.toString(),
      activeHours: json['active_hours'] is Map
          ? Map<String, dynamic>.from(json['active_hours'])
          : null,
      daysOfWeek: json['days_of_week'] is List
          ? (json['days_of_week'] as List).map((e) => (e as num).toInt()).toList()
          : null,
    );
  }
}
