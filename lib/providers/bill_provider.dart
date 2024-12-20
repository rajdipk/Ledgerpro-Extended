import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/bill_model.dart';
import '../models/business_model.dart';
import '../models/customer_model.dart';
import '../models/inventory_item_model.dart';

class BillProvider with ChangeNotifier {
  Bill? _currentBill;
  List<Bill> _bills = [];
  bool _isLoading = false;
  String? _error;
  final List<String> _missingItems = [];
  List<String> get missingItems => _missingItems;

  Bill? get currentBill => _currentBill;
  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new bill
  void startNewBill(int businessId, Customer customer) {
    _currentBill = Bill.create(
      businessId: businessId,
      customer: customer,
      items: const [],
    );
    notifyListeners();
  }

  // Add item to current bill
  void addItem(InventoryItem item, int quantity, {String? notes}) {
    if (_currentBill == null) return;

    final billItem = BillItem(
      item: item,
      quantity: quantity,
      price: item.sellingPrice,
      notes: notes,
    );

    final items = List<BillItem>.from(_currentBill!.items)..add(billItem);
    _updateCurrentBill(items: items);
  }

  // Update item quantity
  void updateItemQuantity(int index, int quantity) {
    if (_currentBill == null || index >= _currentBill!.items.length) return;

    final items = List<BillItem>.from(_currentBill!.items);
    items[index] = items[index].copyWith(quantity: quantity);
    _updateCurrentBill(items: items);
  }

  // Remove item from bill
  void removeItem(int index) {
    if (_currentBill == null || index >= _currentBill!.items.length) return;

    final items = List<BillItem>.from(_currentBill!.items)
      ..removeAt(index);
    _updateCurrentBill(items: items);
  }

  // Update discount
  void updateDiscount(double discount) {
    if (_currentBill == null) return;
    _updateCurrentBill(discount: discount);
  }

  // Update notes
  void updateNotes(String notes) {
    if (_currentBill == null) return;
    _updateCurrentBill(notes: notes);
  }

  // Helper method to update current bill
  void _updateCurrentBill({
    List<BillItem>? items,
    double? discount,
    String? notes,
  }) {
    if (_currentBill == null) return;

    final updatedItems = items ?? _currentBill!.items;
    final subTotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    
    final gstAmount = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.gstAmount,
    );

    _currentBill = _currentBill!.copyWith(
      items: updatedItems,
      subTotal: subTotal,
      gstAmount: gstAmount,
      discount: discount ?? _currentBill!.discount,
      total: subTotal + gstAmount - (discount ?? _currentBill!.discount),
      notes: notes ?? _currentBill!.notes,
    );

    notifyListeners();
  }

  // Save current bill to database
  Future<void> saveBill() async {
    if (_currentBill == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Save bill to database
      final billMap = _currentBill!.toMap();
      final billId = await DatabaseHelper.instance.addBill(billMap);

      // Save bill items
      for (var item in _currentBill!.items) {
        final itemMap = item.toMap();
        itemMap['bill_id'] = billId;
        await DatabaseHelper.instance.addBillItem(itemMap);

        // Update inventory stock
        await DatabaseHelper.instance.updateInventoryStock(
          item.item.id!,
          item.item.currentStock - item.quantity,
        );
      }

      // Update customer balance
      await DatabaseHelper.instance.updateCustomerBalance(
        _currentBill!.customer.id,
        _currentBill!.businessId,
        _currentBill!.customer.balance + _currentBill!.total,
      );

      // Clear current bill
      _currentBill = null;
      await loadBills(_currentBill!.businessId);
    } catch (e) {
      _error = 'Failed to save bill: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load bills for a business
  Future<void> loadBills(int businessId) async {
    try {
      _isLoading = true;
      _error = null;
      _missingItems.clear();
      notifyListeners();

      final bills = await DatabaseHelper.instance.getBills(businessId);
      _bills = await Future.wait(
        bills.map((billMap) async {
          try {
            // Get business
            final businessMaps = await DatabaseHelper.instance.getBusinesses();
            final business = businessMaps.isNotEmpty 
              ? Business.fromMap(businessMaps.first)
              : null;

            // Get customer
            final customerMap = await DatabaseHelper.instance.getCustomer(
              billMap['customer_id'] as int,
            );
            final customer = Customer.fromMap(customerMap);

            // Get bill items
            final billItems = await DatabaseHelper.instance.getBillItems(
              billMap['id'] as int,
            );

            // Convert bill items
            final items = await Future.wait(
              billItems.map((itemMap) async {
                try {
                  final inventoryItem = await DatabaseHelper.instance.getInventoryItem(
                    itemMap['item_id'] as int,
                  );
                  if (inventoryItem == null) {
                    _missingItems.add('Item ID: ${itemMap['item_id']} in Bill #${billMap['id']}');
                    // Create a placeholder item for missing inventory
                    return BillItem.fromMap(
                      itemMap,
                      item: InventoryItem(
                        id: itemMap['item_id'] as int,
                        businessId: businessId,
                        name: 'Missing Item #${itemMap['item_id']}',
                        unit: 'N/A',
                        sellingPrice: itemMap['price'] as double,
                        costPrice: 0,
                        currentStock: 0,
                        reorderLevel: 0,
                        createdAt: DateTime.now().toIso8601String(),
                        updatedAt: DateTime.now().toIso8601String(),
                      ),
                    );
                  }
                  return BillItem.fromMap(
                    itemMap,
                    item: inventoryItem,
                  );
                } catch (e) {
                  _missingItems.add('Error loading item in Bill #${billMap['id']}: $e');
                  // Return a placeholder item for errored inventory
                  return BillItem.fromMap(
                    itemMap,
                    item: InventoryItem(
                      id: itemMap['item_id'] as int,
                      businessId: businessId,
                      name: 'Error Loading Item #${itemMap['item_id']}',
                      unit: 'N/A',
                      sellingPrice: itemMap['price'] as double,
                      costPrice: 0,
                      currentStock: 0,
                      reorderLevel: 0,
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    ),
                  );
                }
              }),
            );

            return Bill.fromMap(
              billMap,
              customer: customer,
              items: items,
              business: business,
            );
          } catch (e) {
            _error = 'Error loading bill #${billMap['id']}: $e';
            // Return a placeholder bill for errored bills
            return Bill.fromMap(
              billMap,
              customer: Customer(
                id: billMap['customer_id'] as int,
                businessId: billMap['business_id'] as int,
                name: 'Error Loading Customer',
                phone: 'N/A',
                address: 'N/A',
                pan: 'N/A',
                gstin: 'N/A',
              ),
              items: const [], // Empty list for error case
            );
          }
        }),
      );

      if (_missingItems.isNotEmpty) {
        _error = 'Some items could not be loaded. Check missing items list.';
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load bills: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel current bill
  void cancelBill() {
    _currentBill = null;
    notifyListeners();
  }

  void clearMissingItems() {
    _missingItems.clear();
    notifyListeners();
  }
}
