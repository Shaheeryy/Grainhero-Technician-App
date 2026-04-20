class DashboardData {
  final List<StatCard> stats;
  final CapacityStats? capacityStats;
  final Map<String, int> grainTypes;
  final List<RecentBatch> recentBatches;
  final List<AlertSummary> alerts;
  final Analytics? analytics;
  final List<SensorSnapshot> sensors;
  final BusinessMetrics? business;

  DashboardData({
    required this.stats,
    this.capacityStats,
    required this.grainTypes,
    required this.recentBatches,
    required this.alerts,
    this.analytics,
    required this.sensors,
    this.business,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats:
          (json['stats'] as List<dynamic>?)
              ?.map((e) => StatCard.fromJson(e))
              .toList() ??
          [],
      capacityStats: json['capacityStats'] != null
          ? CapacityStats.fromJson(json['capacityStats'])
          : null,
      grainTypes: json['grainTypes'] != null
          ? Map<String, int>.from(
              (json['grainTypes'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : {},
      recentBatches:
          (json['recentBatches'] as List<dynamic>?)
              ?.map((e) => RecentBatch.fromJson(e))
              .toList() ??
          [],
      alerts:
          (json['alerts'] as List<dynamic>?)
              ?.map((e) => AlertSummary.fromJson(e))
              .toList() ??
          [],
      analytics: json['analytics'] != null
          ? Analytics.fromJson(json['analytics'])
          : null,
      sensors:
          (json['sensors'] as List<dynamic>?)
              ?.map((e) => SensorSnapshot.fromJson(e))
              .toList() ??
          [],
      business: json['business'] != null
          ? BusinessMetrics.fromJson(json['business'])
          : null,
    );
  }
}

class StatCard {
  final String title;
  final dynamic value;

  StatCard({required this.title, required this.value});

  factory StatCard.fromJson(Map<String, dynamic> json) {
    return StatCard(title: json['title'] ?? '', value: json['value']);
  }
}

class CapacityStats {
  final int totalCapacity;
  final int currentOccupancy;
  final double utilizationPercentage;
  final int availableSpace;

  CapacityStats({
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.utilizationPercentage,
    required this.availableSpace,
  });

  factory CapacityStats.fromJson(Map<String, dynamic> json) {
    return CapacityStats(
      totalCapacity: json['totalCapacity'] ?? 0,
      currentOccupancy: json['currentOccupancy'] ?? 0,
      utilizationPercentage: (json['utilizationPercentage'] ?? 0).toDouble(),
      availableSpace: json['availableSpace'] ?? 0,
    );
  }
}

class RecentBatch {
  final String id;
  final String grain;
  final double quantity;
  final String status;
  final String silo;
  final DateTime date;
  final String risk;

  RecentBatch({
    required this.id,
    required this.grain,
    required this.quantity,
    required this.status,
    required this.silo,
    required this.date,
    required this.risk,
  });

  factory RecentBatch.fromJson(Map<String, dynamic> json) {
    return RecentBatch(
      id: json['id'] ?? '',
      grain: json['grain'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      silo: json['silo'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      risk: json['risk'] ?? 'Low',
    );
  }
}

class AlertSummary {
  final String id;
  final String type;
  final String message;
  final String severity;
  final DateTime time;

  AlertSummary({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.time,
  });

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'low',
      time: json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now(),
    );
  }
}

class Analytics {
  final List<MonthlyIntake> monthlyIntake;
  final List<GrainDistribution> grainDistribution;
  final List<QualityMetric> qualityMetrics;

  Analytics({
    required this.monthlyIntake,
    required this.grainDistribution,
    required this.qualityMetrics,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      monthlyIntake:
          (json['monthlyIntake'] as List<dynamic>?)
              ?.map((e) => MonthlyIntake.fromJson(e))
              .toList() ??
          [],
      grainDistribution:
          (json['grainDistribution'] as List<dynamic>?)
              ?.map((e) => GrainDistribution.fromJson(e))
              .toList() ??
          [],
      qualityMetrics:
          (json['qualityMetrics'] as List<dynamic>?)
              ?.map((e) => QualityMetric.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyIntake {
  final String month;
  final double total;

  MonthlyIntake({required this.month, required this.total});

  factory MonthlyIntake.fromJson(Map<String, dynamic> json) {
    return MonthlyIntake(
      month: json['month'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class GrainDistribution {
  final String grain;
  final int percentage;
  final int quantity;

  GrainDistribution({
    required this.grain,
    required this.percentage,
    required this.quantity,
  });

  factory GrainDistribution.fromJson(Map<String, dynamic> json) {
    return GrainDistribution(
      grain: json['grain'] ?? '',
      percentage: json['percentage'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }
}

class QualityMetric {
  final String quality;
  final int value;

  QualityMetric({required this.quality, required this.value});

  factory QualityMetric.fromJson(Map<String, dynamic> json) {
    return QualityMetric(
      quality: json['quality'] ?? '',
      value: json['value'] ?? 0,
    );
  }
}

class SensorSnapshot {
  final String id;
  final String type;
  final double value;
  final String unit;
  final String status;
  final String location;
  final DateTime lastReading;
  final int? battery;
  final int? signal;

  SensorSnapshot({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.location,
    required this.lastReading,
    this.battery,
    this.signal,
  });

  factory SensorSnapshot.fromJson(Map<String, dynamic> json) {
    return SensorSnapshot(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      status: json['status'] ?? 'active',
      location: json['location'] ?? '',
      lastReading: json['lastReading'] != null
          ? DateTime.parse(json['lastReading'])
          : DateTime.now(),
      battery: json['battery'],
      signal: json['signal'],
    );
  }
}

class BusinessMetrics {
  final int activeBuyers;
  final double avgPrice;
  final int dispatchRate;
  final double qualityScore;

  BusinessMetrics({
    required this.activeBuyers,
    required this.avgPrice,
    required this.dispatchRate,
    required this.qualityScore,
  });

  factory BusinessMetrics.fromJson(Map<String, dynamic> json) {
    return BusinessMetrics(
      activeBuyers: json['activeBuyers'] ?? 0,
      avgPrice: (json['avgPrice'] ?? 0).toDouble(),
      dispatchRate: json['dispatchRate'] ?? 0,
      qualityScore: (json['qualityScore'] ?? 0).toDouble(),
    );
  }
}
