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
      if (lastTransactionDate != null)
        'lastTransactionDate': lastTransactionDate!.toIso8601String(),
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && 
           other.id == id &&
           other.businessId == businessId &&
           other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, businessId, name);

  Supplier copyWith({
    int? id,
    int? businessId,
    String? name,
    String? phone,
    String? address,
    String? pan,
    String? gstin,
    double? balance,
    DateTime? lastTransactionDate,
    List<Transaction>? transactions,
  }) {
    return Supplier(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      pan: pan ?? this.pan,
      gstin: gstin ?? this.gstin,
      balance: balance ?? this.balance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      transactions: transactions ?? this.transactions,
    );
  }
}
