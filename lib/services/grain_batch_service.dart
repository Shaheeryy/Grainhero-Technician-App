import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grain_batch_model.dart';

class GrainBatchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all grain batches with pagination and filters
  Future<Map<String, dynamic>> getGrainBatches({
    int page = 1,
    int limit = 10,
    String? status,
    String? grainType,
    String? siloId,
  }) async {
    try {
      var query = _supabase
          .from('grain_batches')
          .select('*, silos(id, name, silo_id)');
          
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (grainType != null && grainType.isNotEmpty) {
        query = query.eq('grain_type', grainType);
      }
      if (siloId != null && siloId.isNotEmpty) {
        query = query.eq('silo_id', siloId);
      }

      // Pagination
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final data = await query.range(from, to).order('created_at', ascending: false);
      
      final batches = (data as List).map((e) => GrainBatch.fromJson(e)).toList();
      
      return {
        'batches': batches,
        'pagination': {
          'page': page,
          'limit': limit,
        },
      };
    } catch (e) {
      debugPrint('Error getting grain batches: $e');
      throw Exception('Failed to load grain batches');
    }
  }

  /// Get grain batch by ID
  Future<GrainBatch> getGrainBatchById(String id) async {
    try {
      final data = await _supabase
          .from('grain_batches')
          .select('*, silos(id, name, silo_id)')
          .eq('id', id)
          .single();
          
      return GrainBatch.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching grain batch: $e');
      throw Exception('Failed to load grain batch');
    }
  }

  /// Update grain batch status
  Future<GrainBatch> updateGrainBatch(
    String id, {
    String? status,
    // Note: qualityScore is dropped as it's not in the Supabase schema
    double? moistureContent,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status != null) updates['status'] = status;
    if (moistureContent != null) updates['moisture_content'] = moistureContent;

    try {
      final data = await _supabase
          .from('grain_batches')
          .update(updates)
          .eq('id', id)
          .select('*, silos(id, name, silo_id)')
          .single();
          
      return GrainBatch.fromJson(data);
    } catch (e) {
      debugPrint('Error updating grain batch: $e');
      throw Exception('Failed to update grain batch');
    }
  }
}
