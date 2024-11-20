// supplier_model.dart
import 'transaction_model.dart';
import 'package:intl/intl.dart';

class Supplier {
  final int id;
  final int businessId;
  final String name;
  final String phone;
  final String address;
  final String pan;
  final String gstin;
  double balance;
  DateTime? lastTransactionDate;
  List<Transaction>? transactions;

  Supplier({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone = '',
    this.address = '',
    this.pan = '',
    this.gstin = '',
    this.balance = 0,
    this.lastTransactionDate,
    this.transactions,
  });

  String get lastTransactionDateFormatted => lastTransactionDate != null 
      ? DateFormat('dd MMM yyyy').format(lastTransactionDate!)
      : 'No transactions';

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int? ?? 0,
      businessId: map['business_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      pan: map['pan'] as String? ?? '',
      gstin: map['gstin'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastTransactionDate: map['lastTransactionDate'] != null
          ? DateTime.parse(map['lastTransactionDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'address': address,
      'pan': pan,
      'gstin': gstin,
      'balance': balance,
    };
    
    // Only include id if it's not 0 (for updates)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }
}
