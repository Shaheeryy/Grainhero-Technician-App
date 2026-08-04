class AlertModel {
  final String id;
  final String title;
  final String message;
  final String? description;
  final String category;
  final String severity;
  final String status;
  final String? location;
  final String? siloId;
  final String? batchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    this.description,
    required this.category,
    required this.severity,
    required this.status,
    this.location,
    this.siloId,
    this.batchId,
    required this.createdAt,
    required this.updatedAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['message'] ?? '',
      message: json['message'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'environmental',
      severity: json['severity'] ?? json['priority'] ?? 'low',
      status: json['status'] ?? 'active',
      location: json['location'] ?? json['silos']?['name'] ?? json['silo_id']?['name'],
      siloId: json['silo_id'] is String
          ? json['silo_id']
          : json['silo_id']?['id'] ?? json['silo_id']?['_id'],
      batchId: json['batch_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  bool get acknowledged => acknowledgedAt != null;

  String getSeverityLabel() {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return 'High';
      case 'medium':
      case 'moderate':
        return 'Medium';
      default:
        return 'Low';
    }
  }
}
