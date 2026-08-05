import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert_model.dart';

class AlertService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch alerts
  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final data = await _supabase
          .from('grain_alerts')
          .select('*, silos(name), warehouses(name), grain_batches(grain_type)')
          .order('triggered_at', ascending: false);

      final alerts = (data as List).map((alert) => AlertModel.fromJson(alert)).toList();
      return alerts;
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      throw Exception('Failed to load alerts');
    }
  }

  // Acknowledge alert
  Future<bool> acknowledgeAlert(String alertId, {String? notes}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    try {
      final updates = <String, dynamic>{
        'status': 'acknowledged',
        'acknowledged_at': DateTime.now().toIso8601String(),
        'acknowledged_by': user.id,
      };
      
      if (notes != null && notes.isNotEmpty) {
        updates['notes'] = notes; // or resolution_notes depending on schema
      }

      await _supabase
          .from('grain_alerts')
          .update(updates)
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Error acknowledging alert: $e');
      throw Exception('Failed to acknowledge alert');
    }
  }
}
