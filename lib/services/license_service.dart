// license_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';  // Add this import for debugPrint
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http; // Add this import for http
import '../database/database_helper.dart';
import '../models/license_model.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import '../services/api_service.dart'; // Add this import

class LicenseService {
  static final LicenseService instance = LicenseService._();
  final ApiService _apiService = ApiService.instance; // Add this field
  
  LicenseService._();

  // Generate a license key
  String generateLicenseKey(String email, LicenseType type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$email-$type-$timestamp';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    
    // Take first 16 characters of hash and format as XXXX-XXXX-XXXX-XXXX
    final key = hash.toString().substring(0, 16).toUpperCase();
    return '${key.substring(0, 4)}-${key.substring(4, 8)}-'
           '${key.substring(8, 12)}-${key.substring(12, 16)}';
  }

  // Validate a license key format
  bool isValidKeyFormat(String key) {
    // Check if key starts with valid prefix
    if (!key.startsWith('DEMO-') && !key.startsWith('PRO-') && !key.startsWith('ENT-')) {
      return false;
    }
    
    // Check if rest of the key matches format: XXXX-XXXX-XXXX where X is a number
    final parts = key.split('-');
    if (parts.length != 4) return false;
    
    // Skip first part (type), check remaining parts
    for (var i = 1; i < parts.length; i++) {
      if (!RegExp(r'^[0-9]{4}$').hasMatch(parts[i])) {
        return false;
      }
    }
    
    return true;
  }

  // Activate a new license
  Future<License?> activateLicense(String licenseKey, String email, LicenseType type) async {
    try {
      if (!isValidKeyFormat(licenseKey)) {
        throw Exception('Invalid license key format');
      }

      // Extract the license type from the key
      final keyPrefix = licenseKey.split('-')[0];
      final keyType = switch (keyPrefix) {
        'DEMO' => LicenseType.demo,
        'PRO' => LicenseType.professional,
        'ENT' => LicenseType.enterprise,
        _ => throw Exception('Invalid license key prefix'),
      };

      // Compare the key type with the selected type
      if (keyType != type) {
        throw Exception('License key prefix ($keyPrefix) does not match selected plan (${type.toString().split('.').last})');
      }

      final features = License.getDefaultFeatures(type);
      final activationDate = DateTime.now();
      
      // Calculate expiry date based on license type
      final expiryDays = features['expiry_days'] as int? ?? 30; // Default to 30 days
      final expiryDate = activationDate.add(Duration(days: expiryDays));

      final license = License(
        licenseKey: licenseKey,
        licenseType: type,
        activationDate: activationDate,
        expiryDate: expiryDate,
        features: features,
        customerEmail: email,
      );

      await DatabaseHelper.instance.saveLicense(license);
      return license;
    } catch (e) {
      debugPrint('License activation error: $e');
      rethrow; // Rethrow to let the provider handle the error
    }
  }

  // Check if a feature is available
  Future<bool> isFeatureAvailable(String featureName) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return false;
    
    if (license.isExpired()) return false;
    return license.hasFeature(featureName);
  }

  // Check if within limits (for customers, transactions, etc.)
  Future<bool> isWithinLimit(String limitName, int currentCount) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return false;
    
    if (license.isExpired()) return false;
    
    final limit = license.getFeatureLimit(limitName);
    if (limit == null || limit < 0) return true; // No limit or unlimited
    return currentCount < limit;
  }

  // Get current license status
  Future<Map<String, dynamic>> getLicenseStatus() async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) {
      return {
        'status': 'inactive',
        'type': null,
        'expiry': null,
        'features': {},
      };
    }

    return {
      'status': license.isExpired() ? 'expired' : 'active',
      'type': license.licenseType.toString().split('.').last,
      'expiry': license.expiryDate?.toIso8601String(),
      'features': license.features,
    };
  }

  // Deactivate current license
  Future<void> deactivateLicense() async {
    await DatabaseHelper.instance.deleteLicense();
  }

  // Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return;

    await DatabaseHelper.instance.incrementUsageCount(
      license.id!,
      featureName,
    );
  }

  // Track transaction
  Future<void> trackTransaction(String transactionType) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return;

    // Track for current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    await DatabaseHelper.instance.incrementTransactionCount(
      license.id!,
      transactionType,
      startOfMonth,
      endOfMonth,
    );
  }

  // Get transaction count for current period
  Future<int> getTransactionCount(String transactionType) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await DatabaseHelper.instance.getTransactionCount(
      license.id!,
      transactionType,
      startOfMonth,
      endOfMonth,
    );
  }

  // Check if transaction limit is reached
  Future<bool> canMakeTransaction(String transactionType) async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null) return false;

    if (license.isExpired()) return false;

    final currentCount = await getTransactionCount(transactionType);
    final limit = license.getFeatureLimit('${transactionType}_limit');
    
    if (limit == null || limit < 0) return true; // No limit or unlimited
    return currentCount < limit;
  }

  // Send license expiry notification
  Future<void> checkAndNotifyExpiry() async {
    final license = await DatabaseHelper.instance.getCurrentLicense();
    if (license == null || license.expiryDate == null) return;

    final daysUntilExpiry = license.expiryDate!.difference(DateTime.now()).inDays;

    if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
      await NotificationService.instance.showLicenseExpiryNotification(
        licenseId: license.id!,
        title: 'License Expiring Soon',
        body: 'Your license will expire in $daysUntilExpiry days. Please renew to continue using all features.',
      );
    } else if (daysUntilExpiry <= 0) {
      await NotificationService.instance.showLicenseExpiryNotification(
        licenseId: license.id!,
        title: 'License Expired',
        body: 'Your license has expired. Please renew now to continue using all features.',
      );
    }
  }

  Future<void> scheduleExpiryNotifications(License license) async {
    if (license.expiryDate == null) return;

    // Cancel any existing notifications first
    await NotificationService.instance.cancelLicenseNotifications(license.id!);

    // Schedule new notifications
    await NotificationService.instance.scheduleLicenseExpiryNotification(
      licenseId: license.id!,
      expiryDate: license.expiryDate!,
    );
  }

  Future<bool> verifyLicenseWithServer(String licenseKey, String email) async {
    try {
        debugPrint('Verifying license with server - Key: $licenseKey, Email: $email');
        
        final response = await _apiService.apiCall(
            '/api/customers/verify-license',  // Changed from /api/admin/verify-license
            method: 'POST',
            body: {
                'licenseKey': licenseKey,
                'email': email,
            },
        );

        debugPrint('License verification response: $response');

        if (!response['success']) {
            throw Exception(response['error'] ?? 'License verification failed');
        }

        // Store verified license data if successful
        if (response['data']?.containsKey('license')) {
            await DatabaseHelper.instance.saveLicense(
                License.fromMap(response['data']['license'])
            );
        }

        return true;
    } catch (e) {
        debugPrint('License verification error: $e');
        return false;
    }
  }

  LicenseType _getLicenseTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'demo':
        return LicenseType.demo;
      case 'professional':
        return LicenseType.professional;
      case 'enterprise':
        return LicenseType.enterprise;
      default:
        throw Exception('Invalid license type: $type');
    }
  }
}
