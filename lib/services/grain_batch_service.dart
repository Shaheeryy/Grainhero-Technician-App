import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/grain_batch_model.dart';
import '../utils/secure_storage.dart';

class GrainBatchService {
  /// Get all grain batches with pagination and filters
  Future<Map<String, dynamic>> getGrainBatches({
    int page = 1,
    int limit = 10,
    String? status,
    String? grainType,
    String? siloId,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (grainType != null) queryParams['grain_type'] = grainType;
    if (siloId != null) queryParams['silo_id'] = siloId;

    final uri = Uri.parse(
      ApiConfig.grainBatches,
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'batches':
            (data['batches'] as List<dynamic>?)
                ?.map((e) => GrainBatch.fromJson(e))
                .toList() ??
            [],
        'pagination': data['pagination'] ?? {},
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load grain batches');
    }
  }

  /// Get grain batch by ID
  Future<GrainBatch> getGrainBatchById(String id) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(ApiConfig.grainBatchDetails(id)),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GrainBatch.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Batch not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load grain batch');
    }
  }

  /// Update grain batch status
  Future<GrainBatch> updateGrainBatch(
    String id, {
    String? status,
    int? qualityScore,
    double? moistureContent,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (qualityScore != null) body['quality_score'] = qualityScore;
    if (moistureContent != null) body['moisture_content'] = moistureContent;

    final response = await http.patch(
      Uri.parse(ApiConfig.updateGrainBatch(id)),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GrainBatch.fromJson(data['batch'] ?? data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 403) {
      throw Exception('Insufficient permissions');
    } else if (response.statusCode == 404) {
      throw Exception('Batch not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update grain batch');
    }
  }
}
