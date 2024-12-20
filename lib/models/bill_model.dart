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
    String? notes,
  }) {
    final subTotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    final gstAmount = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity * (item.gstRate / 100)),
    );

    return Bill(
      businessId: businessId,
      customer: customer,
      items: items,
      subTotal: subTotal,
      gstAmount: gstAmount,
      discount: discount,
      total: subTotal + gstAmount - discount,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'business_id': businessId,
      'customer_id': customer.id,
      'sub_total': subTotal,
      'gst_amount': gstAmount,
      'discount': discount,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, {
    required Customer customer,
    required List<BillItem> items,
    Business? business,
  }) {
    return Bill(
      id: map['id']?.toString(),
      businessId: map['business_id'] as int,
      business: business,
      customer: customer,
      items: items,
      subTotal: (map['sub_total'] as num).toDouble(),
      gstAmount: (map['gst_amount'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      notes: map['notes'] as String?,
    );
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
    this.gstRate = 0,
    this.notes,
  });

  double get total => price * quantity;
  double get gstAmount => total * (gstRate / 100);
  double get totalWithGst => total + gstAmount;

  Map<String, dynamic> toMap() {
    return {
      'item_id': item.id,
      'quantity': quantity,
      'price': price,
      'gst_rate': gstRate,
      'notes': notes,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map, {
    required InventoryItem item,
  }) {
    return BillItem(
      item: item,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      gstRate: (map['gst_rate'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

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
