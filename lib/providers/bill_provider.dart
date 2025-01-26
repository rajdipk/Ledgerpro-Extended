import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/bill_model.dart';
import '../models/customer_model.dart';
import '../models/inventory_item_model.dart';
import '../models/transaction_model.dart'; // Import transaction model
import '../models/stock_movement_model.dart'; // Import stock movement model

class BillProvider with ChangeNotifier {
  Bill? _currentBill;
  List<Bill> _bills = [];
  bool _isLoading = false;
  String? _error;
  final List<String> _missingItems = [];
  List<String> get missingItems => _missingItems;
  int? _selectedBusinessId;

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
  void addItem(InventoryItem item, int quantity, {
    String? notes,
    double? price,
    double? gstRate,
  }) {
    if (_currentBill == null) return;

    // Check if there's sufficient stock
    if (item.currentStock < quantity) {
      _error =
          'Insufficient stock for ${item.name}. Available: ${item.currentStock}';
      notifyListeners();
      return;
    }

    final billItem = BillItem(
      item: item,
      quantity: quantity,
      price: price ?? item.sellingPrice,
      gstRate: gstRate ?? item.gstRate,
      notes: notes,
    );

    debugPrint('Adding bill item: ${billItem.toMap()}');
    final items = List<BillItem>.from(_currentBill!.items)..add(billItem);
    _updateCurrentBill(items: items);
  }

  // Update item quantity
  void updateItemQuantity(int index, int quantity) {
    if (_currentBill == null || index >= _currentBill!.items.length) return;

    final item = _currentBill!.items[index].item;

    // Check if there's sufficient stock
    if (item.currentStock < quantity) {
      _error =
          'Insufficient stock for ${item.name}. Available: ${item.currentStock}';
      notifyListeners();
      return;
    }

    final items = List<BillItem>.from(_currentBill!.items);
    items[index] = items[index].copyWith(quantity: quantity);
    _updateCurrentBill(items: items);
  }

  // Remove item from bill
  void removeItem(int index) {
    if (_currentBill == null || index >= _currentBill!.items.length) return;

    final items = List<BillItem>.from(_currentBill!.items)..removeAt(index);
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

  // Toggle GST application
  void toggleGst(bool apply) {
    if (_currentBill == null) return;

    if (!apply) {
      // Reset GST rate for all items
      final updatedItems = _currentBill!.items.map((item) {
        return item.copyWith(gstRate: 0);
      }).toList();

      _currentBill = Bill.create(
        businessId: _currentBill!.businessId,
        customer: _currentBill!.customer,
        items: updatedItems,
        discount: _currentBill!.discount,
        notes: _currentBill!.notes,
      );
    }
    notifyListeners();
  }

  // Update GST rate for all items
  void updateGstRate(double rate) {
    if (_currentBill == null) return;

    final updatedItems = _currentBill!.items.map((item) {
      return item.copyWith(
          gstRate: rate / 100); // Convert percentage to decimal
    }).toList();

    _currentBill = Bill.create(
      businessId: _currentBill!.businessId,
      customer: _currentBill!.customer,
      items: updatedItems,
      discount: _currentBill!.discount,
      notes: _currentBill!.notes,
    );
    notifyListeners();
  }

  // Update delivery charge
  void updateDeliveryCharge(double charge) {
    if (_currentBill == null) return;
    _updateCurrentBill(deliveryCharge: charge);
  }

  // Helper method to update current bill
  void _updateCurrentBill({
    List<BillItem>? items,
    double? discount,
    String? notes,
    double? deliveryCharge,
  }) {
    if (_currentBill == null) return;

    debugPrint('Updating current bill:');
    debugPrint('- Items: ${items?.length ?? 0}');
    debugPrint('- Discount: $discount');
    debugPrint('- Notes: $notes');

    final updatedItems = items ?? _currentBill!.items;
    final subTotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final gstAmount = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.gstAmount,
    );

    final updatedDiscount = discount ?? _currentBill!.discount;
    final updatedDeliveryCharge = deliveryCharge ?? _currentBill!.deliveryCharge;
    final total = subTotal + gstAmount + updatedDeliveryCharge - updatedDiscount;

    _currentBill = Bill(
      id: _currentBill!.id,
      businessId: _currentBill!.businessId,
      business: _currentBill!.business,
      customer: _currentBill!.customer,
      items: updatedItems,
      subTotal: subTotal,
      gstAmount: gstAmount,
      discount: updatedDiscount,
      deliveryCharge: updatedDeliveryCharge,
      total: total,
      status: _currentBill!.status,
      createdAt: _currentBill!.createdAt,
      paidAt: _currentBill!.paidAt,
      notes: notes ?? _currentBill!.notes,
    );

    debugPrint('Bill updated:');
    debugPrint('- Items count: ${_currentBill!.items.length}');
    debugPrint('- First item price: ${_currentBill!.items.firstOrNull?.price}');
    debugPrint('- First item quantity: ${_currentBill!.items.firstOrNull?.quantity}');
    debugPrint('- First item total: ${_currentBill!.items.firstOrNull?.total}');

    notifyListeners();
  }

  // Save current bill to database
  Future<void> saveBill() async {
    if (_currentBill == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('BillProvider - Starting bill save process');
      debugPrint('BillProvider - Current bill details:');
      debugPrint('  Business ID: ${_currentBill!.businessId}');
      debugPrint('  Customer ID: ${_currentBill!.customer.id}');
      debugPrint('  Number of items: ${_currentBill!.items.length}');
      debugPrint('  Total amount: ${_currentBill!.total}');

      // Validate stock for all items before proceeding
      for (var item in _currentBill!.items) {
        final currentStock = await DatabaseHelper.instance.getItemStock(item.item.id!);
        debugPrint('BillProvider - Checking stock for item ${item.item.name}:');
        debugPrint('  Required: ${item.quantity}');
        debugPrint('  Available: $currentStock');
        
        if (currentStock < item.quantity) {
          throw Exception('Insufficient stock for ${item.item.name}. Available: $currentStock');
        }
      }

      // Begin transaction
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        debugPrint('BillProvider - Starting database transaction');
        
        // Save bill to database
        final billMap = _currentBill!.toMap();
        debugPrint('BillProvider - Saving bill with data: $billMap');
        final billId = await txn.insert('bills', billMap);
        debugPrint('BillProvider - Bill saved with ID: $billId');

        // Process each item
        for (var item in _currentBill!.items) {
          debugPrint('BillProvider - Processing bill item: ${item.item.name}');
          
          // Save bill item
          final itemMap = {
            'bill_id': billId,
            'item_id': item.item.id,
            'quantity': item.quantity,
            'price': item.price,
            'gst_rate': item.gstRate,
            'notes': item.notes,
          };
          debugPrint('BillProvider - Saving bill item with data: $itemMap');
          await txn.insert('bill_items', itemMap);

          // Create stock movement
          final movement = StockMovement(
            businessId: _currentBill!.businessId,
            itemId: item.item.id!,
            movementType: 'OUT',
            quantity: item.quantity,
            unitPrice: item.price,
            totalPrice: item.total,
            date: DateTime.now().toIso8601String(),
            referenceType: 'BILL',
            referenceId: billId,
            notes: 'Bill #$billId - Sale',
          );
          debugPrint('BillProvider - Creating stock movement: ${movement.toMap()}');
          await txn.insert('stock_movements', movement.toMap());

          // Update inventory stock
          final newStock = item.item.currentStock - item.quantity;
          debugPrint('BillProvider - Updating inventory stock to: $newStock');
          await txn.update(
            'inventory_items',
            {'current_stock': newStock},
            where: 'id = ?',
            whereArgs: [item.item.id],
          );
        }

        // Create customer transaction
        final transaction = Transaction(
          customerId: _currentBill!.customer.id,
          amount: -_currentBill!.total,
          date: DateTime.now().toIso8601String(),
          balance: _currentBill!.customer.balance - _currentBill!.total,
          referenceType: 'BILL',
          referenceId: billId,
          notes: 'Bill #$billId',
        );
        debugPrint('BillProvider - Creating transaction: ${transaction.toMap()}');
        await txn.insert('transactions', transaction.toMap());

        // Update customer balance
        debugPrint('BillProvider - Updating customer balance');
        await txn.update(
          'customers',
          {'balance': _currentBill!.customer.balance - _currentBill!.total},
          where: 'id = ? AND business_id = ?',
          whereArgs: [_currentBill!.customer.id, _currentBill!.businessId],
        );
        
        debugPrint('BillProvider - Transaction completed successfully');
      });

      debugPrint('BillProvider - Bill save process completed');
      
      // Clear current bill and reload
      final businessId = _currentBill!.businessId;
      _currentBill = null;
      await loadBills(businessId);
    } catch (e) {
      debugPrint('BillProvider - Error saving bill: $e');
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

      debugPrint('BillProvider - Loading bills for business: $businessId');
      final billMaps = await DatabaseHelper.instance.getBills(businessId);
      debugPrint('BillProvider - Found ${billMaps.length} bills');
      
      final bills = await Future.wait(
        billMaps.map((billMap) async {
          try {
            debugPrint('BillProvider - Processing bill map: $billMap');
            // Get bill items
            final billItems = await DatabaseHelper.instance
                .getBillItems(billMap['id'] as int);
            debugPrint('BillProvider - Got bill items: $billItems');
            
            // Add items to bill map
            billMap['items'] = billItems;

            debugPrint('BillProvider - Creating Bill from map: $billMap');
            return Bill.fromMap(billMap);
          } catch (e, stackTrace) {
            debugPrint('BillProvider - Error processing bill #${billMap['id']}: $e');
            debugPrint('Stack trace: $stackTrace');
            _error = 'Error loading bill #${billMap['id']}: $e';
            return null;
          }
        }),
      );

      _bills = bills.whereType<Bill>().toList();
      debugPrint('BillProvider - Successfully loaded ${_bills.length} bills');
    } catch (e, stackTrace) {
      debugPrint('BillProvider - Error loading bills: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Failed to load bills: ${e.toString()}';
      _bills = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select customer
  Future<void> selectCustomer(Customer customer) async {
    try {
      final lastTransactionDate =
          await DatabaseHelper.instance.getLastTransactionDate(customer.id);
      if (lastTransactionDate != null) {
        try {
          customer.lastTransactionDate = DateTime.parse(lastTransactionDate);
        } catch (e) {
          _error = 'Failed to parse last transaction date: ${e.toString()}';
        }
      }

      _currentBill = Bill(
        businessId: _currentBill?.businessId ?? 0,
        customer: customer,
        items: _currentBill?.items ?? [],
        total: _currentBill?.total ?? 0,
        subTotal: _currentBill?.subTotal ?? 0,
        gstAmount: _currentBill?.gstAmount ?? 0,
        createdAt: DateTime.now(),
        status: 'pending',
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to select customer: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cancel current bill
  void cancelBill() {
    _currentBill = null;
    notifyListeners();
  }

  void clearCurrentBill() {
    _currentBill = null;
    notifyListeners();
  }

  void clearMissingItems() {
    _missingItems.clear();
    notifyListeners();
  }

  void setSelectedBusiness(int businessId) {
    _selectedBusinessId = businessId;
    refreshBills();
  }

  void refreshBills() async {
    await loadBills(_selectedBusinessId!);
  }
}
