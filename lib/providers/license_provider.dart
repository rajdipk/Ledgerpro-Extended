// license_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/license_model.dart';
import '../services/license_service.dart';
import '../database/database_helper.dart';

class LicenseProvider with ChangeNotifier {
  License? _currentLicense;
  String? _error;

  String? get customerId => _currentLicense?.id?.toString();
  String? get customerEmail => _currentLicense?.customerEmail;
  License? get currentLicense => _currentLicense;
  String? get error => _error;
  bool get isLicensed => _currentLicense != null && !_currentLicense!.isExpired();

  Future<void> loadLicense() async {
    try {
      _currentLicense = await DatabaseHelper.instance.getCurrentLicense();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading license: $e');
      _error = 'Failed to load license';
      notifyListeners();
    }
  }

  Future<void> initializeLicense() async {
    try {
      await loadLicense();
      if (_currentLicense != null) {
        await LicenseService.instance.checkAndNotifyExpiry();
      }
    } catch (e) {
      debugPrint('Error initializing license: $e');
      _error = 'Failed to initialize license';
      notifyListeners();
    }
  }

  Future<bool> activateLicense(String licenseKey, String email, LicenseType type) async {
    try {
      _error = null; // Reset any previous errors
      
      // Validate inputs
      if (licenseKey.isEmpty || email.isEmpty) {
        _error = 'License key and email are required';
        notifyListeners();
        return false;
      }

      // Activate license using LicenseService
      final license = await LicenseService.instance.activateLicense(
        licenseKey.trim(),
        email.trim(),
        type,
      );

      if (license == null) {
        _error = 'Failed to activate license';
        notifyListeners();
        return false;
      }

      // Store the activated license
      _currentLicense = license;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('License activation error: $e');
      _error = 'Failed to activate license: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> deactivateLicense() async {
    try {
      await DatabaseHelper.instance.deleteLicense();
      _currentLicense = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deactivating license: $e');
      _error = 'Failed to deactivate license';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getLicenseStatus() async {
    try {
      return await LicenseService.instance.getLicenseStatus();
    } catch (e) {
      debugPrint('Error getting license status: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<bool> isFeatureAvailable(String featureName) async {
    if (_currentLicense == null) return false;
    if (_currentLicense!.isExpired()) return false;
    return _currentLicense!.hasFeature(featureName);
  }

  Future<bool> isWithinLimit(String limitName, int currentCount) async {
    if (_currentLicense == null) return false;
    if (_currentLicense!.isExpired()) return false;
    
    final limit = _currentLicense!.getFeatureLimit(limitName);
    if (limit == null || limit < 0) return true; // No limit or unlimited
    return currentCount < limit;
  }
}
