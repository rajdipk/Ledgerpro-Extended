// transaction_model.dart

class Transaction {
  final int? id;
  final int? customerId;
  final int? supplierId;
  final double amount;
  final String date; // Consider changing this to DateTime
  late final double balance;

  Transaction({
    this.id,
    this.customerId,
    this.supplierId,
    required this.amount,
    required this.date,
    required this.balance,
  });

  // Converts the Transaction instance to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // Include id if it's not null
      if (customerId != null) 'customer_id': customerId, // Map customerId to customer_id
      if (supplierId != null) 'supplier_id': supplierId, // Map supplierId to supplier_id
      'amount': amount, // Map the amount
      'date': date, // Map the date (consider DateTime)
      'balance': balance, // Map the balance
    };
  }
}
