import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/actuator_model.dart';
import '../utils/secure_storage.dart';

/// Service for managing actuator devices — NO mock data, real API only.
class ActuatorService {
  /// Get all actuators from the dedicated /api/actuators endpoint,
  /// and also check /api/sensors for hybrid devices with actuator capabilities.
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
    if (status != null) queryParams['status'] = status;
    if (actuatorType != null) queryParams['actuator_type'] = actuatorType;

    final List<ActuatorModel> allActuators = [];
    final Set<String> seenIds = {};
    Map<String, dynamic> pagination = {};

    // 1. Fetch from dedicated /api/actuators endpoint (primary source)
    try {
      final actuatorUri = Uri.parse(ApiConfig.actuators).replace(queryParameters: queryParams);
      debugPrint('🔧 ACTUATOR API: GET $actuatorUri');
      final actuatorResponse = await http
          .get(actuatorUri, headers: ApiConfig.getHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint('🔧 ACTUATOR API: Status ${actuatorResponse.statusCode}');

      if (actuatorResponse.statusCode == 200) {
        final data = jsonDecode(actuatorResponse.body);
        final List actuatorList = data['actuators'] ?? data['data'] ?? [];
        debugPrint('🔧 ACTUATOR API: Found ${actuatorList.length} actuators');
        for (final json in actuatorList) {
          final model = ActuatorModel.fromJson(json as Map<String, dynamic>);
          if (!seenIds.contains(model.id)) {
            seenIds.add(model.id);
            allActuators.add(model);
          }
        }
        pagination = data['pagination'] ?? {};
      }
    } catch (e) {
      debugPrint('🔧 ACTUATOR API: Error fetching from /api/actuators: $e');
    }

    // 2. Also check /api/sensors for hybrid devices with actuator capabilities (fan, led, servo, pwm)
    try {
      final sensorParams = <String, String>{
        'page': '1',
        'limit': '100',
      };
      if (siloId != null) sensorParams['silo_id'] = siloId;

      final sensorUri = Uri.parse(ApiConfig.sensors).replace(queryParameters: sensorParams);
      final sensorResponse = await http
          .get(sensorUri, headers: ApiConfig.getHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      if (sensorResponse.statusCode == 200) {
        final data = jsonDecode(sensorResponse.body);
        final List sensorsList = data['sensors'] ?? data['data'] ?? [];
        final hybridDevices = sensorsList.where((sensor) {
          if (sensor['device_type'] == 'actuator') return true;
          final capabilities = sensor['capabilities'];
          if (capabilities != null) {
            if (capabilities['fan'] == true) return true;
            if (capabilities['led'] == true) return true;
            if (capabilities['servo'] == true) return true;
            if (capabilities['pwm'] == true) return true;
          }
          return false;
        }).toList();

        for (final json in hybridDevices) {
          final model = ActuatorModel.fromJson(json as Map<String, dynamic>);
          if (!seenIds.contains(model.id)) {
            seenIds.add(model.id);
            allActuators.add(model);
          }
        }
        debugPrint('🔧 ACTUATOR API: Found ${hybridDevices.length} hybrid sensor-actuators');
      }
    } catch (e) {
      debugPrint('🔧 ACTUATOR API: Error fetching hybrid sensors: $e');
    }

    debugPrint('🔧 ACTUATOR API: Total actuators: ${allActuators.length}');

    return {
      'actuators': allActuators,
      'pagination': pagination,
    };
  }

  /// Toggle actuator ON/OFF — sends `{ action: 'turn_on' / 'turn_off' }` to IoT command endpoint
  static Future<ActuatorModel> toggleActuator(String actuatorId, bool newState) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.iotDeviceControl(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'action': newState ? 'turn_on' : 'turn_off',
            'duration': 60, // Optional duration
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      // The IoT endpoint returns a partial device object. 
      // Instead of throwing an error that breaks the UI, we return an empty ActuatorModel.
      // The UI will reload the full list using _loadActuators() automatically.
      return ActuatorModel(id: actuatorId, actuatorId: actuatorId, name: 'Updating...', actuatorType: 'fan', siloId: '', siloName: '', siloCode: '', status: 'active', operationStatus: '', healthStatus: '', maintenanceStatus: '');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to toggle actuator');
    }
  }

  /// Set power level — sends `{ action: 'set_value', value: level }` to IoT command endpoint
  static Future<ActuatorModel> setPowerLevel(String actuatorId, int level) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.iotDeviceControl(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'action': 'set_value',
            'value': level,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Return dummy model to prevent exception, UI will reload.
      return ActuatorModel(id: actuatorId, actuatorId: actuatorId, name: 'Updating...', actuatorType: 'fan', siloId: '', siloName: '', siloCode: '', status: 'active', operationStatus: '', healthStatus: '', maintenanceStatus: '');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to set power level');
    }
  }

  /// Get actuator details by ID (using the sensors endpoint)
  static Future<ActuatorModel> getActuatorById(String actuatorId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          Uri.parse(ApiConfig.sensorDetails(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sensorJson = data['sensor'] ?? data['data'] ?? data;
      return ActuatorModel.fromJson(sensorJson as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Actuator not found');
    } else {
      throw Exception('Failed to fetch actuator details');
    }
  }

  /// Log maintenance for actuator.
  static Future<bool> logMaintenance(
    String actuatorId, {
    required String maintenanceType,
    required String notes,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.actuatorMaintenance(actuatorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'maintenance_type': maintenanceType,
            'maintenance_actions': ['Visual Inspection', 'Testing'],
            'notes': notes.isEmpty ? 'Routine maintenance' : notes,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      if (response.statusCode == 404) throw Exception('Actuator not found');
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
