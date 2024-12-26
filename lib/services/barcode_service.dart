import 'dart:convert';
import 'package:flutter/material.dart';
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
    debugPrint('BarcodeService: Processing barcode: $barcode');
    final cleanedCode = cleanBarcode(barcode);
    debugPrint('BarcodeService: Cleaned barcode: $cleanedCode');
    
    if (cleanedCode.isEmpty) {
      debugPrint('BarcodeService: Error - Invalid barcode format');
      throw Exception('Invalid barcode format');
    }
    return cleanedCode;
  }

  Future<Map<String, dynamic>?> getProductInfo(String barcode) async {
    debugPrint('BarcodeService: Fetching product info for barcode: $barcode');
    try {
      final uri = Uri.parse('$_baseUrl?upc=$barcode');
      debugPrint('BarcodeService: Making API request to: $uri');
      
      final response = await http.get(uri);
      debugPrint('BarcodeService: API response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('BarcodeService: Successful API response');
        final data = json.decode(response.body);
        debugPrint('BarcodeService: Parsed response data: $data');
        
        if (data['items']?.isNotEmpty) {
          final productInfo = {
            'title': data['items'][0]['title'],
            'description': data['items'][0]['description'],
            'brand': data['items'][0]['brand'],
            'category': data['items'][0]['category'],
            'images': data['items'][0]['images'],
          };
          debugPrint('BarcodeService: Extracted product info: $productInfo');
          return productInfo;
        } else {
          debugPrint('BarcodeService: No items found in API response');
        }
      } else {
        debugPrint('BarcodeService: API request failed with status: ${response.statusCode}');
        debugPrint('BarcodeService: Response body: ${response.body}');
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('BarcodeService: Error fetching product info: $e');
      debugPrint('BarcodeService: Stack trace: $stackTrace');
      return null;
    }
  }
}
