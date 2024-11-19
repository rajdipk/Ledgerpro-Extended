class PurchaseOrder {
  final int? id;
  final int businessId;
  final int supplierId;
  final String orderNumber;
  final String status; // 'DRAFT', 'ORDERED', 'RECEIVED', 'CANCELLED'
  final double totalAmount;
  final String? notes;
  final String orderDate;
  final String? expectedDate;
  final String? receivedDate;
  final String createdAt;
  final String updatedAt;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    this.id,
    required this.businessId,
    required this.supplierId,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.notes,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'supplier_id': supplierId,
      'order_number': orderNumber,
      'status': status,
      'total_amount': totalAmount,
      'notes': notes,
      'order_date': orderDate,
      'expected_date': expectedDate,
      'received_date': receivedDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map, List<PurchaseOrderItem> items) {
    return PurchaseOrder(
      id: map['id'] as int?,
      businessId: map['business_id'] as int,
      supplierId: map['supplier_id'] as int,
      orderNumber: map['order_number'] as String,
      status: map['status'] as String,
      totalAmount: map['total_amount'] as double,
      notes: map['notes'] as String?,
      orderDate: map['order_date'] as String,
      expectedDate: map['expected_date'] as String?,
      receivedDate: map['received_date'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      items: items,
    );
  }

  PurchaseOrder copyWith({
    int? id,
    int? businessId,
    int? supplierId,
    String? orderNumber,
    String? status,
    double? totalAmount,
    String? notes,
    String? orderDate,
    String? expectedDate,
    String? receivedDate,
    String? createdAt,
    String? updatedAt,
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      supplierId: supplierId ?? this.supplierId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      expectedDate: expectedDate ?? this.expectedDate,
      receivedDate: receivedDate ?? this.receivedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

class PurchaseOrderItem {
  final int? id;
  final int purchaseOrderId;
  final int itemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int receivedQuantity;

  PurchaseOrderItem({
    this.id,
    required this.purchaseOrderId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.receivedQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'received_quantity': receivedQuantity,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'] as int?,
      purchaseOrderId: map['purchase_order_id'] as int,
      itemId: map['item_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as double,
      totalPrice: map['total_price'] as double,
      receivedQuantity: map['received_quantity'] as int,
    );
  }

  PurchaseOrderItem copyWith({
    int? id,
    int? purchaseOrderId,
    int? itemId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    int? receivedQuantity,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    );
  }
}
