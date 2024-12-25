import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/purchase_order_model.dart';
import '../models/transaction_model.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<InventoryItem> _items = [];
  List<StockMovement> _movements = [];
  List<PurchaseOrder> _purchaseOrders = [];
  int _selectedBusinessId = 0;

  // Getters
  List<InventoryItem> get items => _items;
  List<StockMovement> get movements => _movements;
  List<PurchaseOrder> get purchaseOrders => List.from(_purchaseOrders)
    ..sort((a, b) =>
        DateTime.parse(b.orderDate).compareTo(DateTime.parse(a.orderDate)));
  int get selectedBusinessId => _selectedBusinessId;

  // Set selected business
  void setSelectedBusiness(int businessId) {
    debugPrint('InventoryProvider - Setting business ID: $businessId');
    debugPrint('InventoryProvider - Current items: ${_items.length}');
    debugPrint(
        'InventoryProvider - Current items business IDs: ${_items.map((e) => e.businessId).toList()}');
    _selectedBusinessId = businessId;
    refreshInventory();
  }

  // Refresh all inventory data
  Future<void> refreshInventory() async {
    debugPrint(
        'InventoryProvider - Refreshing inventory for business: $_selectedBusinessId');
    await Future.wait([
      refreshItems(),
      refreshMovements(),
      refreshPurchaseOrders(),
    ]);
    debugPrint(
        'InventoryProvider - Inventory refreshed, items count: ${_items.length}');
    debugPrint(
        'InventoryProvider - Refreshed items business IDs: ${_items.map((e) => e.businessId).toList()}');
    notifyListeners();
  }

  // Inventory Items Methods
  Future<void> refreshItems() async {
    debugPrint(
        'InventoryProvider - Refreshing items for business: $_selectedBusinessId');
    _items = await _db.getInventoryItems(_selectedBusinessId);
    debugPrint('InventoryProvider - Items refreshed, count: ${_items.length}');
    debugPrint(
        'InventoryProvider - Items business IDs: ${_items.map((e) => e.businessId).toList()}');
  }

  Future<void> addItem(InventoryItem item) async {
    debugPrint(
        'InventoryProvider - Adding item with business ID: ${item.businessId}');
    await _db.addInventoryItem(item);
    await refreshItems();
    notifyListeners();
  }

  Future<void> updateItem(InventoryItem item) async {
    await _db.updateInventoryItem(item);
    await refreshItems();
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteInventoryItem(id);
    await refreshItems();
    notifyListeners();
  }

  // Stock Movements Methods
  Future<void> refreshMovements() async {
    _movements = await _db.getStockMovements(_selectedBusinessId);
  }

  Future<void> addMovement(StockMovement movement) async {
    try {
      await _db.addStockMovement(movement);
      // Refresh data sequentially to prevent database locking
      await refreshMovements();
      await refreshItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in addMovement: $e');
      rethrow;
    }
  }

  Future<List<StockMovement>> getItemMovements(int itemId) async {
    return await _db.getItemStockMovements(itemId);
  }

  // Purchase Orders Methods
  Future<void> refreshPurchaseOrders() async {
    _purchaseOrders = await _db.getPurchaseOrders(_selectedBusinessId);
  }

  Future<void> addPurchaseOrder(PurchaseOrder order) async {
    await _db.addPurchaseOrder(order);
    await refreshPurchaseOrders();
    notifyListeners();
  }

  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    await _db.updatePurchaseOrder(order);
    await refreshPurchaseOrders();
    notifyListeners();
  }

  Future<void> deletePurchaseOrder(int id) async {
    await _db.deletePurchaseOrder(id);
    await refreshPurchaseOrders();
    notifyListeners();
  }

  Future<void> updatePurchaseOrderStatus(int id, String status) async {
    await _db.updatePurchaseOrderStatus(id, status);
    await refreshPurchaseOrders();
    notifyListeners();
  }

  Future<void> receivePurchaseOrder(
      int orderId, List<PurchaseOrderItem> items) async {
    try {
      // Get the purchase order details first
      final order = await _db.getPurchaseOrder(orderId);
      if (order == null) {
        throw Exception('Purchase order not found');
      }

      // Only proceed if the order is not already received
      if (order.status == 'RECEIVED') {
        throw Exception('Order is already received');
      }

      // Process the order items - this will create stock movements
      await _db.receivePurchaseOrderItems(orderId, items);

      // Calculate total amount received
      double totalReceived = items
          .where((item) => item.receivedQuantity > 0)
          .fold(
              0, (sum, item) => sum + (item.unitPrice * item.receivedQuantity));

      // Create a supplier transaction for the received amount
      if (totalReceived > 0) {
        final transaction = Transaction(
          supplierId: order.supplierId,
          amount: totalReceived,
          date: DateTime.now().toIso8601String(),
          balance: 0,
        );
        await _db.addSupplierTransaction(transaction);
      }

      await refreshPurchaseOrders();
      await refreshItems();
      await refreshMovements();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in receivePurchaseOrder: $e');
      rethrow;
    }
  }

  // Search items by name, SKU, or barcode
  Future<List<InventoryItem>> searchItems(String query) async {
    if (query.isEmpty) return [];
    query = query.toLowerCase();
    return _items
        .where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.sku!.toLowerCase().contains(query) ||
            (item.barcode?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  // Helper Methods
  InventoryItem? getItemById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<InventoryItem> getLowStockItems() {
    return _items
        .where((item) => item.currentStock <= item.reorderLevel)
        .toList();
  }

  double getTotalInventoryValue() {
    return _items.fold(
        0, (sum, item) => sum + (item.costPrice * item.currentStock));
  }

  Map<String, int> getStockMovementSummary() {
    int inward = 0;
    int outward = 0;
    for (var movement in _movements) {
      if (movement.movementType == 'IN') {
        inward += movement.quantity;
      } else {
        outward += movement.quantity;
      }
    }
    return {'inward': inward, 'outward': outward};
  }

  List<PurchaseOrder> getPendingOrders() {
    return _purchaseOrders.where((order) => order.status == 'ORDERED').toList();
  }
}
