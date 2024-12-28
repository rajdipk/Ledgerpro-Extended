// license_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/license_model.dart';
import '../services/license_service.dart';
import '../services/storage_service.dart';

class LicenseProvider with ChangeNotifier {
  License? _currentLicense;
  bool _isLoading = false;
  String? _error;
  String? _licenseKey;
  LicenseType _licenseType = LicenseType.demo;
  String? _customerId;
  String? _customerEmail;
  DateTime? _expiryDate;
  bool _isActive = false;

  License? get currentLicense => _currentLicense;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get licenseKey => _licenseKey;
  LicenseType get licenseType => _licenseType;
  String? get customerId => _customerId;
  String? get customerEmail => _customerEmail;
  DateTime? get expiryDate => _expiryDate;
  bool get isActive => _isActive;
  
  // Initialize license state
  Future<void> initializeLicense() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await LicenseService.instance.getLicenseStatus();
      if (status['status'] == 'active') {
        // Load current license
        _currentLicense = await LicenseService.instance
            .activateLicense(
              status['license_key'], 
              '', // Email not needed for existing license
              LicenseType.values.firstWhere(
                (e) => e.toString().split('.').last == status['type']
              )
            );
      }
    } catch (e) {
      _error = 'Failed to initialize license: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activate a new license
  Future<bool> activateLicense(String licenseKey, String email, LicenseType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final license = await LicenseService.instance
          .activateLicense(licenseKey, email, type);
      
      if (license != null) {
        _currentLicense = license;
        _licenseKey = licenseKey;
        _licenseType = type;
        _customerEmail = email;
        _customerId = await StorageService.instance.getValue('customerId');
        _isActive = true;
        _expiryDate = license.expiryDate;
        
        // Save to storage
        await StorageService.instance.saveValue('licenseKey', licenseKey);
        await StorageService.instance.saveValue('licenseType', type.toString());
        await StorageService.instance.saveValue('customerEmail', email);
        if (_expiryDate != null) {
          await StorageService.instance.saveValue('expiryDate', _expiryDate!.toIso8601String());
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to activate license: Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if a feature is available
  Future<bool> isFeatureAvailable(String featureName) async {
    try {
      return await LicenseService.instance.isFeatureAvailable(featureName);
    } catch (e) {
      _error = 'Failed to check feature availability: $e';
      return false;
    }
  }

  // Check if within limits
  Future<bool> isWithinLimit(String limitName, int currentCount) async {
    try {
      return await LicenseService.instance.isWithinLimit(limitName, currentCount);
    } catch (e) {
      _error = 'Failed to check limit: $e';
      return false;
    }
  }

  // Get current license status
  Future<Map<String, dynamic>> getLicenseStatus() async {
    try {
      return await LicenseService.instance.getLicenseStatus();
    } catch (e) {
      _error = 'Failed to get license status: $e';
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Deactivate current license
  Future<void> deactivateLicense() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await LicenseService.instance.deactivateLicense();
      _currentLicense = null;
      _licenseKey = null;
      _licenseType = LicenseType.demo;
      _customerEmail = null;
      _isActive = false;
      _expiryDate = null;
      
      // Clear from storage
      await StorageService.instance.removeValue('licenseKey');
      await StorageService.instance.removeValue('licenseType');
      await StorageService.instance.removeValue('customerEmail');
      await StorageService.instance.removeValue('expiryDate');
    } catch (e) {
      _error = 'Failed to deactivate license: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadLicenseData() async {
    _licenseKey = await StorageService.instance.getValue('licenseKey');
    final typeStr = await StorageService.instance.getValue('licenseType');
    _customerEmail = await StorageService.instance.getValue('customerEmail');
    _customerId = await StorageService.instance.getValue('customerId');
    final expiryStr = await StorageService.instance.getValue('expiryDate');
    
    if (typeStr != null) {
      _licenseType = LicenseType.values.firstWhere(
        (t) => t.toString() == typeStr,
        orElse: () => LicenseType.demo,
      );
    }
    
    if (expiryStr != null) {
      _expiryDate = DateTime.parse(expiryStr);
      _isActive = _expiryDate!.isAfter(DateTime.now());
    }
    
    notifyListeners();
  }
}
