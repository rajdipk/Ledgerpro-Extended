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
      debugPrint('Headers: ${defaultHeaders..addAll(headers ?? {})}');
      if (body != null) debugPrint('Body: $body');

      http.Response response;
      switch (method) {
        case 'POST':
          response = await http.post(
            uri,
            headers: {...defaultHeaders, ...?headers},
            body: body != null ? json.encode(body) : null,
          );
          break;
        default:
          response = await http.get(
            uri,
            headers: {...defaultHeaders, ...?headers},
          );
      }

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 404) {
        throw Exception('Endpoint not found: $endpoint');
      }

      // Try to parse the response body
      final Map<String, dynamic> responseData = 
          json.decode(response.body) as Map<String, dynamic>;

      if (responseData['success'] == null) {
        throw Exception('Invalid response format');
      }

      if (!responseData['success']) {
        throw Exception(responseData['error'] ?? 'Request failed');
      }

      return responseData;
    } catch (e) {
      debugPrint('API call error: $e');
      rethrow;
    }
  }
}
