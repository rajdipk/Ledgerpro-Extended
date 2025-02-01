import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  Future<Map<String, dynamic>> apiCall(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-admin-token': ApiConfig.adminToken,
    };

    try {
      debugPrint('Making API call to: $uri');
      debugPrint('Method: $method');
      debugPrint('Headers: $defaultHeaders');
      if (body != null) debugPrint('Body: $body');

      final response = await http.post(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check the URL and try again.');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (!responseData['success']) {
        throw Exception(responseData['error'] ?? 'Request failed');
      }

      return responseData;
    } catch (e) {
      debugPrint('API call failed: $e');
      rethrow;
    }
  }
}
