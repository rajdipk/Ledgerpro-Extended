import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeService {
  static const String _baseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  /// Processes a barcode and returns a cleaned version
  /// This method handles different barcode formats and cleans the input
  String cleanBarcode(String barcode) {
    // Remove any whitespace and special characters
    return barcode.trim().replaceAll(RegExp(r'[^\w\d]'), '');
  }

  Future<String> processBarcode(String barcode) async {
    final cleanedCode = cleanBarcode(barcode);
    if (cleanedCode.isEmpty) {
      throw Exception('Invalid barcode format');
    }
    return cleanedCode;
  }

  Future<Map<String, dynamic>?> getProductInfo(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?upc=$barcode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items']?.isNotEmpty) {
          return {
            'title': data['items'][0]['title'],
            'description': data['items'][0]['description'],
            'brand': data['items'][0]['brand'],
            'category': data['items'][0]['category'],
            'images': data['items'][0]['images'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching product info: $e');
      return null;
    }
  }
}
