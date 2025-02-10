// transaction_model.dart

class Transaction {
  final int? id;
  final int? businessId;
  final int? customerId;
  final int? supplierId;
  final double amount;
  final String date; // Consider changing this to DateTime
  late final double balance;
  final String? notes;
  final String? referenceType;
  final int? referenceId;

  Transaction({
    this.id,
    this.businessId,
    this.customerId,
    this.supplierId,
    required this.amount,
    required this.date,
    required this.balance,
    this.notes,
    this.referenceType,
    this.referenceId,
  });

  // Converts the Transaction instance to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // Include id if it's not null
      if (businessId != null) 'business_id': businessId, // Include business_id
      if (customerId != null)
        'customer_id': customerId, // Map customerId to customer_id
      if (supplierId != null)
        'supplier_id': supplierId, // Map supplierId to supplier_id
      'amount': amount, // Map the amount
      'date': date, // Map the date (consider DateTime)
      'balance': balance, // Map the balance
      if (notes != null) 'notes': notes,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
    };
  }
}
