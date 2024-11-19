//database_helper.dart

// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For UTF8 encoding
import 'package:crypto/crypto.dart'; // For hashing the password
import '../models/transaction_model.dart' as my_model;
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/purchase_order_model.dart';
// Import Supplier model

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ledgerpro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Version set to 1 initially, can be increased for future upgrades
    return await openDatabase(path,
        version: 4, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE user_password (
  id $idType,
  password $textType
)
''');
    // Create businesses table
    await db.execute('''
CREATE TABLE businesses (
  id $idType,
  name $textType
);
''');
    // Create customers table
    await db.execute('''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  pan TEXT NOT NULL,
  gstin TEXT NOT NULL,
  balance REAL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);
''');
// Create transactions table
    await db.execute('''
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER,
  supplier_id INTEGER,
  amount REAL,
  date TEXT,
  balance REAL, 
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
''');
// create customer balances
    await db.execute('''
CREATE TABLE customer_balances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER,
  date TEXT,
  receivable_balance REAL,
  payable_balance REAL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);
''');
// Create supplier balances
    await db.execute('''
CREATE TABLE supplier_balances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER,
  date TEXT,
  payable_balance REAL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);
''');
// Create suppliers table
    await db.execute('''
  CREATE TABLE suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    business_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    pan TEXT,
    gstin TEXT,
    balance REAL DEFAULT 0,
    FOREIGN KEY (business_id) REFERENCES businesses(id)
  );
  ''');
    // Create supplier transactions table
    await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        balance REAL NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
      );
    ''');

    // Create inventory_items table
    await db.execute('''
CREATE TABLE inventory_items (
  id $idType,
  business_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  sku TEXT,
  barcode TEXT,
  category TEXT,
  unit TEXT NOT NULL,
  unit_price REAL NOT NULL,
  cost_price REAL NOT NULL,
  current_stock INTEGER NOT NULL DEFAULT 0,
  reorder_level INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);
''');

    // Create stock_movements table
    await db.execute('''
CREATE TABLE stock_movements (
  id $idType,
  business_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  movement_type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  reference_type TEXT,
  reference_id INTEGER,
  notes TEXT,
  date TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);
''');

    // Create purchase_orders table
    await db.execute('''
CREATE TABLE purchase_orders (
  id $idType,
  business_id INTEGER NOT NULL,
  supplier_id INTEGER NOT NULL,
  order_number TEXT NOT NULL,
  status TEXT NOT NULL,
  total_amount REAL NOT NULL,
  notes TEXT,
  order_date TEXT NOT NULL,
  expected_date TEXT,
  received_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
''');

    // Create purchase_order_items table
    await db.execute('''
CREATE TABLE purchase_order_items (
  id $idType,
  purchase_order_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  received_quantity INTEGER DEFAULT 0,
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop the old suppliers table
      await db.execute('DROP TABLE IF EXISTS suppliers');
      
      // Create the new suppliers table with updated schema
      await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        pan TEXT,
        gstin TEXT,
        balance REAL DEFAULT 0,
        FOREIGN KEY (business_id) REFERENCES businesses(id)
      );
      ''');
    }
    if (oldVersion < 3) {
      // Add supplier transactions table
      await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        balance REAL NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
      );
      ''');
    }
    if (oldVersion < 4) {
      // Create inventory_items table
      await db.execute('''
CREATE TABLE inventory_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  sku TEXT,
  barcode TEXT,
  category TEXT,
  unit TEXT NOT NULL,
  unit_price REAL NOT NULL,
  cost_price REAL NOT NULL,
  current_stock INTEGER NOT NULL DEFAULT 0,
  reorder_level INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);
''');

      // Create stock_movements table
      await db.execute('''
CREATE TABLE stock_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  movement_type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  reference_type TEXT,
  reference_id INTEGER,
  notes TEXT,
  date TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);
''');

      // Create purchase_orders table
      await db.execute('''
CREATE TABLE purchase_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  business_id INTEGER NOT NULL,
  supplier_id INTEGER NOT NULL,
  order_number TEXT NOT NULL,
  status TEXT NOT NULL,
  total_amount REAL NOT NULL,
  notes TEXT,
  order_date TEXT NOT NULL,
  expected_date TEXT,
  received_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
''');

      // Create purchase_order_items table
      await db.execute('''
CREATE TABLE purchase_order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  purchase_order_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  received_quantity INTEGER DEFAULT 0,
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);
''');
    }
  }

  Future<bool> isPasswordSet() async {
    final db = await instance.database;
    final maps = await db.query('user_password');
    return maps.isNotEmpty;
  }

  Future<void> setPassword(String password) async {
    final db = await instance.database;

    // Hash the password before storing it
    final hashedPassword = _hashPassword(password);

    await db.insert('user_password', {
      'password': hashedPassword,
    });
  }

  Future<bool> checkPassword(String password) async {
    final db = await instance.database;

    // Hash the provided password for comparison
    final hashedPassword = _hashPassword(password);

    final maps = await db.query(
      'user_password',
      columns: ['password'],
      where: 'password = ?',
      whereArgs: [hashedPassword],
    );

    return maps.isNotEmpty;
  }

  // Helper method to hash the password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final hashed = sha256.convert(bytes); // Hash the password using SHA-256
    return hashed.toString(); // Convert the hash to a string for storage
  }

  // Add a business to the database
  Future<int> addBusiness(String name) async {
    final db = await database;
    int id = await db.insert(
      'businesses',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // Retrieve all businesses
  Future<List<Map<String, dynamic>>> getBusinesses() async {
    final db = await database;
    return await db.query('businesses');
  }

  // Delete a business
  Future<void> deleteBusiness(int id) async {
    final db = await database;

    // First, get all customer ids for the business
    final List<Map<String, dynamic>> customerMaps = await db.query(
      'customers',
      columns: ['id'],
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Extract customer ids
    final List<int> customerIds =
        customerMaps.map((customer) => customer['id'] as int).toList();

    // Delete all transactions for each customer
    for (final customerId in customerIds) {
      await db.delete(
        'transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    }

    // Delete all customers for the business
    await db.delete(
      'customers',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all suppliers for the business
    await db.delete(
      'suppliers',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all customer_balances for the business
    await db.delete(
      'customer_balances',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all supplier_balances for the business
    await db.delete(
      'supplier_balances',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all inventory items for the business
    await db.delete(
      'inventory_items',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all stock movements for the business
    await db.delete(
      'stock_movements',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all purchase orders for the business
    await db.delete(
      'purchase_orders',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all purchase order items for the business
    await db.delete(
      'purchase_order_items',
      where: 'purchase_order_id IN (SELECT id FROM purchase_orders WHERE business_id = ?)',
      whereArgs: [id],
    );

    // Finally, delete the business
    await db.delete(
      'businesses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Add a customer to the database
  Future<void> addCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.insert('customers', customer);
  }

  // Retrieve all customers for a specific business
  Future<List<Map<String, dynamic>>> getCustomers(int businessId) async {
    final db = await database;
    return await db
        .query('customers', where: 'business_id = ?', whereArgs: [businessId]);
  }

  // Delete a customer
  Future<void> deleteCustomer(int id, int businessId) async {
    final db = await database;
    await db.delete(
      'customers',
      where: 'id = ? AND business_id = ?',
      whereArgs: [id, businessId],
    );
  }

  // Method to get the count of customers for a specific business
  Future<int> getCustomerCountForBusiness(int businessId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM customers WHERE business_id = ?', [businessId]));
    return count ?? 0;
  }

  // Update customer balance
  Future<void> updateCustomerBalance(
      int id, int businessId, double newBalance) async {
    final db = await database;
    await db.update(
      'customers',
      {'balance': newBalance},
      where: 'id = ? AND business_id = ?',
      whereArgs: [id, businessId],
    );
  }

  //method to fetch the last transaction date
  Future<String?> getLastTransactionDate(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: ['date'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['date'] as String;
    } else {
      return null;
    }
  }

  // Other customer-related methods...

  // Add a method to add a transaction to the database
  Future<void> addTransaction(my_model.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  // Retrieve transactions
  Future<List<Map<String, dynamic>>> getTransactions(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> transactions = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );

    // Convert the amount to double for each transaction
    for (var transaction in transactions) {
      if (transaction['amount'] is String) {
        // If it's a string, try parsing it
        transaction['amount'] = double.tryParse(transaction['amount']) ?? 0.0;
      }
    }
    // Create a mutable list of maps to ensure no read-only error occurs
    return transactions
        .map((transaction) => Map<String, dynamic>.from(transaction))
        .toList();
  }

  Future<Map<String, dynamic>?> getTransactionById(int transactionId) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1, // Limit to 1 as we are fetching by ID
    );

    if (result.isNotEmpty) {
      final transaction = result.first;

      // Convert the 'amount' field to double if it's stored as a string
      if (transaction['amount'] is String) {
        transaction['amount'] = double.tryParse(transaction['amount']) ?? 0.0;
      }

      return transaction;
    }

    return null; // Return null if no transaction is found with the given ID
  }

  // Method to fetch all transactions after a given transaction ID
  Future<List<Map<String, dynamic>>> getTransactionsAfterId(
      int customerId, int transactionId) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'customer_id = ? AND id > ?',
      whereArgs: [customerId, transactionId],
    );
  }


  Future<double?> getLastTransactionBalance(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: ['balance'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['balance'] as double?;
    } else {
      return null;
    }
  }

  Future<double?> getLastTransactionBalanceForUpdate(
      int customerId, int transactionId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT balance FROM transactions WHERE customer_id = ? AND id < ? ORDER BY date DESC LIMIT 1',
      [customerId, transactionId],
    );

    if (result.isNotEmpty) {
      return result.first['balance'] as double?;
    } else {
      return null; // No previous balance found
    }
  }


  // Update a transaction balance
  Future<void> updateTransactionBalance(
      int transactionId, double newBalance) async {
    final db = await database;
    await db.update(
      'transactions',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Updating a transaction
  Future<void> updateTransaction(
      int transactionId, my_model.Transaction updatedTransaction) async {
    final db = await database;
    await db.update(
      'transactions',
      updatedTransaction.toMap(),
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Delete a transaction
  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Delete transactions for a specific customer
  Future<void> deleteTransactionsForCustomer(int customerId) async {
    final db = await instance.database;
    await db.delete(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Retrieve customer balances for a specific business
  Future<List<Map<String, dynamic>>> getCustomerBalances(int businessId) async {
    final db = await database;
    return await db.query(
      'customer_balances',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'date DESC',
    );
  }

  // Calculate and update customer balances
  Future<void> calculateAndUpdateCustomerBalances(int businessId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Calculate total receivable (negative balances)
    final receivableResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM customers
      WHERE business_id = ? AND balance < 0
    ''', [businessId]);
    final receivableBalance = ((receivableResult.first['total'] as num?)?.toDouble() ?? 0.0).abs();

    // Calculate total payable (positive balances)
    final payableResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM customers
      WHERE business_id = ? AND balance > 0
    ''', [businessId]);
    final payableBalance = (payableResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Update or insert into customer_balances
    await upsertCustomerBalances(
      businessId,
      today,
      receivableBalance,  // Store receivable as negative
      payableBalance,     // Store payable as positive
    );
  }

  // A method to handle upserting (update or insert) the balance data
  Future<void> upsertCustomerBalances(int businessId, String date,
      double receivableBalance, double payableBalance) async {
    final db = await database;

    // Check if an entry for the given date already exists
    final existingEntries = await db.query(
      'customer_balances',
      where: 'business_id = ? AND date = ?',
      whereArgs: [businessId, date],
    );

    if (existingEntries.isNotEmpty) {
      // Update existing entry
      await db.update(
        'customer_balances',
        {
          'receivable_balance': receivableBalance,
          'payable_balance': payableBalance,
        },
        where: 'business_id = ? AND date = ?',
        whereArgs: [businessId, date],
      );
    } else {
      // Insert new entry
      await db.insert(
        'customer_balances',
        {
          'business_id': businessId,
          'date': date,
          'receivable_balance': receivableBalance,
          'payable_balance': payableBalance,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Handle conflicts
      );
    }
  }

  Future<Map<String, double>> getTotalTransactionsForDay(
      int businessId, String date) async {
    final db = await database;

    final startOfDay = '$date 00:00:00';
    final endOfDay = '$date 23:59:59';

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalReceived
      FROM transactions
      WHERE customer_id IN (
        SELECT id FROM customers WHERE business_id = ?
      ) AND date BETWEEN ? AND ?
    ''', [businessId, startOfDay, endOfDay]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching total transactions for day: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  Future<Map<String, double>> getTotalTransactionsForWeek(
      int businessId) async {
    final db = await database;

    final now = DateTime.now();
    final startOfWeek =
        DateTime(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek =
        DateTime(now.year, now.month, now.day + (7 - now.weekday));

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalReceived
      FROM transactions
      WHERE customer_id IN (
        SELECT id FROM customers WHERE business_id = ?
      ) AND date BETWEEN ? AND ?
    ''', [
        businessId,
        DateFormat('yyyy-MM-dd').format(startOfWeek),
        DateFormat('yyyy-MM-dd').format(endOfWeek)
      ]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching total transactions for week: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  Future<Map<String, double>> getTotalTransactionsForMonth(
      int businessId, int month, int year) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalReceived
      FROM transactions
      WHERE customer_id IN (
        SELECT id FROM customers WHERE business_id = ?
      ) AND date BETWEEN ? AND ?
    ''', [
        businessId,
        DateFormat('yyyy-MM-dd').format(startOfMonth),
        DateFormat('yyyy-MM-dd').format(endOfMonth)
      ]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching total transactions for month: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  // Get suppliers for a business
  Future<List<Map<String, dynamic>>> getSuppliers(int businessId) async {
    final db = await database;
    return await db.query(
      'suppliers',
      where: 'business_id = ?',
      whereArgs: [businessId],
    );
  }

  // Get last supplier transaction date
  Future<String?> getLastSupplierTransactionDate(int supplierId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: ['date'],
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['date'] as String;
    } else {
      return null;
    }
  }

  // Get supplier transactions
  Future<List<Map<String, dynamic>>> getSupplierTransactions(int supplierId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> transactions = await db.query(
      'transactions',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC, id DESC',  // Order by date and id in descending order
    );

    // Convert the amount to double for each transaction
    for (var transaction in transactions) {
      if (transaction['amount'] is String) {
        transaction['amount'] = double.tryParse(transaction['amount']) ?? 0.0;
      }
    }
    return transactions
        .map((transaction) => Map<String, dynamic>.from(transaction))
        .toList();
  }

  // Get last supplier transaction balance
  Future<double?> getLastSupplierTransactionBalance(int supplierId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: ['balance'],
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['balance'] as double?;
    }
    return null;
  }

  // Add supplier transaction
  Future<int> addSupplierTransaction(my_model.Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', {
      'supplier_id': transaction.customerId, // Using customerId field for supplierId
      'amount': transaction.amount,
      'date': transaction.date,
      'balance': transaction.balance,
    });
  }

  // Update supplier transaction
  Future<int> updateSupplierTransaction(int id, my_model.Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {
        'amount': transaction.amount,
        'date': transaction.date,
        'balance': transaction.balance,
      },
      where: 'id = ? AND supplier_id = ?',
      whereArgs: [id, transaction.customerId],
    );
  }

  // Delete supplier transaction
  Future<int> deleteSupplierTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update supplier balance
  Future<int> updateSupplierBalance(int supplierId, int businessId, double balance) async {
    final db = await instance.database;
    return await db.update(
      'suppliers',
      {'balance': balance},
      where: 'id = ? AND business_id = ?',
      whereArgs: [supplierId, businessId],
    );
  }

  // Update supplier transaction balance
  Future<int> updateSupplierTransactionBalance(int transactionId, double balance) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Add supplier balances record to the database
  Future<void> addSupplierBalances(int businessId, String date, double payableBalance) async {
    final db = await database;
    await db.insert('supplier_balances', {
      'business_id': businessId,
      'date': date,
      'payable_balance': payableBalance,
    });
  }

  // Retrieve supplier balances for a specific business
  Future<List<Map<String, dynamic>>> getSupplierBalances(int businessId) async {
    final db = await database;
    return await db.query(
      'supplier_balances',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'date ASC',
    );
  }

  // A method to handle upserting (update or insert) the supplier balance data
  Future<void> upsertSupplierBalances(int businessId, String date, double payableBalance) async {
    final db = await database;

    // Check if an entry for the given date already exists
    final existingEntries = await db.query(
      'supplier_balances',
      where: 'business_id = ? AND date = ?',
      whereArgs: [businessId, date],
    );

    if (existingEntries.isNotEmpty) {
      // Update existing entry
      await db.update(
        'supplier_balances',
        {
          'payable_balance': payableBalance,
        },
        where: 'business_id = ? AND date = ?',
        whereArgs: [businessId, date],
      );
    } else {
      // Insert new entry
      await db.insert(
        'supplier_balances',
        {
          'business_id': businessId,
          'date': date,
          'payable_balance': payableBalance,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, double>> getSupplierTotalTransactionsForDay(
      int businessId, String date) async {
    final db = await database;

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN t.amount < 0 THEN t.amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as totalReceived
      FROM transactions t
      INNER JOIN suppliers s ON t.supplier_id = s.id
      WHERE s.business_id = ? 
      AND date(t.date) = date(?)
    ''', [businessId, date]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching supplier total transactions for day: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  Future<Map<String, double>> getSupplierTotalTransactionsForWeek(
      int businessId) async {
    final db = await database;

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek = DateTime(now.year, now.month, now.day + (7 - now.weekday));

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalReceived
      FROM transactions
      WHERE supplier_id IN (
        SELECT id FROM suppliers WHERE business_id = ?
      ) AND date BETWEEN ? AND ?
    ''', [
        businessId,
        DateFormat('yyyy-MM-dd').format(startOfWeek),
        DateFormat('yyyy-MM-dd').format(endOfWeek)
      ]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching supplier total transactions for week: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  Future<Map<String, double>> getSupplierTotalTransactionsForMonth(
      int businessId, int month, int year) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    try {
      final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as totalGiven,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalReceived
      FROM transactions
      WHERE supplier_id IN (
        SELECT id FROM suppliers WHERE business_id = ?
      ) AND date BETWEEN ? AND ?
    ''', [
        businessId,
        DateFormat('yyyy-MM-dd').format(startOfMonth),
        DateFormat('yyyy-MM-dd').format(endOfMonth)
      ]);

      final row = result.isNotEmpty ? result.first : {};
      return {
        'totalGiven': (row['totalGiven'] as num?)?.toDouble() ?? 0.0,
        'totalReceived': (row['totalReceived'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching supplier total transactions for month: $e');
      return {'totalGiven': 0.0, 'totalReceived': 0.0};
    }
  }

  Future<Map<String, double>> getBusinessProfitAndCapital(int businessId) async {
    final db = await database;
    final now = DateTime.now();
    
    try {
      // Get total receivable from customers
      final customerReceivableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM customers
        WHERE business_id = ? AND balance < 0
      ''', [businessId]);
      final customerReceivable = ((customerReceivableResult.first['total'] as num?)?.toDouble() ?? 0.0).abs();

      // Get total payable to customers
      final customerPayableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM customers
        WHERE business_id = ? AND balance > 0
      ''', [businessId]);
      final customerPayable = (customerPayableResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Get total payable to suppliers
      final supplierPayableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM suppliers
        WHERE business_id = ? AND balance != 0
      ''', [businessId]);
      final supplierPayable = (supplierPayableResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Calculate total capital (receivable - payable)
      final totalCapital = customerReceivable - (customerPayable + supplierPayable);

      // Get this month's transactions
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Calculate this month's profit
      final monthProfitResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) as receivable,
          COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as payable
        FROM transactions
        WHERE (customer_id IN (
          SELECT id FROM customers WHERE business_id = ?
        ) OR supplier_id IN (
          SELECT id FROM suppliers WHERE business_id = ?
        ))
        AND date BETWEEN ? AND ?
      ''', [
        businessId,
        businessId,
        DateFormat('yyyy-MM-dd').format(startOfMonth),
        DateFormat('yyyy-MM-dd').format(endOfMonth)
      ]);

      final monthReceivable = (monthProfitResult.first['receivable'] as num).toDouble();
      final monthPayable = (monthProfitResult.first['payable'] as num).toDouble();
      final monthlyProfit = monthReceivable - monthPayable;

      return {
        'totalCapital': totalCapital,
        'monthlyProfit': monthlyProfit,
      };
    } catch (e) {
      print('Error calculating business profit and capital: $e');
      return {
        'totalCapital': 0.0,
        'monthlyProfit': 0.0,
      };
    }
  }

  // Debug method to verify transactions
  Future<List<Map<String, dynamic>>> verifyTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  // Inventory Items Methods
  Future<InventoryItem> addInventoryItem(InventoryItem item) async {
    final db = await database;
    final id = await db.insert('inventory_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<InventoryItem>> getInventoryItems(int businessId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_items',
      where: 'business_id = ?',
      whereArgs: [businessId],
    );
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.update(
      'inventory_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await database;
    await db.delete(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Stock Movements Methods
  Future<StockMovement> addStockMovement(StockMovement movement) async {
    final db = await database;
    
    // Start a transaction
    await db.transaction((txn) async {
      // Insert the movement
      final id = await txn.insert('stock_movements', movement.toMap());
      
      // Update the inventory item's current stock
      final item = await getInventoryItem(movement.itemId);
      if (item != null) {
        final newStock = movement.movementType == 'IN'
            ? item.currentStock + movement.quantity
            : item.currentStock - movement.quantity;
        
        await txn.update(
          'inventory_items',
          {'current_stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [movement.itemId],
        );
      }
      
      movement = movement.copyWith(id: id);
    });
    
    return movement;
  }

  Future<List<StockMovement>> getStockMovements(int businessId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  Future<List<StockMovement>> getItemStockMovements(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => StockMovement.fromMap(maps[i]));
  }

  // Purchase Orders Methods
  Future<PurchaseOrder> addPurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    
    // Start a transaction
    await db.transaction((txn) async {
      // Insert the purchase order
      final orderId = await txn.insert('purchase_orders', order.toMap());
      
      // Insert all purchase order items
      for (var item in order.items) {
        await txn.insert('purchase_order_items', {
          ...item.toMap(),
          'purchase_order_id': orderId,
        });
      }
      
      order = order.copyWith(id: orderId);
    });
    
    return order;
  }

  Future<List<PurchaseOrder>> getPurchaseOrders(int businessId) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'purchase_orders',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'order_date DESC',
    );

    return Future.wait(orderMaps.map((orderMap) async {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'purchase_order_items',
        where: 'purchase_order_id = ?',
        whereArgs: [orderMap['id']],
      );
      final items = itemMaps.map((m) => PurchaseOrderItem.fromMap(m)).toList();
      return PurchaseOrder.fromMap(orderMap, items);
    }));
  }

  Future<PurchaseOrder?> getPurchaseOrder(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (orderMaps.isNotEmpty) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'purchase_order_items',
        where: 'purchase_order_id = ?',
        whereArgs: [id],
      );
      final items = itemMaps.map((m) => PurchaseOrderItem.fromMap(m)).toList();
      return PurchaseOrder.fromMap(orderMaps.first, items);
    }
    return null;
  }

  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    
    // Start a transaction
    await db.transaction((txn) async {
      // Update the purchase order
      await txn.update(
        'purchase_orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
      
      // Delete existing items
      await txn.delete(
        'purchase_order_items',
        where: 'purchase_order_id = ?',
        whereArgs: [order.id],
      );
      
      // Insert updated items
      for (var item in order.items) {
        await txn.insert('purchase_order_items', {
          ...item.toMap(),
          'purchase_order_id': order.id,
        });
      }
    });
  }

  Future<void> deletePurchaseOrder(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete purchase order items first
      await txn.delete(
        'purchase_order_items',
        where: 'purchase_order_id = ?',
        whereArgs: [id],
      );
      
      // Delete the purchase order
      await txn.delete(
        'purchase_orders',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updatePurchaseOrderStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'purchase_orders',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'RECEIVED') 'received_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> receivePurchaseOrderItems(int orderId, List<PurchaseOrderItem> items) async {
    final db = await database;
    
    // Start a transaction
    await db.transaction((txn) async {
      for (var item in items) {
        // Update received quantity in purchase_order_items
        await txn.update(
          'purchase_order_items',
          {'received_quantity': item.receivedQuantity},
          where: 'id = ?',
          whereArgs: [item.id],
        );
        
        // Create stock movement for received items
        if (item.receivedQuantity > 0) {
          await txn.insert('stock_movements', StockMovement(
            businessId: (await getPurchaseOrder(orderId))!.businessId,
            itemId: item.itemId,
            movementType: 'IN',
            quantity: item.receivedQuantity,
            unitPrice: item.unitPrice,
            totalPrice: item.unitPrice * item.receivedQuantity,
            referenceType: 'PURCHASE_ORDER',
            referenceId: orderId,
            date: DateTime.now().toIso8601String(),
          ).toMap());
          
          // Update inventory item stock
          final inventoryItem = await getInventoryItem(item.itemId);
          if (inventoryItem != null) {
            await txn.update(
              'inventory_items',
              {
                'current_stock': inventoryItem.currentStock + item.receivedQuantity,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [item.itemId],
            );
          }
        }
      }
    });
  }
}
