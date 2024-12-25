//customer_model.dart
import 'transaction_model.dart';
import 'package:intl/intl.dart';

class Customer {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String pan;
  final String gstin;
  double balance;
  DateTime? lastTransactionDate;
  List<Transaction>? transactions;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.pan = '',
    this.gstin = '',
    this.balance = 0,
    this.lastTransactionDate,
    this.transactions, required int businessId,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      pan: map['pan'] ?? '',
      gstin: map['gstin'] ?? '',
      balance: map['balance']?.toDouble() ?? 0.0,
      lastTransactionDate: map['lastTransactionDate'] != null
          ? DateTime.parse(map['lastTransactionDate'])
          : null,
      businessId: map['business_id'] as int,
    );
  }

  // Convert a Customer object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'pan': pan,
      'gstin': gstin,
      'balance': balance,
      'lastTransactionDate': lastTransactionDate?.toIso8601String(),
    };
  }

  // Method to assign transactions to the customer
  void setTransactions(List<Transaction> transactions) {
    this.transactions = transactions;
  }

  String get lastTransactionDateFormatted => lastTransactionDate != null 
      ? DateFormat('dd MMM yyyy').format(lastTransactionDate!)
      : 'No transactions';
}
