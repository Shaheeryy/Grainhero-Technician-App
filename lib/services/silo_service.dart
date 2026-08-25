import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/silo_model.dart';
import 'package:flutter/foundation.dart';

class SiloService {
  static final _supabase = Supabase.instance.client;

  static Future<List<SiloModel>> getSilos() async {
    try {
      // Query silos and fetch the joined current batch and latest sensor
      // reading only — ordering/limiting the nested join server-side avoids
      // pulling each silo's entire reading history just to pick the newest.
      final data = await _supabase
          .from('silos')
          .select('*, current_batch:grain_batches!fk_silos_current_batch(id, batch_id, grain_type), sensor_readings(temperature_value, humidity_value, voc_value, co2_value, moisture_value, reading_timestamp)')
          .order('created_at', ascending: false)
          .order('reading_timestamp', ascending: false, referencedTable: 'sensor_readings')
          .limit(500)
          .limit(1, referencedTable: 'sensor_readings');

      final silos = (data as List).map((json) => SiloModel.fromJson(json)).toList();

      return silos;
    } catch (e) {
      debugPrint('Failed to load silos: $e');
      throw Exception('Failed to load silos');
    }
  }
}
