import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/activity_log_model.dart';
import '../utils/secure_storage.dart';

class ActivityLogService {
  /// Fetch paginated activity logs
  static Future<Map<String, dynamic>> fetchLogs({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    var uri = Uri.parse('${ApiConfig.activityLogs}?page=$page&limit=$limit');
    if (category != null && category.isNotEmpty) {
      uri = Uri.parse('${uri.toString()}&category=$category');
    }

    final response = await http
        .get(
          uri,
          headers: ApiConfig.getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List logsList = data['logs'] ?? [];

      return {
        'logs': logsList.map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>)).toList(),
        'pagination': data['pagination'] ?? {},
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch logs');
    }
  }
}
