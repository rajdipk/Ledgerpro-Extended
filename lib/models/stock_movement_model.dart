class StockMovement {
  final int? id;
  final int businessId;
  final int itemId;
  final String movementType; // 'IN' or 'OUT'
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? referenceType; // e.g., 'PURCHASE_ORDER', 'SALE', 'ADJUSTMENT'
  final int? referenceId;
  final String? notes;
  final String date;

  StockMovement({
    this.id,
    required this.businessId,
    required this.itemId,
    required this.movementType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'item_id': itemId,
      'movement_type': movementType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'date': date,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      businessId: map['business_id'] as int,
      itemId: map['item_id'] as int,
      movementType: map['movement_type'] as String,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as double,
      totalPrice: map['total_price'] as double,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      notes: map['notes'] as String?,
      date: map['date'] as String,
    );
  }

  StockMovement copyWith({
    int? id,
    int? businessId,
    int? itemId,
    String? movementType,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? referenceType,
    int? referenceId,
    String? notes,
    String? date,
  }) {
    return StockMovement(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      itemId: itemId ?? this.itemId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}
