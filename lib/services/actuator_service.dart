import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/actuator_model.dart';
import '../utils/secure_storage.dart';

/// Service for managing actuator devices — NO mock data, real API only.
class ActuatorService {
  /// Get all actuators with optional filters.
  static Future<Map<String, dynamic>> getActuators({
    String? siloId,
    String? actuatorType,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (siloId != null) queryParams['silo_id'] = siloId;
    if (actuatorType != null) queryParams['actuator_type'] = actuatorType;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(ApiConfig.actuators).replace(queryParameters: queryParams);

    final response = await http
        .get(uri, headers: ApiConfig.getHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List actuatorsList = data['actuators'] ?? data['data'] ?? [];
      return {
        'actuators': actuatorsList
            .map((json) => ActuatorModel.fromJson(json as Map<String, dynamic>))
            .toList(),
        'pagination': data['pagination'] ?? {},
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch actuators');
    }
  }

  /// Toggle actuator ON/OFF — sends correct `{ action, triggered_by }` body.
  static Future<ActuatorModel> toggleActuator(String actuatorId, bool newState) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.actuatorControl(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'action': newState ? 'on' : 'off',
            'triggered_by': 'Manual',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['actuator'] != null) {
        return ActuatorModel.fromJson(data['actuator'] as Map<String, dynamic>);
      }
      // If server doesn't return full actuator, we rely on caller to refresh
      throw Exception('_no_actuator_in_response');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Bad request');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Actuator not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to toggle actuator');
    }
  }

  /// Set power level — sends `{ action: 'set_power', power_level, triggered_by }`.
  static Future<ActuatorModel> setPowerLevel(String actuatorId, int level) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.actuatorControl(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'action': 'set_power',
            'power_level': level,
            'triggered_by': 'Manual',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['actuator'] != null) {
        return ActuatorModel.fromJson(data['actuator'] as Map<String, dynamic>);
      }
      throw Exception('_no_actuator_in_response');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to set power level');
    }
  }

  /// Get actuator details by ID.
  static Future<ActuatorModel> getActuatorById(String actuatorId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          Uri.parse(ApiConfig.actuatorDetails(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ActuatorModel.fromJson(data as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Actuator not found');
    } else {
      throw Exception('Failed to fetch actuator details');
    }
  }

  /// Log maintenance activity.
  static Future<bool> logMaintenance(
    String actuatorId, {
    required String maintenanceType,
    required String notes,
    int? nextMaintenanceDays,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      'maintenance_type': maintenanceType,
      'notes': notes,
    };
    if (nextMaintenanceDays != null) {
      body['next_maintenance_days'] = nextMaintenanceDays;
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.actuatorMaintenance(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to log maintenance');
    }
  }

  /// Bulk control — turn ON/OFF multiple actuators.
  static Future<Map<String, dynamic>> bulkControl({
    required List<String> actuatorIds,
    required String action,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse('${ApiConfig.actuators}/bulk-control'),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'actuator_ids': actuatorIds,
            'action': action,
            'triggered_by': 'Manual',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Bulk control failed');
    }
  }
}
