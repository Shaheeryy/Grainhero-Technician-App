class GrainBatch {
  final String id;
  final String batchId;
  final String? siloId;
  final SiloInfo? silo;
  final String grainType;
  final double quantityKg;
  final String? variety;
  final String? grade;
  final double? moistureContent;
  final String status;
  final int riskScore;
  final int? qualityScore;
  final String spoilageLabel;
  final DateTime intakeDate;
  final DateTime createdAt;
  final String? farmerName;
  final String? farmerContact;
  final String? harvestDate;
  final String? qrCode;
  final String adminId;

  GrainBatch({
    required this.id,
    required this.batchId,
    this.siloId,
    this.silo,
    required this.grainType,
    required this.quantityKg,
    this.variety,
    this.grade,
    this.moistureContent,
    required this.status,
    required this.riskScore,
    this.qualityScore,
    required this.spoilageLabel,
    required this.intakeDate,
    required this.createdAt,
    this.farmerName,
    this.farmerContact,
    this.harvestDate,
    this.qrCode,
    required this.adminId,
  });

  factory GrainBatch.fromJson(Map<String, dynamic> json) {
    return GrainBatch(
      id: json['_id'] ?? json['id'] ?? '',
      batchId: json['batch_id'] ?? '',
      siloId: json['silo_id'] is String
          ? json['silo_id']
          : json['silo_id']?['_id'] ?? json['silo_id']?['id'],
      silo: json['silo_id'] is Map ? SiloInfo.fromJson(json['silo_id']) : null,
      grainType: json['grain_type'] ?? '',
      quantityKg: (json['quantity_kg'] ?? 0).toDouble(),
      variety: json['variety'],
      grade: json['grade'],
      moistureContent: json['moisture_content']?.toDouble(),
      status: json['status'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      qualityScore: json['quality_score'],
      spoilageLabel: json['spoilage_label'] ?? 'safe',
      intakeDate: json['intake_date'] != null
          ? DateTime.parse(json['intake_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      farmerName: json['farmer_name'],
      farmerContact: json['farmer_contact'],
      harvestDate: json['harvest_date'],
      qrCode: json['qr_code'],
      adminId: json['admin_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'batch_id': batchId,
      'silo_id': siloId,
      'grain_type': grainType,
      'quantity_kg': quantityKg,
      'variety': variety,
      'grade': grade,
      'moisture_content': moistureContent,
      'status': status,
      'risk_score': riskScore,
      'quality_score': qualityScore,
      'spoilage_label': spoilageLabel,
      'intake_date': intakeDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'farmer_name': farmerName,
      'farmer_contact': farmerContact,
      'harvest_date': harvestDate,
      'qr_code': qrCode,
      'admin_id': adminId,
    };
  }
}

class SiloInfo {
  final String id;
  final String name;
  final String siloId;
  final double? capacityKg;

  SiloInfo({
    required this.id,
    required this.name,
    required this.siloId,
    this.capacityKg,
  });

  factory SiloInfo.fromJson(Map<String, dynamic> json) {
    return SiloInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      siloId: json['silo_id'] ?? '',
      capacityKg: json['capacity_kg']?.toDouble(),
    );
  }
}
