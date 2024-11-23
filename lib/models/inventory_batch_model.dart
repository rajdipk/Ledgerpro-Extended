class InventoryBatch {
  final int? id;
  final int itemId;
  final int quantity;
  final double costPrice;
  final String purchaseDate;
  final String? referenceType;
  final int? referenceId;

  InventoryBatch({
    this.id,
    required this.itemId,
    required this.quantity,
    required this.costPrice,
    required this.purchaseDate,
    this.referenceType,
    this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'quantity': quantity,
      'cost_price': costPrice,
      'purchase_date': purchaseDate,
      'reference_type': referenceType,
      'reference_id': referenceId,
    };
  }

  factory InventoryBatch.fromMap(Map<String, dynamic> map) {
    return InventoryBatch(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      quantity: map['quantity'] as int,
      costPrice: map['cost_price'] as double,
      purchaseDate: map['purchase_date'] as String,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
    );
  }
}
