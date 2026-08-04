import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/silo_model.dart';
import 'package:flutter/foundation.dart';

class SiloService {
  static final _supabase = Supabase.instance.client;

  static Future<List<SiloModel>> getSilos() async {
    try {
      // Query silos and fetch the joined current batch and latest sensor reading
      final data = await _supabase
          .from('silos')
          .select('*, current_batch:grain_batches!fk_silos_current_batch(id, batch_id, grain_type), sensor_readings(temperature, temperature_value, humidity, humidity_value, tvoc, voc_value, co2, reading_timestamp)')
          .order('created_at', ascending: false)
          .limit(500);
      
      // We manually sort/limit the sensor readings since PostgREST nested limits can be tricky, 
      // but assuming the view or relation returns them, the model will pick the first one.
      
      final silos = (data as List).map((json) {
        // Sort sensor readings if present so the newest is first
        if (json['sensor_readings'] != null && json['sensor_readings'] is List) {
          final readings = json['sensor_readings'] as List;
          readings.sort((a, b) {
            final t1 = a['reading_timestamp'] ?? a['timestamp'] ?? '';
            final t2 = b['reading_timestamp'] ?? b['timestamp'] ?? '';
            return t2.compareTo(t1); // Descending
          });
        }
        return SiloModel.fromJson(json);
      }).toList();

      return silos;
    } catch (e) {
      debugPrint('Failed to load silos: $e');
      throw Exception('Failed to load silos');
    }
  }
}
