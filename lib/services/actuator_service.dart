import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/actuator_model.dart';
import '../utils/secure_storage.dart';

/// Service for managing actuator devices (fans, lids, ventilation)
class ActuatorService {
  /// Get all actuators
  static Future<List<ActuatorModel>> getActuators({
    String? siloId,
    String? type,
    String? status,
  }) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      String url = ApiConfig.actuators;
      final queryParams = <String, String>{};
      
      if (siloId != null) queryParams['siloId'] = siloId;
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List actuatorsList = data['actuators'] ?? data['data'] ?? data;
        return actuatorsList.map((json) => ActuatorModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // API not implemented yet, return mock data
        debugPrint('Actuators API not found, using mock data');
        return _getMockActuators();
      } else {
        throw Exception('Failed to fetch actuators: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching actuators: $e');
      // Return mock data if API fails
      return _getMockActuators();
    }
  }

  /// Toggle actuator state (on/off)
  static Future<bool> toggleActuator(String actuatorId, bool newState) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.actuatorControl(actuatorId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'state': newState ? 'on' : 'off',
          'isOn': newState,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 404) {
        // API not implemented, simulate success
        debugPrint('Actuator control API not found, simulating success');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to toggle actuator');
      }
    } catch (e) {
      debugPrint('Error toggling actuator: $e');
      // Simulate success for demo purposes
      return true;
    }
  }

  /// Log maintenance activity
  static Future<bool> logMaintenance(String actuatorId, String notes) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(ApiConfig.actuatorMaintenance(actuatorId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'notes': notes}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error logging maintenance: $e');
      // Simulate success for demo
      return true;
    }
  }

  /// Get actuators for a specific silo
  static Future<List<ActuatorModel>> getActuatorsBySilo(String siloId) async {
    return getActuators(siloId: siloId);
  }

  /// Get actuator by ID
  static Future<ActuatorModel?> getActuatorById(String actuatorId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.actuators}/$actuatorId'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActuatorModel.fromJson(data['actuator'] ?? data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching actuator: $e');
      return null;
    }
  }

  /// Mock data for development/demo
  static List<ActuatorModel> _getMockActuators() {
    return [
      ActuatorModel(
        id: 'act_001',
        name: 'Main Ventilation Fan',
        type: 'fan',
        siloId: 'silo_001',
        siloName: 'Silo A - Wheat',
        isOn: true,
        status: 'active',
        lastAction: DateTime.now().subtract(const Duration(hours: 2)),
        lastActionBy: 'John Doe',
      ),
      ActuatorModel(
        id: 'act_002',
        name: 'Top Lid',
        type: 'lid',
        siloId: 'silo_001',
        siloName: 'Silo A - Wheat',
        isOn: false,
        status: 'active',
        lastAction: DateTime.now().subtract(const Duration(days: 1)),
        lastActionBy: 'Jane Smith',
      ),
      ActuatorModel(
        id: 'act_003',
        name: 'Cooling Unit',
        type: 'cooler',
        siloId: 'silo_002',
        siloName: 'Silo B - Rice',
        isOn: true,
        status: 'active',
        lastAction: DateTime.now().subtract(const Duration(minutes: 30)),
        lastActionBy: 'John Doe',
      ),
      ActuatorModel(
        id: 'act_004',
        name: 'Secondary Fan',
        type: 'fan',
        siloId: 'silo_002',
        siloName: 'Silo B - Rice',
        isOn: false,
        status: 'offline',
        lastAction: DateTime.now().subtract(const Duration(days: 7)),
        lastActionBy: 'System',
      ),
      ActuatorModel(
        id: 'act_005',
        name: 'Access Lid',
        type: 'lid',
        siloId: 'silo_003',
        siloName: 'Silo C - Corn',
        isOn: true,
        status: 'active',
        lastAction: DateTime.now().subtract(const Duration(hours: 5)),
        lastActionBy: 'Jane Smith',
      ),
      ActuatorModel(
        id: 'act_006',
        name: 'Ventilation System',
        type: 'ventilation',
        siloId: 'silo_003',
        siloName: 'Silo C - Corn',
        isOn: true,
        status: 'active',
        lastAction: DateTime.now().subtract(const Duration(hours: 1)),
        lastActionBy: 'Auto',
      ),
    ];
  }
}
