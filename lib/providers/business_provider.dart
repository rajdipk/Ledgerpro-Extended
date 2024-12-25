//business_provider.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/business_model.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/supplier_model.dart';
import '../database/supplier_operations.dart';

class BusinessProvider with ChangeNotifier {
  List<Business> _businesses = [];
  final List<FlSpot> _dailyBalances = [];
  int customerCount = 0;
  int supplierCount = 0; // Added supplier count

  String? _selectedBusinessId;
  bool _isPasswordValid = true;
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;

  double _customerReceivableBalance = 0.0;
  double _customerPayableBalance = 0.0;
  double _supplierReceivableBalance = 0.0;
  double _supplierPayableBalance = 0.0;

  // New variable to store the selected customer's balance
  double _selectedCustomerBalance = 0.0;
  // New variable to store the selected supplier's balance
  double _selectedSupplierBalance = 0.0;

  List<Business> get businesses => _businesses;
  List<FlSpot> get dailyBalances => _dailyBalances;
  bool get isPasswordValid => _isPasswordValid;
  String? get selectedBusinessId {
    debugPrint('BusinessProvider - Getting selected business ID: $_selectedBusinessId');
    return _selectedBusinessId;
  }
  Customer? get selectedCustomer => _selectedCustomer;
  Supplier? get selectedSupplier => _selectedSupplier;

  double get customerReceivableBalance => _customerReceivableBalance;
  double get customerPayableBalance => _customerPayableBalance;
  double get supplierReceivableBalance => _supplierReceivableBalance;
  double get supplierPayableBalance => _supplierPayableBalance;

  // Total balances for overall view
  double get receivableBalance =>
      _customerReceivableBalance + _supplierReceivableBalance;
  double get payableBalance =>
      _customerPayableBalance + _supplierPayableBalance;

  // Getter for the selected customer's balance
  double get selectedCustomerBalance => _selectedCustomerBalance;
  // Getter for the selected supplier's balance
  double get selectedSupplierBalance => _selectedSupplierBalance;

  // Add getter for supplier count
  int get getSupplierCount => supplierCount;

  // Add getter for supplier transactions
  List<Transaction>? get supplierTransactions {
    if (_selectedSupplier == null) return null;
    return _selectedSupplier!.transactions;
  }

  BusinessProvider() {
    loadBusinessesFromDb();
  }

  Future<void> loadBusinessesFromDb() async {
    final loadedBusinessesMaps = await DatabaseHelper.instance.getBusinesses();
    _businesses = loadedBusinessesMaps
        .map((business) =>
            Business(id: business['id'].toString(), name: business['name']))
        .toList();
    notifyListeners();
  }

  Future<void> addBusiness(String name) async {
    final now = DateTime.now();
    final business = Business(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    final int newBusinessId = await DatabaseHelper.instance.addBusiness(business.toMap());
    
    // Set the newly added business as selected
    _selectedBusinessId = newBusinessId.toString();
    
    // Refresh the business list
    await loadBusinessesFromDb();
    
    // Load counts and balances for the new business
    await loadCustomerCount();
    await loadSupplierCount();
    await calculateBalances();
    
    notifyListeners();
  }

  Future<void> deleteBusiness(String id, String password) async {
    final isValidPassword =
        await DatabaseHelper.instance.checkPassword(password);
    if (isValidPassword) {
      await DatabaseHelper.instance.deleteBusiness(int.parse(id));
      if (_selectedBusinessId == id) {
        _selectedBusinessId = null;
      }
      await loadBusinessesFromDb();
      _isPasswordValid = true;
      notifyListeners();
    } else {
      _isPasswordValid = false;
      notifyListeners();
    }
  }

  void setSelectedBusinessId(String? businessId) {
    _selectedBusinessId = businessId;
    if (businessId != null) {
      loadCustomerCount();
      refreshSuppliers(); // Load supplier count when business is selected
      calculateBalances(); // Calculate balances when a business is selected
    } else {
      customerCount = 0;
      supplierCount = 0;
    }
    notifyListeners();
  }

  // Method to load customer count
  Future<void> loadCustomerCount() async {
    if (_selectedBusinessId != null) {
      customerCount = await DatabaseHelper.instance
          .getCustomerCountForBusiness(int.parse(_selectedBusinessId!));
      notifyListeners();
    }
  }

  // Method to load supplier count
  Future<void> loadSupplierCount() async {
    if (_selectedBusinessId != null) {
      final supplierMaps = await DatabaseHelper.instance
          .getSuppliers(int.parse(_selectedBusinessId!));
      supplierCount = supplierMaps.length;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Map<String, dynamic> customerData) async {
    await DatabaseHelper.instance.addCustomer(customerData);
    await loadCustomerCount();
    calculateBalances(); // Recalculate balances after adding a customer
    notifyListeners(); // Notify all listeners to refresh their data
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    if (_selectedCustomer != null) {
      // Fetch and store the selected customer's balance
      _selectedCustomerBalance = _selectedCustomer!.balance;
      refreshTransactions(_selectedCustomer!.id);
    }
    notifyListeners();
  }

  Future<void> setSelectedCustomerById(int customerId) async {
    final customers = await DatabaseHelper.instance
        .getCustomers(int.parse(_selectedBusinessId ?? '0'));
    _selectedCustomer = customers
        .map((map) => Customer.fromMap(map))
        .firstWhere((c) => c.id == customerId);
    notifyListeners();
  }

  void setSelectedSupplier(Supplier? supplier) {
    _selectedSupplier = supplier;
    if (_selectedSupplier != null) {
      // Fetch and store the selected supplier's balance
      _selectedSupplierBalance = _selectedSupplier!.balance;
      refreshSupplierTransactions(_selectedSupplier!.id);
    }
    notifyListeners();
  }

  // Method to handle 'Amount Received'
  Future<void> addAmountReceived(
      int customerId, double amount, String date) async {
    await addTransaction(customerId, -amount.abs(),
        date); // Negative amount when we receive money (reduces receivable)
    await calculateAndUpdateCustomerBalance(customerId);
    await refreshCustomerData(customerId);
  }

  // Method to handle 'Amount Given'
  Future<void> addAmountGiven(
      int customerId, double amount, String date) async {
    await addTransaction(customerId, amount.abs(),
        date); // Positive amount when we give money (increases payable)
    await calculateAndUpdateCustomerBalance(customerId);
    await refreshCustomerData(customerId);
  }

  // Method to add a transaction and update balance
  Future<void> addTransaction(
      int customerId, double amount, String date) async {
    // Fetch the last transaction balance for the customer
    double lastBalance =
        await DatabaseHelper.instance.getLastTransactionBalance(customerId) ??
            0.0;

    // Calculate the new balance
    double newBalance = lastBalance + amount;

    // Add the new transaction with the calculated balance
    await DatabaseHelper.instance.addTransaction(
      Transaction(
        customerId: customerId,
        amount: amount,
        date: date,
        balance: newBalance,
      ),
    );

    // Update the customer balance
    await DatabaseHelper.instance.updateCustomerBalance(
        customerId, int.parse(_selectedBusinessId!), newBalance);

    // Refresh transactions for the customer
    await refreshTransactions(customerId);

    // Update the stored balance of the selected customer if it's the same customer
    if (_selectedCustomer != null && _selectedCustomer!.id == customerId) {
      _selectedCustomerBalance = newBalance;
    }

    // Notify listeners to rebuild UI
    notifyListeners();
  }

  // Method to calculate and update customer balance
  Future<void> calculateAndUpdateCustomerBalance(int customerId) async {
    final transactions =
        await DatabaseHelper.instance.getTransactions(customerId);
    double runningBalance = 0;

    for (var transactionMap in transactions) {
      runningBalance += transactionMap['amount'];
      await DatabaseHelper.instance
          .updateTransactionBalance(transactionMap['id'], runningBalance);
    }

    int? businessId =
        _selectedBusinessId != null ? int.tryParse(_selectedBusinessId!) : null;
    if (businessId != null) {
      await DatabaseHelper.instance
          .updateCustomerBalance(customerId, businessId, runningBalance);
    }

    if (_selectedCustomer != null && _selectedCustomer!.id == customerId) {
      _selectedCustomer!.balance = runningBalance;
      _selectedCustomerBalance = runningBalance; // Update stored balance
      notifyListeners();
    }

    calculateBalances(); // Recalculate balances after updating a customer's balance
  }

  // Method to refresh the list of transactions for a customer
  Future<void> refreshTransactions(int customerId) async {
    // Fetch the updated list of transactions from the database
    final transactions =
        await DatabaseHelper.instance.getTransactions(customerId);
    // Update the transactions list for the selected customer
    _selectedCustomer!.transactions = transactions.map((transactionMap) {
      return Transaction(
        id: transactionMap['id'],
        customerId: transactionMap['customer_id'],
        amount: transactionMap['amount'],
        date: transactionMap['date'],
        balance: transactionMap['balance'],
      );
    }).toList();

    notifyListeners(); // Notify to refresh the UI
  }

  // Method to refresh supplier transactions and balance
  Future<void> refreshSupplierTransactions(int supplierId) async {
    if (_selectedSupplier != null && _selectedSupplier!.id == supplierId) {
      final transactions =
          await DatabaseHelper.instance.getSupplierTransactions(supplierId);
      _selectedSupplier!.transactions = transactions.map((transactionMap) {
        return Transaction(
          id: transactionMap['id'],
          supplierId: transactionMap['supplier_id'],
          amount: transactionMap['amount'],
          date: transactionMap['date'],
          balance: transactionMap['balance'],
        );
      }).toList();

      // Update supplier balance
      final supplierOps = SupplierOperations(DatabaseHelper.instance);
      final newBalance = await supplierOps.getSupplierBalance(supplierId);
      _selectedSupplier!.balance = newBalance;
      _selectedSupplierBalance = newBalance; // Update stored balance

      // Recalculate overall balances
      await calculateBalances();

      notifyListeners();
    }
  }

  Future<void> updateTransaction(
      int transactionId, Transaction updatedTransaction) async {
    if (updatedTransaction.customerId == null) {
      throw Exception('Customer ID cannot be null');
    }

    // Step 1: Update the transaction in the database
    await DatabaseHelper.instance
        .updateTransaction(transactionId, updatedTransaction);

    // Step 2: Recalculate and update all balances
    await calculateAndUpdateCustomerBalance(updatedTransaction.customerId!);

    // Step 3: Refresh customer data and UI
    await refreshCustomerData(updatedTransaction.customerId!);
  }

  Future<void> deleteTransaction(int transactionId, int customerId) async {
    // Step 1: Fetch the last balance for the customer before the deleted transaction
    double lastBalance = await DatabaseHelper.instance
            .getLastTransactionBalanceForUpdate(customerId, transactionId) ??
        0.0;

    // Step 2: Delete the specified transaction from the database
    await DatabaseHelper.instance.deleteTransaction(transactionId);

    // Step 3: Fetch all transactions for the customer after the deleted transaction
    List<Map<String, dynamic>> subsequentTransactions = await DatabaseHelper
        .instance
        .getTransactionsAfterId(customerId, transactionId);

    // Step 4: Update the balances for subsequent transactions
    double newBalance = lastBalance; // Start from the last balance
    for (var txn in subsequentTransactions) {
      int id = txn['id'];
      double amount = txn['amount'];
      // Calculate the new balance
      newBalance += amount;

      // Update the balance for the current transaction
      await DatabaseHelper.instance.updateTransactionBalance(id, newBalance);
    }

    // Step 5: Update the customer's balance in the database
    int? businessId =
        _selectedBusinessId != null ? int.tryParse(_selectedBusinessId!) : null;
    if (businessId != null) {
      await DatabaseHelper.instance
          .updateCustomerBalance(customerId, businessId, newBalance);
    }

    // Step 6: If the selected customer is the same, update the in-memory balance for the UI
    if (_selectedCustomer != null && _selectedCustomer!.id == customerId) {
      _selectedCustomer!.balance =
          newBalance; // Update the selected customer's balance
      _selectedCustomerBalance = newBalance; // Update the stored balance
      notifyListeners();
    }

    // Step 7: Optionally refresh the list of transactions
    await refreshTransactions(customerId);

    // Notify listeners to refresh UI
    notifyListeners();
  }

  // Supplier transaction methods
  Future<void> addSupplierPayment(double amount, String date) async {
    if (_selectedSupplier == null) {
      throw Exception('No supplier selected');
    }

    final transaction = Transaction(
      supplierId: _selectedSupplier!.id,
      amount: -amount.abs(), // Payment is negative (money going out)
      date: date,
      balance: 0, // This will be calculated in addSupplierTransaction
    );

    final supplierOps = SupplierOperations(DatabaseHelper.instance);
    await supplierOps.addSupplierTransaction(transaction);
    await refreshSupplierTransactions(_selectedSupplier!.id);
  }

  Future<void> addSupplierReceipt(double amount, String date) async {
    if (_selectedSupplier == null) {
      throw Exception('No supplier selected');
    }

    final transaction = Transaction(
      supplierId: _selectedSupplier!.id,
      amount: amount.abs(), // Receipt is positive (money coming in)
      date: date,
      balance: 0, // This will be calculated in addSupplierTransaction
    );

    final supplierOps = SupplierOperations(DatabaseHelper.instance);
    await supplierOps.addSupplierTransaction(transaction);
    await refreshSupplierTransactions(_selectedSupplier!.id);
  }

  Future<void> updateSupplierTransaction(Transaction transaction) async {
    final supplierOps = SupplierOperations(DatabaseHelper.instance);
    await supplierOps.updateSupplierTransaction(transaction);

    if (_selectedSupplier != null) {
      // Update supplier balance
      final newBalance =
          await supplierOps.getSupplierBalance(_selectedSupplier!.id);
      _selectedSupplier!.balance = newBalance;
      _selectedSupplierBalance = newBalance; // Update stored balance

      await refreshSupplierTransactions(_selectedSupplier!.id);
      await calculateBalances(); // Recalculate overall balances
    }
    notifyListeners();
  }

  Future<void> deleteSupplierTransaction(
      int transactionId, int supplierId) async {
    final supplierOps = SupplierOperations(DatabaseHelper.instance);
    await supplierOps.deleteSupplierTransaction(transactionId, supplierId);

    if (_selectedSupplier != null) {
      // Update supplier balance
      final newBalance =
          await supplierOps.getSupplierBalance(_selectedSupplier!.id);
      _selectedSupplier!.balance = newBalance;
      _selectedSupplierBalance = newBalance; // Update stored balance

      await refreshSupplierTransactions(_selectedSupplier!.id);
      await calculateBalances(); // Recalculate overall balances
    }
    notifyListeners();
  }

  // Method to delete a customer and all related transactions
  Future<void> deleteCustomerAndTransactions(
      int customerId, int businessId) async {
    // Delete all transactions related to the customer
    await DatabaseHelper.instance.deleteTransactionsForCustomer(customerId);

    // Delete the customer itself
    await DatabaseHelper.instance.deleteCustomer(customerId, businessId);

    // Update the customer count
    await loadCustomerCount();

    calculateBalances(); // Recalculate balances after deleting a customer

    // Notify listeners or perform any additional logic as needed
    notifyListeners();
  }

  //Method to calculate and update the customer balances for the Dashboards
  Future<void> calculateBalances() async {
    if (_selectedBusinessId != null) {
      // Calculate customer balances
      final customers = await DatabaseHelper.instance
          .getCustomers(int.parse(_selectedBusinessId!));
      double customerReceivable = 0.0;
      double customerPayable = 0.0;

      // Calculate customer receivables and payables
      for (var customer in customers) {
        double balance = customer['balance'] ?? 0.0;
        if (balance < 0) {
          customerReceivable += balance.abs();
        } else {
          customerPayable += balance;
        }
      }

      // Calculate supplier balances
      final suppliers = await DatabaseHelper.instance
          .getSuppliers(int.parse(_selectedBusinessId!));
      double supplierReceivable = 0.0;
      double supplierPayable = 0.0;

      for (var supplier in suppliers) {
        final supplierOps = SupplierOperations(DatabaseHelper.instance);
        double balance = await supplierOps.getSupplierBalance(supplier['id']);
        if (balance < 0) {
          supplierReceivable += balance.abs();
        } else {
          supplierPayable += balance;
        }
      }

      _customerReceivableBalance = customerReceivable;
      _customerPayableBalance = customerPayable;
      _supplierReceivableBalance = supplierReceivable;
      _supplierPayableBalance = supplierPayable;

      // Store the calculated balances in customer_balances table
      await DatabaseHelper.instance.calculateAndUpdateCustomerBalances(
        int.parse(_selectedBusinessId!),
      );

      notifyListeners();
    }
  }

  Future<void> refreshSuppliers() async {
    if (_selectedBusinessId != null) {
      final supplierMaps = await DatabaseHelper.instance
          .getSuppliers(int.parse(_selectedBusinessId!));

      // Update supplier count
      supplierCount = supplierMaps.length;

      // Update payable balance
      double totalPayable = 0.0;
      for (var supplierMap in supplierMaps) {
        totalPayable += (supplierMap['balance'] as num).toDouble();
      }
      _supplierPayableBalance = totalPayable;

      // Store or update the supplier balances in the supplier_balances table
      await DatabaseHelper.instance.upsertSupplierBalances(
        int.parse(_selectedBusinessId!),
        DateTime.now().toIso8601String().split('T').first,
        totalPayable,
      );

      notifyListeners();
    }
  }

  Future<void> refreshCustomerData(int customerId) async {
    // Get updated customer data from database
    final customers = await DatabaseHelper.instance
        .getCustomers(int.parse(_selectedBusinessId ?? '0'));
    final updatedCustomer = customers
        .map((map) => Customer.fromMap(map))
        .firstWhere((c) => c.id == customerId);

    // Update selected customer with new data
    if (_selectedCustomer != null && _selectedCustomer!.id == customerId) {
      _selectedCustomer = updatedCustomer;
      _selectedCustomerBalance = updatedCustomer.balance;
    }

    // Refresh transactions
    await refreshTransactions(customerId);

    // Recalculate overall balances
    await calculateBalances();

    notifyListeners();
  }

  Future<void> updateBusiness(Business business) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'businesses',
        business.toMap(),
        where: 'id = ?',
        whereArgs: [business.id],
      );

      final index = _businesses.indexWhere((b) => b.id == business.id);
      if (index != -1) {
        _businesses[index] = business;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating business: $e');
      }
      rethrow;
    }
  }
}
