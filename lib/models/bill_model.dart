import 'package:flutter/material.dart';
import 'customer_model.dart';
import 'inventory_item_model.dart';
import 'business_model.dart';

@immutable
class Bill {
  final String? id;
  final int businessId;
  final Business? business;
  final Customer customer;
  final List<BillItem> items;
  final double subTotal;
  final double gstAmount;
  final double discount;
  final double deliveryCharge;
  final double total;
  final String status; // 'pending', 'paid', 'cancelled'
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? notes;

  const Bill({
    this.id,
    required this.businessId,
    this.business,
    required this.customer,
    required this.items,
    required this.subTotal,
    required this.gstAmount,
    this.discount = 0,
    this.deliveryCharge = 0,
    required this.total,
    this.status = 'pending',
    required this.createdAt,
    this.paidAt,
    this.notes,
  });

  factory Bill.create({
    required int businessId,
    required Customer customer,
    required List<BillItem> items,
    double discount = 0,
    double deliveryCharge = 0,
    String? notes,
  }) {
    final subTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final gstAmount = items.fold<double>(
      0,
      (sum, item) => sum + (item.total * item.gstRate / 100),
    );

    return Bill(
      businessId: businessId,
      customer: customer,
      items: items,
      subTotal: subTotal,
      gstAmount: gstAmount,
      discount: discount,
      deliveryCharge: deliveryCharge,
      total: subTotal + gstAmount + deliveryCharge - discount,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    debugPrint('Bill - Converting to map');
    final map = {
      'business_id': businessId,
      'customer_id': customer.id,
      'sub_total': subTotal,
      'gst_amount': gstAmount,
      'discount': discount,
      'delivery_charge': deliveryCharge,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
    debugPrint('Bill - Map created: $map');
    return map;
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    debugPrint('Bill.fromMap - Converting map to Bill: $map');
    try {
      // Process bill items
      List<BillItem> billItems = [];
      if (map['items'] != null) {
        billItems = (map['items'] as List).map((itemData) {
          final itemMap = itemData['item'] as Map<String, dynamic>;
          final inventoryItem = InventoryItem(
            id: itemMap['id'] as int,
            businessId: itemMap['business_id'] as int,
            name: itemMap['name'] as String,
            description: itemMap['description'] as String?,
            currentStock: itemMap['current_stock'] as int,
            unit: itemMap['unit'] as String,
            sellingPrice: (itemMap['selling_price'] as num).toDouble(),
            costPrice: 0.0, // Default value since it's not needed for bills
            reorderLevel: 0, // Default value since it's not needed for bills
            createdAt:
                DateTime.now().toIso8601String(), // Default since not needed
            updatedAt:
                DateTime.now().toIso8601String(), // Default since not needed
          );

          return BillItem(
            item: inventoryItem,
            quantity: itemData['quantity'] as int,
            price: (itemData['price'] as num).toDouble(),
            gstRate: (itemData['gst_rate'] as num).toDouble(),
            notes: itemData['notes'] as String?,
          );
        }).toList();
      }

      // Process customer data
      final customerMap = map['customer'] as Map<String, dynamic>;
      final customer = Customer(
        id: customerMap['id'] as int? ?? 0,
        businessId:
            customerMap['business_id'] as int? ?? map['business_id'] as int,
        name: customerMap['name'] as String? ?? 'Unknown Customer',
        phone: customerMap['phone'] as String? ?? '',
        address: customerMap['address'] as String? ?? '',
        pan: customerMap['pan'] as String? ?? '',
        gstin: customerMap['gstin'] as String? ?? '',
        balance: (customerMap['balance'] as num?)?.toDouble() ?? 0.0,
      );

      // Process business data
      Business? business;
      if (map['business'] != null) {
        final businessMap = map['business'] as Map<String, dynamic>;
        business = Business(
          id: businessMap['id']?.toString() ?? '', // Convert int to String
          name: businessMap['name'] as String? ?? '',
          address: businessMap['address'] as String? ?? '',
          phone: businessMap['phone'] as String? ?? '',
          email: businessMap['email'] as String? ?? '',
          gstin: businessMap['gstin'] as String? ?? '',
          pan: businessMap['pan'] as String? ?? '',
        );
      }

      final bill = Bill(
        id: map['id']?.toString(),
        businessId: map['business_id'] as int? ?? 0,
        customer: customer,
        business: business,
        items: billItems,
        subTotal: (map['sub_total'] as num?)?.toDouble() ?? 0.0,
        gstAmount: (map['gst_amount'] as num?)?.toDouble() ?? 0.0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
        deliveryCharge: (map['delivery_charge'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        paidAt: map['paid_at'] != null
            ? DateTime.parse(map['paid_at'] as String)
            : null,
        notes: map['notes'] as String?,
      );
      debugPrint('Bill.fromMap - Successfully converted to Bill object');
      return bill;
    } catch (e, stackTrace) {
      debugPrint('Bill.fromMap - Error converting map to Bill: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return a placeholder bill with empty items list
      return Bill(
        id: map['id']?.toString(),
        businessId: map['business_id'] as int? ?? 0,
        customer: Customer(
          id: map['customer_id'] as int? ?? 0,
          businessId: map['business_id'] as int? ?? 0,
          name: 'Unknown Customer',
          phone: '',
        ),
        items: const [],
        subTotal: (map['sub_total'] as num?)?.toDouble() ?? 0.0,
        gstAmount: (map['gst_amount'] as num?)?.toDouble() ?? 0.0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
        deliveryCharge: (map['delivery_charge'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        paidAt: map['paid_at'] != null
            ? DateTime.parse(map['paid_at'] as String)
            : null,
        notes: map['notes'] as String?,
      );
    }
  }

  Bill copyWith({
    String? id,
    int? businessId,
    Business? business,
    Customer? customer,
    List<BillItem>? items,
    double? subTotal,
    double? gstAmount,
    double? discount,
    double? deliveryCharge,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? notes,
  }) {
    return Bill(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      business: business ?? this.business,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      gstAmount: gstAmount ?? this.gstAmount,
      discount: discount ?? this.discount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class BillItem {
  final InventoryItem item;
  final int quantity;
  final double price;
  final double gstRate;
  final String? notes;

  const BillItem({
    required this.item,
    required this.quantity,
    required this.price,
    required this.gstRate,
    this.notes,
  });

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      item: InventoryItem.fromMap(map['item'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      gstRate: (map['gst_rate'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'quantity': quantity,
      'price': price,
      'gst_rate': gstRate,
      'notes': notes,
    };
  }

  double get total => price * quantity;
  double get gstAmount => total * (gstRate / 100);
  double get totalWithGst => total + gstAmount;

  BillItem copyWith({
    InventoryItem? item,
    int? quantity,
    double? price,
    double? gstRate,
    String? notes,
  }) {
    return BillItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      notes: notes ?? this.notes,
    );
  }
}
