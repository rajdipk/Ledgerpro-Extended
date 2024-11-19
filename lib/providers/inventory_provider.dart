import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/purchase_order_model.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<InventoryItem> _items = [];
  List<StockMovement> _movements = [];
  List<PurchaseOrder> _purchaseOrders = [];
  int _selectedBusinessId = 0;

  // Getters
  List<InventoryItem> get items => _items;
  List<StockMovement> get movements => _movements;
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  int get selectedBusinessId => _selectedBusinessId;

  // Set selected business
  void setSelectedBusiness(int businessId) {
    _selectedBusinessId = businessId;
    refreshInventory();
  }

  // Refresh all inventory data
  Future<void> refreshInventory() async {
    await Future.wait([
      refreshItems(),
      refreshMovements(),
      refreshPurchaseOrders(),
    ]);
    notifyListeners();
  }

  // Inventory Items Methods
  Future<void> refreshItems() async {
    _items = await _db.getInventoryItems(_selectedBusinessId);
  }

  Future<void> addItem(InventoryItem item) async {
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
    await _db.addStockMovement(movement);
    await Future.wait([
      refreshMovements(),
      refreshItems(), // Refresh items as stock levels will change
    ]);
    notifyListeners();
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

  Future<void> receivePurchaseOrder(int orderId, List<PurchaseOrderItem> items) async {
    await _db.receivePurchaseOrderItems(orderId, items);
    await Future.wait([
      refreshPurchaseOrders(),
      refreshItems(),
      refreshMovements(),
    ]);
    notifyListeners();
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
    return _items.where((item) => item.currentStock <= item.reorderLevel).toList();
  }

  double getTotalInventoryValue() {
    return _items.fold(0, (sum, item) => sum + (item.costPrice * item.currentStock));
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
