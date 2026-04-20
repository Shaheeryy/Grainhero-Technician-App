/// Model class for actuator devices (fans, lids, ventilation systems)
class ActuatorModel {
  final String id;
  final String name;
  final String type; // 'fan', 'lid', 'ventilation', 'heater', 'cooler'
  final String? siloId;
  final String? siloName;
  final bool isOn;
  final String status; // 'active', 'offline', 'error'
  final DateTime? lastAction;
  final String? lastActionBy;
  final Map<String, dynamic>? settings;

  ActuatorModel({
    required this.id,
    required this.name,
    required this.type,
    this.siloId,
    this.siloName,
    required this.isOn,
    required this.status,
    this.lastAction,
    this.lastActionBy,
    this.settings,
  });

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    return ActuatorModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Actuator',
      type: json['type']?.toString() ?? 'fan',
      siloId: json['siloId']?.toString() ?? json['silo_id']?.toString(),
      siloName: json['siloName']?.toString() ?? json['silo_name']?.toString() ?? json['silo']?['name']?.toString(),
      isOn: json['isOn'] == true || json['is_on'] == true || json['state'] == 'on',
      status: json['status']?.toString() ?? 'active',
      lastAction: json['lastAction'] != null || json['last_action'] != null
          ? DateTime.tryParse(json['lastAction'] ?? json['last_action'])
          : null,
      lastActionBy: json['lastActionBy']?.toString() ?? json['last_action_by']?.toString(),
      settings: json['settings'] is Map ? Map<String, dynamic>.from(json['settings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'siloId': siloId,
      'siloName': siloName,
      'isOn': isOn,
      'status': status,
      'lastAction': lastAction?.toIso8601String(),
      'lastActionBy': lastActionBy,
      'settings': settings,
    };
  }

  ActuatorModel copyWith({
    String? id,
    String? name,
    String? type,
    String? siloId,
    String? siloName,
    bool? isOn,
    String? status,
    DateTime? lastAction,
    String? lastActionBy,
    Map<String, dynamic>? settings,
  }) {
    return ActuatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      siloId: siloId ?? this.siloId,
      siloName: siloName ?? this.siloName,
      isOn: isOn ?? this.isOn,
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      lastActionBy: lastActionBy ?? this.lastActionBy,
      settings: settings ?? this.settings,
    );
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'fan':
        return 'Fan';
      case 'lid':
        return 'Lid';
      case 'ventilation':
        return 'Ventilation';
      case 'heater':
        return 'Heater';
      case 'cooler':
        return 'Cooler';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'offline':
        return 'Offline';
      case 'error':
        return 'Error';
      default:
        return status;
    }
  }
}
