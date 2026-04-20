import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/silo_model.dart';
import '../utils/secure_storage.dart';

class SiloService {
  static Future<List<SiloModel>> getSilos() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(ApiConfig.silos),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Adjust parsing based on actual backend response structure
      // Assuming it returns { "silos": [...] } or just [...]
      final List<dynamic> list = data['silos'] ?? (data is List ? data : []);
      return list.map((json) => SiloModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load silos: ${response.statusCode}');
    }
  }
}
