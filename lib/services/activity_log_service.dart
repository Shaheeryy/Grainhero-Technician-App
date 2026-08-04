import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';

class ActivityLogService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch paginated activity logs
  static Future<Map<String, dynamic>> fetchLogs({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      var query = _supabase
          .from('activity_logs')
          .select('*');
          
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Pagination
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final data = await query.range(from, to).order('created_at', ascending: false);
      
      final logs = (data as List).map((json) => ActivityLogModel.fromJson(json)).toList();
      
      return {
        'logs': logs,
        'pagination': {
          'page': page,
          'limit': limit,
        },
      };
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      throw Exception('Failed to fetch logs');
    }
  }
}
