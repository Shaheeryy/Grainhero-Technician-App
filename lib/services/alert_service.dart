import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/alert_model.dart';
import '../utils/secure_storage.dart';

class AlertService {
  // Fetch alerts
  Future<List<AlertModel>> fetchAlerts() async {
    final token = await SecureStorage.getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.alerts),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alertsData = data['alerts'] ?? data['data'] ?? [];

        if (alertsData is List) {
          return alertsData.map((alert) => AlertModel.fromJson(alert)).toList();
        }
        // If no alerts, return empty list
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        // No alerts found - return empty list instead of error
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load alerts');
      }
    } catch (e) {
      // If it's a format exception or network error, provide better message
      if (e.toString().contains('FormatException') ||
          e.toString().contains('SocketException')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      throw Exception('Failed to load alerts: ${e.toString()}');
    }
  }

  // Acknowledge alert
  Future<bool> acknowledgeAlert(String alertId, {String? notes}) async {
    final token = await SecureStorage.getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final body = <String, dynamic>{};
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await http.patch(
        Uri.parse(ApiConfig.acknowledgeAlert(alertId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Alert not found');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to acknowledge alert');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
