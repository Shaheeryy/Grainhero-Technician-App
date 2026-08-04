import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/actuator_model.dart';

/// Service for managing actuator devices
class ActuatorService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all actuators
  static Future<Map<String, dynamic>> getActuators({
    String? siloId,
    String? actuatorType,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('actuators').select('*');
      
      if (siloId != null && siloId.isNotEmpty) {
        query = query.eq('silo_id', siloId);
      }
      if (actuatorType != null && actuatorType.isNotEmpty) {
        query = query.eq('type', actuatorType);
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final data = await query.range(from, to).order('created_at', ascending: false);
      
      final List<ActuatorModel> allActuators = (data as List)
          .map((json) => ActuatorModel.fromJson(json))
          .toList();

      return {
        'actuators': allActuators,
        'pagination': {
          'page': page,
          'limit': limit,
        },
      };
    } catch (e) {
      debugPrint('🔧 ACTUATOR API: Error fetching actuators: $e');
      throw Exception('Failed to fetch actuators');
    }
  }

  /// Toggle actuator ON/OFF
  static Future<ActuatorModel> toggleActuator(String actuatorId, bool newState) async {
    try {
      await _supabase.from('actuator_commands').insert({
        'actuator_id': actuatorId,
        'command': newState ? 'on' : 'off',
        'params': {},
        'source': 'manual'
      });
      
      // Optionally log to activity_logs
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('activity_logs').insert({
          'user_id': user.id,
          'action': newState ? 'turn_on' : 'turn_off',
          'category': 'actuator_control',
          'entity_type': 'actuator',
          'entity_ref': actuatorId,
          'description': 'Manually turned ${newState ? 'on' : 'off'} actuator',
          'severity': 'info',
        });
      }

      return getActuatorById(actuatorId);
    } catch (e) {
      debugPrint('Error toggling actuator: $e');
      throw Exception('Failed to control actuator via direct insert.');
    }
  }

  /// Set power level
  static Future<ActuatorModel> setPowerLevel(String actuatorId, int level) async {
    try {
      await _supabase.from('actuator_commands').insert({
        'actuator_id': actuatorId,
        'command': 'set_level',
        'params': {'value': level},
        'source': 'manual'
      });

      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('activity_logs').insert({
          'user_id': user.id,
          'action': 'set_power_level',
          'category': 'actuator_control',
          'entity_type': 'actuator',
          'entity_ref': actuatorId,
          'description': 'Manually set power level to $level',
          'severity': 'info',
        });
      }

      return getActuatorById(actuatorId);
    } catch (e) {
      debugPrint('Error setting actuator power: $e');
      throw Exception('Failed to set power level via direct insert.');
    }
  }

  /// Get actuator details by ID
  static Future<ActuatorModel> getActuatorById(String actuatorId) async {
    try {
      final data = await _supabase
          .from('actuators')
          .select('*')
          .eq('id', actuatorId)
          .single();
          
      return ActuatorModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching actuator: $e');
      throw Exception('Failed to fetch actuator details');
    }
  }

  /// Log maintenance for actuator.
  static Future<bool> logMaintenance(
    String actuatorId, {
    required String maintenanceType,
    required String notes,
  }) async {
    // ⚠️ Gap G4: No maintenance table exists in Supabase schema yet.
    throw Exception('Maintenance logging is disabled during migration (Gap G4).');
  }

  /// Bulk control — turn ON/OFF multiple actuators.
  static Future<Map<String, dynamic>> bulkControl({
    required List<String> actuatorIds,
    required String action, // e.g. 'turn_on' or 'turn_off'
  }) async {
    try {
      final command = (action == 'turn_on') ? 'on' : 'off';
      
      final List<Map<String, dynamic>> inserts = actuatorIds.map((id) => {
        'actuator_id': id,
        'command': command,
        'params': {},
        'source': 'manual_bulk'
      }).toList();

      await _supabase.from('actuator_commands').insert(inserts);

      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('activity_logs').insert({
          'user_id': user.id,
          'action': 'bulk_$action',
          'category': 'actuator_control',
          'entity_type': 'bulk_actuators',
          'entity_ref': actuatorIds.join(','),
          'description': 'Bulk command $command sent to ${actuatorIds.length} actuators',
          'severity': 'info',
        });
      }
      
      return {'success': true, 'count': actuatorIds.length};
    } catch (e) {
      debugPrint('Error executing bulk control: $e');
      throw Exception('Failed to perform bulk control via direct insert.');
    }
  }
}
