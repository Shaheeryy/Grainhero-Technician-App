import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sensor_model.dart';
import '../utils/secure_storage.dart';

class SensorService {
  /// Get all sensors with pagination and filters.
  Future<Map<String, dynamic>> getAllSensors({
    int page = 1,
    int limit = 20,
    String? status,
    String? siloId,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (siloId != null) queryParams['silo_id'] = siloId;

    final uri = Uri.parse(ApiConfig.sensors).replace(queryParameters: queryParams);

    final response = await http
        .get(uri, headers: ApiConfig.getHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'sensors': (data['sensors'] as List<dynamic>?)
                ?.map((e) => SensorDevice.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        'pagination': data['pagination'] ?? {},
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load sensors');
    }
  }

  /// Fetch sensor details by ID (includes recent_readings).
  Future<SensorDevice> fetchSensorDetails(String sensorId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          Uri.parse(ApiConfig.sensorDetails(sensorId)),
          headers: ApiConfig.getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend may return { sensor: {...} } or just {...}
      final sensorJson = data['sensor'] ?? data['data'] ?? data;
      return SensorDevice.fromJson(sensorJson as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Sensor not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load sensor details');
    }
  }

  /// Get sensor readings (time-series).
  Future<Map<String, dynamic>> getSensorReadings(
    String sensorId, {
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{'limit': limit.toString()};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse(
      ApiConfig.sensorReadings(sensorId),
    ).replace(queryParameters: queryParams);

    final response = await http
        .get(uri, headers: ApiConfig.getHeaders(token: token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Parse readings into SensorReading objects
      final rawReadings = data['readings'] as List<dynamic>? ?? [];
      final readings = rawReadings
          .where((r) => r is Map)
          .map((r) => SensorReading.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      return {
        'readings': readings,
        'total_readings': data['total_readings'] ?? readings.length,
        'date_range': data['date_range'],
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 404) {
      throw Exception('Sensor not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load sensor readings');
    }
  }

  /// Calibrate sensor.
  Future<bool> calibrateSensor(String sensorId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.sensorCalibrate(sensorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({'timestamp': DateTime.now().toIso8601String()}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to calibrate sensor');
    }
  }

  /// Log sensor maintenance.
  Future<bool> logSensorMaintenance(String sensorId, String notes) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .post(
          Uri.parse(ApiConfig.sensorMaintenance(sensorId)),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({'notes': notes}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to log sensor maintenance');
    }
  }

  /// Fetch dashboard data.
  Future<Map<String, dynamic>> fetchDashboard() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          Uri.parse(ApiConfig.technicianDashboard),
          headers: ApiConfig.getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load dashboard');
    }
  }
}
