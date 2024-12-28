// license_model.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

enum LicenseType {
  demo,
  professional,
  enterprise,
}

class License {
  final String licenseKey;
  final LicenseType licenseType;
  final DateTime activationDate;
  final DateTime? expiryDate;
  final Map<String, dynamic> features;
  final String? customerEmail;
  final int? id;

  License({
    required this.licenseKey,
    required this.licenseType,
    required this.activationDate,
    this.expiryDate,
    required this.features,
    this.customerEmail,
    this.id,
  });

  bool isExpired() {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool hasFeature(String featureName) {
    return features.containsKey(featureName) && features[featureName] == true;
  }

  int? getFeatureLimit(String limitName) {
    return features[limitName] as int?;
  }

  static Map<String, dynamic> getDefaultFeatures(LicenseType type) {
    switch (type) {
      case LicenseType.demo:
        return {
          'expiry_days': 30,
          'customer_limit': 10,
          'inventory_limit': 50,
          'invoice_limit': 20,
          'monthly_transaction_limit': 100,
          'basic_inventory': true,
          'basic_customers': true,
          'basic_invoicing': true,
          'pdf_export': false,
          'barcode_scanning': false,
          'purchase_orders': false,
          'inventory_movements': false,
          'advanced_reports': false,
          'custom_branding': false,
          'api_access': false,
          'multi_business': false,
        };
      
      case LicenseType.professional:
        return {
          'expiry_days': 30,
          'customer_limit': 1000,
          'inventory_limit': 5000,
          'invoice_limit': 1000,
          'monthly_transaction_limit': 10000,
          'basic_inventory': true,
          'basic_customers': true,
          'basic_invoicing': true,
          'advanced_inventory': true,
          'advanced_customers': true,
          'advanced_invoicing': true,
          'pdf_export': true,
          'barcode_scanning': true,
          'purchase_orders': true,
          'inventory_movements': true,
          'basic_reports': true,
          'custom_branding': false,
          'api_access': false,
          'multi_business': false,
        };
      
      case LicenseType.enterprise:
        return {
          'expiry_days': 365,
          'customer_limit': -1, // unlimited
          'inventory_limit': -1, // unlimited
          'invoice_limit': -1, // unlimited
          'monthly_transaction_limit': -1, // unlimited
          'basic_inventory': true,
          'basic_customers': true,
          'basic_invoicing': true,
          'advanced_inventory': true,
          'advanced_customers': true,
          'advanced_invoicing': true,
          'pdf_export': true,
          'barcode_scanning': true,
          'purchase_orders': true,
          'inventory_movements': true,
          'advanced_reports': true,
          'custom_branding': true,
          'api_access': true,
          'multi_business': true,
        };
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_key': licenseKey,
      'license_type': licenseType.toString(),
      'activation_date': activationDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'features': features,
      'customer_email': customerEmail,
    };
  }

  factory License.fromMap(Map<String, dynamic> map) {
    return License(
      id: map['id'] as int?,
      licenseKey: map['license_key'] as String,
      licenseType: LicenseType.values.firstWhere(
        (t) => t.toString() == map['license_type'],
      ),
      activationDate: DateTime.parse(map['activation_date'] as String),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      features: Map<String, dynamic>.from(map['features'] as Map),
      customerEmail: map['customer_email'] as String?,
    );
  }
}
