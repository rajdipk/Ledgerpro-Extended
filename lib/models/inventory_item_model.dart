import 'package:ledgerpro/models/inventory_batch_model.dart';

class InventoryItem {
  final int? id;
  final int businessId;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final double weightedAverageCost;
  final int currentStock;
  final int reorderLevel;
  final String createdAt;
  final String updatedAt;
  final List<InventoryBatch> batches;

  InventoryItem({
    this.id,
    required this.businessId,
    required this.name,
    this.description = '',
    this.sku = '',
    this.barcode = '',
    this.category = '',
    required this.unit,
    required this.sellingPrice,
    required this.costPrice,
    this.weightedAverageCost = 0.0,
    required this.currentStock,
    required this.reorderLevel,
    required this.createdAt,
    required this.updatedAt,
    this.batches = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'business_id': businessId,
      'name': name,
      'description': description ?? '',
      'sku': sku ?? '',
      'barcode': barcode ?? '',
      'category': category ?? '',
      'unit': unit,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'weighted_average_cost': weightedAverageCost,
      'current_stock': currentStock,
      'reorder_level': reorderLevel,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, {List<InventoryBatch> batches = const []}) {
    return InventoryItem(
      id: map['id'] as int?,
      businessId: map['business_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      unit: map['unit'] as String,
      sellingPrice: (map['selling_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      weightedAverageCost: map['weighted_average_cost'] as double? ?? map['cost_price'] as double,
      currentStock: map['current_stock'] as int,
      reorderLevel: map['reorder_level'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      batches: batches,
    );
  }

  double calculateStockValue() {
    if (batches.isEmpty) {
      return currentStock * weightedAverageCost;
    }
    
    double totalValue = 0;
    for (var batch in batches) {
      totalValue += batch.quantity * batch.costPrice;
    }
    return totalValue;
  }

  double calculateWeightedAverageCost() {
    if (batches.isEmpty) {
      return costPrice;
    }
    
    double totalCost = 0;
    int totalQuantity = 0;
    for (var batch in batches) {
      totalCost += batch.costPrice * batch.quantity;
      totalQuantity += batch.quantity;
    }
    return totalQuantity > 0 ? totalCost / totalQuantity : costPrice;
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
    double? sellingPrice,
    double? costPrice,
    double? weightedAverageCost,
    int? currentStock,
    int? reorderLevel,
    String? createdAt,
    String? updatedAt,
    List<InventoryBatch>? batches,
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
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      weightedAverageCost: weightedAverageCost ?? this.weightedAverageCost,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      batches: batches ?? this.batches,
    );
  }
}
