import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_model.dart';

class SensorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all sensors with pagination and filters.
  Future<Map<String, dynamic>> getAllSensors({
    int page = 1,
    int limit = 20,
    String? status,
    String? siloId,
  }) async {
    try {
      var query = _supabase
          .from('sensor_devices')
          .select('*, silos(id, silo_id, name), warehouses(id, name, warehouse_id)');
          
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (siloId != null && siloId.isNotEmpty) {
        query = query.eq('silo_id', siloId);
      }

      // Pagination
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final data = await query.range(from, to).order('created_at', ascending: false);
      
      final sensors = (data as List).map((e) => SensorDevice.fromJson(e)).toList();
      
      return {
        'sensors': sensors,
        'pagination': {
          'page': page,
          'limit': limit,
          // 'total': count might be fetched using count() if needed
        },
      };
    } catch (e) {
      debugPrint('Error getting sensors: $e');
      throw Exception('Failed to load sensors');
    }
  }

  /// Fetch sensor details by ID (includes recent_readings).
  Future<SensorDevice> fetchSensorDetails(String sensorId) async {
    try {
      final sensorData = await _supabase
          .from('sensor_devices')
          .select('*')
          .eq('id', sensorId)
          .single();
          
      final readingsData = await _supabase
          .from('sensor_readings')
          .select('*')
          .eq('device_id', sensorId)
          .order('reading_timestamp', ascending: false)
          .limit(10);
          
      final json = Map<String, dynamic>.from(sensorData);
      json['recent_readings'] = readingsData;

      return SensorDevice.fromJson(json);
    } catch (e) {
      debugPrint('Error fetching sensor details: $e');
      throw Exception('Failed to load sensor details');
    }
  }

  /// Get sensor readings (time-series).
  Future<Map<String, dynamic>> getSensorReadings(
    String sensorId, {
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var filterBuilder = _supabase
          .from('sensor_readings')
          .select('*')
          .eq('device_id', sensorId);

      if (startDate != null) {
        filterBuilder = filterBuilder.gte('reading_timestamp', startDate);
      }
      if (endDate != null) {
        filterBuilder = filterBuilder.lte('reading_timestamp', endDate);
      }

      final query = filterBuilder
          .order('reading_timestamp', ascending: false)
          .limit(limit);

      final data = await query;
      
      final readings = (data as List).map((r) => SensorReading.fromJson(r)).toList();
      
      return {
        'readings': readings,
        'total_readings': readings.length,
        'date_range': {'start': startDate, 'end': endDate},
      };
    } catch (e) {
      debugPrint('Error getting sensor readings: $e');
      throw Exception('Failed to load sensor readings');
    }
  }

  /// Calibrate sensor.
  Future<bool> calibrateSensor(String sensorId) async {
    try {
      await _supabase
          .from('sensor_devices')
          .update({
            'last_calibration_date': DateTime.now().toIso8601String(),
            // Ensure calibration interval is respected (e.g. defaulting to 365 days if missing)
            'calibration_interval_days': 365,
          })
          .eq('id', sensorId);
      return true;
    } catch (e) {
      debugPrint('Error calibrating sensor: $e');
      throw Exception('Failed to calibrate sensor');
    }
  }

  /// Log sensor maintenance.
  Future<bool> logSensorMaintenance(String sensorId, String notes) async {
    // ⚠️ Gap G4: No maintenance table exists in Supabase schema yet.
    // Throw an error until the schema is decided.
    throw Exception('Maintenance logging is disabled during migration (Gap G4). Please wait for database updates.');
  }

  /// Fetch dashboard data.
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      // Manual aggregation since Dashboard Edge Function does not exist
      final siloResponse = await _supabase.from('silos').select('id');
      final batchResponse = await _supabase.from('grain_batches').select('id');
      // grain_alerts.status is a Postgres enum: pending | acknowledged | resolved
      // (no 'active' value exists) — "active" here means not yet resolved.
      final alertResponse = await _supabase.from('grain_alerts').select('id').neq('status', 'resolved');
      
      final siloCount = (siloResponse as List).length;
      final batchCount = (batchResponse as List).length;
      final alertCount = (alertResponse as List).length;
      
      // For now, fetch latest objects for recent lists
      final recentSilos = await _supabase.from('silos').select('*').limit(5);
      final recentBatches = await _supabase.from('grain_batches').select('*').limit(5);
      final recentAlerts = await _supabase.from('grain_alerts').select('*').neq('status', 'resolved').limit(5);

      return {
        'stats': {
          'totalSilos': siloCount,
          'activeBatches': batchCount,
          'activeAlerts': alertCount,
          'criticalAlerts': 0,
        },
        'silos': recentSilos,
        'recentBatches': recentBatches,
        'alerts': recentAlerts,
        'capacityStats': {
          'totalCapacityKg': 0,
          'usedCapacityKg': 0,
          'utilizationPercentage': 0,
        },
      };
    } catch (e) {
      debugPrint('Dashboard aggregate failed: $e');
      throw Exception('Failed to load dashboard data via manual queries.');
    }
  }
}
