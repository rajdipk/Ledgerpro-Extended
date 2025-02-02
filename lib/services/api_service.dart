import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  final String baseUrl = 'https://ledgerpro-extended.onrender.com';

  ApiService._();

  Future<Map<String, dynamic>> apiCall(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('Making API call to: $uri');
      debugPrint('Method: $method');
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
        body: body != null ? json.encode(body) : null,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check the URL and try again.');
      }

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Server error: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      debugPrint('API call failed: $e');
      rethrow;
    }
  }
}
