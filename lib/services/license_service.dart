// license_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http; // Add this import for http
import '../database/database_helper.dart';
import '../models/license_model.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'storage_service.dart'; // Add this import

class LicenseService {
  static final LicenseService instance = LicenseService._();
  late final ApiService _apiService;

  LicenseService._() {
    _apiService = ApiService.instance;
  }

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
    if (!key.startsWith('DEMO-') &&
        !key.startsWith('PRO-') &&
        !key.startsWith('ENT-')) {
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
  Future<License?> activateLicense(dynamic input) async {
    try {
      License license;

      if (input is License) {
        license = input;
      } else if (input is Map<String, dynamic>) {
        final licenseKey = input['licenseKey'] as String;
        final email = input['email'] as String;
        final type = input['type'] as LicenseType;

        if (!isValidKeyFormat(licenseKey)) {
          throw Exception('Invalid license key format');
        }

        final keyPrefix = licenseKey.split('-')[0];
        final keyType = switch (keyPrefix) {
          'DEMO' => LicenseType.demo,
          'PRO' => LicenseType.professional,
          'ENT' => LicenseType.enterprise,
          _ => throw Exception('Invalid license key prefix'),
        };

        if (keyType != type) {
          throw Exception(
              'License key prefix ($keyPrefix) does not match selected plan (${type.toString().split('.').last})');
        }

        final features = License.getDefaultFeatures(type);
        final activationDate = DateTime.now();
        final expiryDays = features['expiry_days'] as int? ?? 30;
        final expiryDate = activationDate.add(Duration(days: expiryDays));

        license = License(
          licenseKey: licenseKey,
          licenseType: type,
          activationDate: activationDate,
          expiryDate: expiryDate,
          features: features,
          customerEmail: email,
        );
      } else {
        throw Exception('Invalid input type for license activation');
      }

      debugPrint('Saving license to database: ${license.toMap()}');

      // Save to database and get the ID
      final id = await DatabaseHelper.instance.saveLicense(license);

      // Create a new license object with the ID
      final savedLicense = License(
        id: id,
        licenseKey: license.licenseKey,
        licenseType: license.licenseType,
        activationDate: license.activationDate,
        expiryDate: license.expiryDate,
        features: license.features,
        customerEmail: license.customerEmail,
      );

      // Try to schedule notifications, but don't let it block license activation
      if (savedLicense.expiryDate != null) {
        try {
          await scheduleExpiryNotifications(savedLicense);
        } catch (e) {
          debugPrint('Warning: Could not schedule notifications: $e');
          // Continue with license activation even if notifications fail
        }
      }

      debugPrint('License activated successfully: ${savedLicense.toMap()}');
      return savedLicense;
    } catch (e) {
      debugPrint('License activation error: $e');
      rethrow;
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
    try {
      final license = await DatabaseHelper.instance.getCurrentLicense();
      if (license != null) {
        // Cancel any scheduled notifications
        await NotificationService.instance
            .cancelLicenseNotifications(license.id!);
      }

      // Clear license from database
      await DatabaseHelper.instance.deleteLicense();

      // Clear any cached data or states
      await StorageService.instance.removeValue('last_validation');
      await StorageService.instance.removeValue('offline_grace_start');

      debugPrint('License deactivated successfully');
    } catch (e) {
      debugPrint('Error deactivating license: $e');
      rethrow;
    }
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

    final daysUntilExpiry =
        license.expiryDate!.difference(DateTime.now()).inDays;

    if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
      await NotificationService.instance.showLicenseExpiryNotification(
        licenseId: license.id!,
        title: 'License Expiring Soon',
        body:
            'Your license will expire in $daysUntilExpiry days. Please renew to continue using all features.',
      );
    } else if (daysUntilExpiry <= 0) {
      await NotificationService.instance.showLicenseExpiryNotification(
        licenseId: license.id!,
        title: 'License Expired',
        body:
            'Your license has expired. Please renew now to continue using all features.',
      );
    }
  }

  Future<void> scheduleExpiryNotifications(License license) async {
    if (license.expiryDate == null || license.id == null) {
      debugPrint('Cannot schedule notifications: license ID or expiry date is null');
      return;
    }

    try {
      // Initialize notification service
      final notificationService = NotificationService.instance;
      final initialized = await notificationService.initialize();
      
      if (!initialized) {
        debugPrint('Failed to initialize notification service');
        return;
      }

      // Cancel any existing notifications first
      await notificationService.cancelLicenseNotifications(license.id!);

      // Schedule new notifications
      final scheduled = await notificationService.scheduleLicenseExpiryNotification(
        licenseId: license.id!,
        expiryDate: license.expiryDate!,
      );

      if (scheduled) {
        debugPrint('Successfully scheduled license expiry notifications');
      } else {
        debugPrint('Failed to schedule license expiry notifications');
      }
    } catch (e) {
      debugPrint('Error scheduling license expiry notifications: $e');
      // Don't rethrow - we want to continue with license activation even if notifications fail
    }
  }

  Future<bool> verifyLicenseWithServer(String licenseKey, String email) async {
    try {
      debugPrint(
          'Verifying license with server - Key: $licenseKey, Email: $email');

      final response = await _apiService.apiCall(
        '/api/customers/verify-license', // Changed from /api/admin/verify-license
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
        await DatabaseHelper.instance
            .saveLicense(License.fromMap(response['data']['license']));
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
