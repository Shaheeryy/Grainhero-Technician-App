import 'package:intl/intl.dart';

class ActivityLogModel {
  final String id;
  final String action;
  final String category;
  final String entityType;
  final String entityRef;
  final String description;
  final String severity;
  final String userName;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.action,
    required this.category,
    required this.entityType,
    required this.entityRef,
    required this.description,
    required this.severity,
    required this.userName,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['_id'] ?? '',
      action: json['action'] ?? 'unknown',
      category: json['category'] ?? 'system',
      entityType: json['entity_type'] ?? '',
      entityRef: json['entity_ref'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
      userName: json['user_name'] ?? 'System',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(createdAt);
  }
}
