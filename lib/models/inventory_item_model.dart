class InventoryItem {
  final int? id;
  final int businessId;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final String unit;
  final double unitPrice;
  final double costPrice;
  final int currentStock;
  final int reorderLevel;
  final String createdAt;
  final String updatedAt;

  InventoryItem({
    this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category,
    required this.unit,
    required this.unitPrice,
    required this.costPrice,
    required this.currentStock,
    required this.reorderLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'current_stock': currentStock,
      'reorder_level': reorderLevel,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      businessId: map['business_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      unit: map['unit'] as String,
      unitPrice: map['unit_price'] as double,
      costPrice: map['cost_price'] as double,
      currentStock: map['current_stock'] as int,
      reorderLevel: map['reorder_level'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  InventoryItem copyWith({
    int? id,
    int? businessId,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? unitPrice,
    double? costPrice,
    int? currentStock,
    int? reorderLevel,
    String? createdAt,
    String? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
