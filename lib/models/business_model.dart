// business_model.dart
import 'dart:convert';

class Business {
  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;
  final String? pan;
  final String? businessType;
  final String createdAt;
  final String updatedAt;
  final String? logo;
  final String? defaultCurrency;
  final Map<String, dynamic>? settings;

  Business({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gstin = '',
    this.pan = '',
    this.businessType = '',
    String? createdAt,
    String? updatedAt,
    this.logo = '',
    this.defaultCurrency = 'INR',
    this.settings,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'pan': pan,
      'business_type': businessType,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'logo': logo,
      'default_currency': defaultCurrency,
      'settings': settings != null ? json.encode(settings) : null,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id']?.toString(),
      name: map['name'],
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      pan: map['pan'] ?? '',
      businessType: map['business_type'] ?? '',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      logo: map['logo'] ?? '',
      defaultCurrency: map['default_currency'] ?? 'INR',
      settings: map['settings'] != null ? json.decode(map['settings']) : null,
    );
  }
}
