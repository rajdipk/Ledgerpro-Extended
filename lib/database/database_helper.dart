//database_helper.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For UTF8 encoding
import 'package:crypto/crypto.dart'; // For hashing the password
import 'package:sqflite/sqflite.dart';
import 'dart:io'; // Added import
import 'dart:ffi';
import 'package:sqlite3/open.dart';
import '../models/inventory_batch_model.dart';
import '../models/transaction_model.dart' as my_model;
import '../models/inventory_item_model.dart'; // Import InventoryItem model
import '../models/stock_movement_model.dart'; // Import StockMovement model
import '../models/purchase_order_model.dart'; // Import PurchaseOrder model
import '../models/license_model.dart'; // Import License model

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;

    if (Platform.isWindows) {
      // Set the SQLite DLL path for Windows
      var dllPath = join(Directory.current.path, 'sqlite3.dll');
      debugPrint('Looking for SQLite DLL at: $dllPath');

      if (FileSystemEntity.isFileSync(dllPath)) {
        debugPrint('SQLite DLL found at current directory');
        open.overrideFor(OperatingSystem.windows, () {
          return DynamicLibrary.open('sqlite3.dll');
        });
      } else {
        debugPrint(
            'SQLite DLL not found in current directory, checking executable directory');
        // Try to find it in the executable's directory
        var exePath = Platform.resolvedExecutable;
        var exeDir = dirname(exePath);
        dllPath = join(exeDir, 'sqlite3.dll');

        if (FileSystemEntity.isFileSync(dllPath)) {
          debugPrint('SQLite DLL found at: $dllPath');
          open.overrideFor(OperatingSystem.windows, () {
            return DynamicLibrary.open(dllPath);
          });
        } else {
          debugPrint('SQLite DLL not found at: $dllPath');
        }
      }
    }

    _database = await _initDB('ledgerpro.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint('Database path: $path');
    debugPrint('Checking if directory exists...');

    // Ensure the directory exists
    try {
      await Directory(dbPath).create(recursive: true);
      debugPrint('Database directory created/exists');
    } catch (e) {
      debugPrint('Error creating database directory: $e');
    }

    // Version set to 1 initially, can be increased for future upgrades
    return await sqflite.openDatabase(
      path,
      version: 11, // Increased from 10 to 11 for adding business_id to transactions
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('Database opened successfully');
      },
    );
  }

  Future _createDB(sqflite.Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

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
  name $textType,
  phone TEXT,
  email TEXT,
  address TEXT,
  gstin TEXT,
  pan TEXT,
  business_type TEXT,
  created_at TEXT,
  updated_at TEXT,
  logo TEXT,
  default_currency TEXT,
  settings TEXT
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
  business_id INTEGER,
  customer_id INTEGER,
  supplier_id INTEGER,
  amount REAL,
  date TEXT,
  balance REAL, 
  notes TEXT,
  reference_type TEXT,
  reference_id INTEGER,
  FOREIGN KEY (business_id) REFERENCES businesses(id),
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
    // Create inventory items table
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
        selling_price REAL NOT NULL, 
        cost_price REAL NOT NULL,
        weighted_average_cost REAL NOT NULL,
        gst_rate REAL NOT NULL DEFAULT 0,
        current_stock INTEGER NOT NULL DEFAULT 0,
        reorder_level INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (business_id) REFERENCES businesses(id)
      );
    ''');
    // Create inventory batches table
    await db.execute('''
      CREATE TABLE inventory_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        reference_type TEXT,
        reference_id INTEGER,
        FOREIGN KEY (item_id) REFERENCES inventory_items(id)
      );
    ''');
    // Create stock movements table
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
    // Create purchase orders table
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
    // Create purchase order items table
    await db.execute('''
      CREATE TABLE purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_order_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        received_quantity INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
        FOREIGN KEY (item_id) REFERENCES inventory_items(id)
      );
    ''');

    // Create bills table
    await db.execute('''
CREATE TABLE bills (
  id $idType,
  business_id INTEGER NOT NULL,
  customer_id INTEGER NOT NULL,
  sub_total REAL NOT NULL,
  gst_amount REAL NOT NULL,
  discount REAL NOT NULL,
  total REAL NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  paid_at TEXT,
  notes TEXT,
  delivery_charge REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
)
''');

    // Create bill_items table
    await db.execute('''
CREATE TABLE bill_items (
  id $idType,
  bill_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  gst_rate REAL NOT NULL,
  notes TEXT,
  FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES inventory_items (id) ON DELETE CASCADE
)
''');

    // Create licenses table
    await db.execute('''
CREATE TABLE licenses (
  id $idType,
  license_key $textType,
  license_type $textType,
  activation_date $textType,
  expiry_date $textNullable,
  features TEXT,
  customer_id $textNullable,
  customer_email $textNullable,
  last_validated_at $textNullable,
  offline_grace_period_start $textNullable
)
''');

    // Create license usage table
    await db.execute('''
CREATE TABLE license_usage (
  id $idType,
  license_id INTEGER,
  feature_type $textType,
  usage_count INTEGER DEFAULT 0,
  period_start $textType,
  period_end $textType,
  FOREIGN KEY (license_id) REFERENCES licenses(id)
)
''');

    // Create transaction tracking table
    await db.execute('''
    CREATE TABLE transaction_tracking (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_id INTEGER NOT NULL,
      transaction_type TEXT NOT NULL,
      count INTEGER NOT NULL DEFAULT 0,
      period_start TIMESTAMP NOT NULL,
      period_end TIMESTAMP NOT NULL,
      FOREIGN KEY (license_id) REFERENCES licenses (id)
    )
    ''');

    // Create usage tracking table
    await db.execute('''
    CREATE TABLE usage_tracking (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_id INTEGER NOT NULL,
      feature_type TEXT NOT NULL,
      count INTEGER NOT NULL DEFAULT 0,
      last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (license_id) REFERENCES licenses (id)
    )
    ''');
  }

  Future<void> _onUpgrade(
      sqflite.Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 6) {
      try {
        // Drop and recreate the businesses table
        await db.execute('DROP TABLE IF EXISTS businesses');

        // Create the new businesses table with all columns
        await db.execute('''
CREATE TABLE businesses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  gstin TEXT,
  pan TEXT,
  business_type TEXT,
  created_at TEXT,
  updated_at TEXT,
  logo TEXT,
  default_currency TEXT,
  settings TEXT
)
''');
        debugPrint('Successfully recreated businesses table');
      } catch (e, stackTrace) {
        debugPrint('Error upgrading database: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    }

    if (oldVersion < 7) {
      // Add delivery_charge column to bills table
      await db.execute('''
        ALTER TABLE bills ADD COLUMN delivery_charge REAL NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 8) {
      // Add gst_rate column to inventory_items table
      await db.execute('''
        ALTER TABLE inventory_items ADD COLUMN gst_rate REAL NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 9) {
      // Add license table in upgrade
      await db.execute('''
CREATE TABLE IF NOT EXISTS license (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  license_key TEXT NOT NULL,
  license_type TEXT NOT NULL,
  activation_date TEXT NOT NULL,
  expiry_date TEXT,
  features TEXT NOT NULL
)
''');
    }

    if (oldVersion < 10) {
      // Add usage tracking table
      await db.execute('''
    CREATE TABLE IF NOT EXISTS usage_tracking (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_id INTEGER NOT NULL,
      feature_type TEXT NOT NULL,
      count INTEGER NOT NULL DEFAULT 0,
      last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (license_id) REFERENCES licenses (id)
    )
    ''');

    // Add transaction tracking table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS transaction_tracking (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_id INTEGER NOT NULL,
      transaction_type TEXT NOT NULL,
      count INTEGER NOT NULL DEFAULT 0,
      period_start TIMESTAMP NOT NULL,
      period_end TIMESTAMP NOT NULL,
      FOREIGN KEY (license_id) REFERENCES licenses (id)
    )
    ''');

    // Add license table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS licenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      license_key TEXT NOT NULL,
      license_type TEXT NOT NULL,
      customer_id TEXT NOT NULL,
      customer_email TEXT NOT NULL,
      activation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expiry_date TIMESTAMP,
      is_active INTEGER NOT NULL DEFAULT 1,
      features TEXT NOT NULL,
      last_validated_at TIMESTAMP,
      offline_grace_period_start TIMESTAMP
    )
    ''');
    }

    if (oldVersion < 11) {
      // Add business_id column to transactions table
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN business_id INTEGER REFERENCES businesses(id)');
        debugPrint('Added business_id column to transactions table');

        // Update existing transactions with business_id from their customers
        await db.execute('''
          UPDATE transactions 
          SET business_id = (
            SELECT business_id 
            FROM customers 
            WHERE customers.id = transactions.customer_id
          )
          WHERE customer_id IS NOT NULL
        ''');

        // Update transactions with business_id from their suppliers
        await db.execute('''
          UPDATE transactions 
          SET business_id = (
            SELECT business_id 
            FROM suppliers 
            WHERE suppliers.id = transactions.supplier_id
          )
          WHERE supplier_id IS NOT NULL AND business_id IS NULL
        ''');

        debugPrint('Updated existing transactions with business_id');
      } catch (e) {
        debugPrint('Error upgrading database: $e');
      }
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
  Future<int> addBusiness(Map<String, dynamic> business) async {
    try {
      debugPrint('Adding business with data: $business');
      final db = await database;

      // Remove empty id from the map
      business.remove('id');

      final id = await db.insert(
        'businesses',
        business,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      debugPrint('Business added successfully with ID: $id');
      return id;
    } catch (e, stackTrace) {
      debugPrint('Error in addBusiness: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
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
      where:
          'purchase_order_id IN (SELECT id FROM purchase_orders WHERE business_id = ?)',
      whereArgs: [id],
    );

    // Delete all bills for the business
    await db.delete(
      'bills',
      where: 'business_id = ?',
      whereArgs: [id],
    );

    // Delete all bill items for the business
    await db.delete(
      'bill_items',
      where: 'bill_id IN (SELECT id FROM bills WHERE business_id = ?)',
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
    final count = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM customers WHERE business_id = ?', [businessId]));
    return count ?? 0;
  }

  Future<int> getCustomerCount([int? businessId]) async {
    final db = await database;
    if (businessId != null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers WHERE business_id = ?',
        [businessId]
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } else {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
      return Sqflite.firstIntValue(result) ?? 0;
    }
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
    final receivableBalance =
        ((receivableResult.first['total'] as num?)?.toDouble() ?? 0.0).abs();

    // Calculate total payable (positive balances)
    final payableResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM customers
      WHERE business_id = ? AND balance > 0
    ''', [businessId]);
    final payableBalance =
        (payableResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Update or insert into customer_balances
    await upsertCustomerBalances(
      businessId,
      today,
      receivableBalance, // Store receivable as negative
      payableBalance, // Store payable as positive
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
        conflictAlgorithm:
            sqflite.ConflictAlgorithm.replace, // Handle conflicts
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
  Future<List<Map<String, dynamic>>> getSupplierTransactions(
      int supplierId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> transactions = await db.query(
      'transactions',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC, id DESC', // Order by date and id in descending order
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
      'supplier_id':
          transaction.customerId, // Using customerId field for supplierId
      'amount': transaction.amount,
      'date': transaction.date,
      'balance': transaction.balance,
      'notes': transaction.notes,
      'reference_type': transaction.referenceType,
      'reference_id': transaction.referenceId,
      'customer_id': null, // This is a supplier transaction
    });
  }

  // Update supplier transaction
  Future<int> updateSupplierTransaction(
      int id, my_model.Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {
        'amount': transaction.amount,
        'date': transaction.date,
        'balance': transaction.balance,
        'notes': transaction.notes,
        'reference_type': transaction.referenceType,
        'reference_id': transaction.referenceId,
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
  Future<int> updateSupplierBalance(
      int supplierId, int businessId, double balance) async {
    final db = await instance.database;
    return await db.update(
      'suppliers',
      {'balance': balance},
      where: 'id = ? AND business_id = ?',
      whereArgs: [supplierId, businessId],
    );
  }

  // Update supplier transaction balance
  Future<int> updateSupplierTransactionBalance(
      int transactionId, double balance) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Add supplier balances record to the database
  Future<void> addSupplierBalances(
      int businessId, String date, double payableBalance) async {
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
  Future<void> upsertSupplierBalances(
      int businessId, String date, double payableBalance,
      {sqflite.Transaction? txn}) async {
    final db = txn ?? await database;

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
      await db.insert('supplier_balances', {
        'business_id': businessId,
        'date': date,
        'payable_balance': payableBalance,
      });
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

  // Inventory Items Methods
  Future<List<InventoryItem>> getInventoryItems(int businessId) async {
    debugPrint(
        'DatabaseHelper - Getting inventory items for business: $businessId');
    final db = await database;

    // First check if any items exist at all
    final allItemsCount =
        await db.rawQuery('SELECT COUNT(*) as count FROM inventory_items');
    debugPrint(
        'DatabaseHelper - Total items in database: ${allItemsCount.first['count']}');

    // Check business IDs in the table
    final businessIds =
        await db.rawQuery('SELECT DISTINCT business_id FROM inventory_items');
    debugPrint('DatabaseHelper - Business IDs in inventory: $businessIds');

    // Get items for specific business
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_items',
      where: 'business_id = ?',
      whereArgs: [businessId],
    );
    debugPrint(
        'DatabaseHelper - Found ${maps.length} inventory items for business $businessId');
    debugPrint('DatabaseHelper - Query results: $maps');

    // Check table structure
    final tableInfo = await db.rawQuery('PRAGMA table_info(inventory_items)');
    debugPrint('DatabaseHelper - Table structure: $tableInfo');

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
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    debugPrint(
        'DatabaseHelper - Inserting inventory item with business ID: ${item.businessId}');
    final db = await database;
    await db.insert(
      'inventory_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper - Item inserted successfully');
  }

  Future<int> addInventoryItem(InventoryItem item) async {
    final db = await database;
    try {
      return await db.insert('inventory_items', item.toMap(),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    try {
      await db.update(
        'inventory_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // First check if there are any related stock movements
      final movements = await txn.query(
        'stock_movements',
        where: 'item_id = ?',
        whereArgs: [id],
      );

      if (movements.isNotEmpty) {
        throw Exception('Cannot delete item with existing stock movements');
      }

      // Check if there are any related purchase order items
      final purchaseOrderItems = await txn.query(
        'purchase_order_items',
        where: 'item_id = ?',
        whereArgs: [id],
      );

      if (purchaseOrderItems.isNotEmpty) {
        throw Exception('Cannot delete item with existing purchase orders');
      }

      // Check if there are any related bill items
      final billItems = await txn.query(
        'bill_items',
        where: 'item_id = ?',
        whereArgs: [id],
      );

      if (billItems.isNotEmpty) {
        throw Exception('Cannot delete item with existing bills');
      }

      // If no related records exist, delete the item
      await txn.delete(
        'inventory_items',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Stock Movements Methods
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

  Future<void> addStockMovement(StockMovement movement) async {
    final db = await database;
    await db.insert('stock_movements', movement.toMap());
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
  Future<List<PurchaseOrder>> getPurchaseOrders(int businessId) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'purchase_orders',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'order_date DESC, id DESC', // Added id as secondary sort
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

    if (orderMaps.isEmpty) return null;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      'purchase_order_items',
      where: 'purchase_order_id = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((m) => PurchaseOrderItem.fromMap(m)).toList();
    return PurchaseOrder.fromMap(orderMaps.first, items);
  }

  Future<int> addPurchaseOrder(PurchaseOrder order) async {
    final db = await database;

    int orderId = 0;
    // Start a transaction
    await db.transaction((txn) async {
      // Insert the purchase order first
      final orderMap = order.toMap();
      orderMap.remove('id'); // Remove id to let SQLite auto-increment
      orderId = await txn.insert('purchase_orders', orderMap);

      // Insert all purchase order items with the correct purchase_order_id
      for (var item in order.items) {
        final itemMap = item.toMap();
        itemMap.remove('id'); // Remove id to let SQLite auto-increment
        itemMap['purchase_order_id'] =
            orderId; // Set the correct purchase_order_id
        await txn.insert('purchase_order_items', itemMap);
      }
    });

    return orderId;
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
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> generatePurchaseOrderNumber(int businessId) async {
    final db = await database;

    // Get the latest order number for the business
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT order_number 
      FROM purchase_orders 
      WHERE business_id = ? 
      ORDER BY id DESC 
      LIMIT 1
    ''', [businessId]);

    if (result.isEmpty) {
      // First order for this business
      return 'PO${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}001';
    }

    final String lastOrderNumber = result.first['order_number'] as String;
    // Extract the sequence number (last 3 digits)
    final int sequence =
        int.parse(lastOrderNumber.substring(lastOrderNumber.length - 3)) + 1;
    // Create new order number with current date
    return 'PO${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${sequence.toString().padLeft(3, '0')}';
  }

  Future<Map<String, dynamic>> getBusinessProfitAndCapital(
      int businessId) async {
    final db = await database;
    final now = DateTime.now();

    try {
      // Get total receivable from customers
      final customerReceivableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM customers
        WHERE business_id = ? AND balance < 0
      ''', [businessId]);
      final customerReceivable =
          ((customerReceivableResult.first['total'] as num?)?.toDouble() ?? 0.0)
              .abs();

      // Get total payable to customers
      final customerPayableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM customers
        WHERE business_id = ? AND balance > 0
      ''', [businessId]);
      final customerPayable =
          (customerPayableResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Get total payable to suppliers
      final supplierPayableResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM suppliers
        WHERE business_id = ? AND balance != 0
      ''', [businessId]);
      final supplierPayable =
          (supplierPayableResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Calculate total capital (receivable - payable)
      final totalCapital =
          customerReceivable - (customerPayable + supplierPayable);

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

      final monthReceivable =
          (monthProfitResult.first['receivable'] as num).toDouble();
      final monthPayable =
          (monthProfitResult.first['payable'] as num).toDouble();
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

  Future<List<InventoryBatch>> getInventoryBatches(int itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_batches',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    return List.generate(maps.length, (i) => InventoryBatch.fromMap(maps[i]));
  }

  // Update purchase order item
  Future<int> updatePurchaseOrderItem(PurchaseOrderItem item) async {
    final db = await database;
    return await db.update(
      'purchase_order_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete purchase order item
  Future<int> deletePurchaseOrderItem(int itemId) async {
    final db = await database;
    return await db.delete(
      'purchase_order_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Bill-related methods
  Future<List<Map<String, dynamic>>> getBills(int businessId) async {
    debugPrint('DatabaseHelper - Getting bills for business: $businessId');
    final db = await instance.database;
    try {
      // Join with customers table and businesses table to get all details
      final List<Map<String, dynamic>> bills = await db.rawQuery('''
        SELECT 
          b.*,
          c.id as customer_id,
          c.business_id as customer_business_id,
          c.name as customer_name,
          c.phone as customer_phone,
          c.balance as customer_balance,
          c.address as customer_address,
          c.pan as customer_pan,
          c.gstin as customer_gstin,
          bus.name as business_name,
          bus.address as business_address,
          bus.phone as business_phone,
          bus.email as business_email,
          bus.gstin as business_gstin,
          bus.pan as business_pan
        FROM bills b
        LEFT JOIN customers c ON b.customer_id = c.id
        LEFT JOIN businesses bus ON b.business_id = bus.id
        WHERE b.business_id = ?
        ORDER BY b.created_at DESC
      ''', [businessId]);
      
      debugPrint('DatabaseHelper - Raw bills: $bills');
      
      // Create new list to store processed bills
      final List<Map<String, dynamic>> processedBills = [];
      
      // For each bill, create a new map with all the data
      for (final bill in bills) {
        final billId = bill['id'] as int;
        final items = await getBillItems(billId);
        
        // Create a new map for the bill
        final processedBill = Map<String, dynamic>.from(bill);
        
        // Add items
        processedBill['items'] = items;
        
        // Create customer map with proper structure
        processedBill['customer'] = {
          'id': bill['customer_id'] ?? 0,
          'business_id': bill['customer_business_id'] ?? businessId,
          'name': bill['customer_name'] ?? 'Unknown Customer',
          'phone': bill['customer_phone'] ?? '',
          'balance': bill['customer_balance'] ?? 0.0,
          'address': bill['customer_address'] ?? '',
          'pan': bill['customer_pan'] ?? '',
          'gstin': bill['customer_gstin'] ?? '',
        };

        // Create business map with proper structure
        processedBill['business'] = {
          'id': businessId,
          'name': bill['business_name'] ?? '',
          'address': bill['business_address'] ?? '',
          'phone': bill['business_phone'] ?? '',
          'email': bill['business_email'] ?? '',
          'gstin': bill['business_gstin'] ?? '',
          'pan': bill['business_pan'] ?? '',
        };
        
        // Remove redundant fields
        processedBill.remove('customer_id');
        processedBill.remove('customer_business_id');
        processedBill.remove('customer_name');
        processedBill.remove('customer_phone');
        processedBill.remove('customer_balance');
        processedBill.remove('customer_address');
        processedBill.remove('customer_pan');
        processedBill.remove('customer_gstin');
        processedBill.remove('business_name');
        processedBill.remove('business_address');
        processedBill.remove('business_phone');
        processedBill.remove('business_email');
        processedBill.remove('business_gstin');
        processedBill.remove('business_pan');
        
        processedBills.add(processedBill);
      }
      
      debugPrint('DatabaseHelper - Processed bills: $processedBills');
      return processedBills;
    } catch (e, stackTrace) {
      debugPrint('DatabaseHelper - Error getting bills: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBillItems(int billId) async {
    debugPrint('DatabaseHelper - Getting items for bill: $billId');
    final db = await instance.database;
    try {
      final items = await db.rawQuery('''
        SELECT 
          bi.id,
          bi.bill_id,
          bi.item_id,
          bi.quantity,
          bi.price,
          bi.gst_rate,
          bi.notes,
          i.business_id as item_business_id,
          i.name as item_name,
          i.description as item_description,
          i.current_stock as item_stock,
          i.unit as item_unit,
          i.selling_price as item_selling_price
        FROM bill_items bi
        LEFT JOIN inventory_items i ON bi.item_id = i.id
        WHERE bi.bill_id = ?
      ''', [billId]);
      
      debugPrint('DatabaseHelper - Raw bill items: $items');
      
      // Process items to include full item details
      final processedItems = items.map((item) {
        final processedItem = Map<String, dynamic>.from(item);
        processedItem['item'] = {
          'id': item['item_id'],
          'business_id': item['item_business_id'],
          'name': item['item_name'],
          'description': item['item_description'],
          'current_stock': item['item_stock'],
          'unit': item['item_unit'],
          'selling_price': item['item_selling_price'],
        };
        
        // Remove redundant fields
        processedItem.remove('item_id');
        processedItem.remove('item_business_id');
        processedItem.remove('item_name');
        processedItem.remove('item_description');
        processedItem.remove('item_stock');
        processedItem.remove('item_unit');
        processedItem.remove('item_selling_price');
        
        return processedItem;
      }).toList();
      
      debugPrint('DatabaseHelper - Processed bill items: $processedItems');
      return processedItems;
    } catch (e, stackTrace) {
      debugPrint('DatabaseHelper - Error getting bill items: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBill(int billId) async {
    final db = await instance.database;
    final bills = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
      limit: 1,
    );
    return bills.first;
  }

  Future<void> updateBillStatus(int billId, String status,
      {DateTime? paidAt}) async {
    final db = await instance.database;
    await db.update(
      'bills',
      {
        'status': status,
        if (paidAt != null) 'paid_at': paidAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // Get a single customer by ID
  Future<Map<String, dynamic>> getCustomer(int customerId) async {
    final db = await instance.database;
    final customers = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (customers.isEmpty) {
      throw Exception('Customer not found');
    }
    return customers.first;
  }

  // Update inventory stock
  Future<void> updateInventoryStock(int itemId, int newStock) async {
    final db = await instance.database;
    await db.update(
      'inventory_items',
      {'current_stock': newStock},
      where: 'id = ?',
      whereArgs: [itemId],
    );

    // Add a stock movement record
    await addStockMovement(
      StockMovement(
        businessId: 0, // This will be set by the calling function
        itemId: itemId,
        movementType: 'SALE',
        quantity: -newStock,
        unitPrice: 0, // This will be set by the calling function
        totalPrice: 0, // This will be set by the calling function
        date: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> receivePurchaseOrderItems(
      int orderId, List<PurchaseOrderItem> items) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // Get the order to update its status
        final List<Map<String, dynamic>> orderMaps = await txn.query(
          'purchase_orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        if (orderMaps.isEmpty) {
          throw Exception('Order not found');
        }

        // Check if order is already received
        final order = PurchaseOrder.fromMap(orderMaps.first, []);
        if (order.status == 'RECEIVED') {
          throw Exception('Order is already received');
        }

        // Update order status and received date
        await txn.update(
          'purchase_orders',
          {
            'status': 'RECEIVED',
            'received_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );

        // Process each item
        for (var item in items) {
          if (item.receivedQuantity <= 0) continue;

          // Get the current inventory item with batches
          final List<Map<String, dynamic>> itemMaps = await txn.query(
            'inventory_items',
            where: 'id = ?',
            whereArgs: [item.itemId],
          );

          if (itemMaps.isEmpty) {
            throw Exception('Inventory item not found');
          }

          final inventoryItem = InventoryItem.fromMap(itemMaps.first);

          // Create new batch for received items
          final batch = InventoryBatch(
            itemId: item.itemId,
            quantity: item.receivedQuantity,
            costPrice: item.unitPrice,
            purchaseDate: DateTime.now().toIso8601String(),
            referenceType: 'PURCHASE_ORDER',
            referenceId: orderId,
          );

          await txn.insert('inventory_batches', batch.toMap());

          // Get all batches to calculate new weighted average cost
          final List<Map<String, dynamic>> batchMaps = await txn.query(
            'inventory_batches',
            where: 'item_id = ?',
            whereArgs: [item.itemId],
          );

          final batches =
              batchMaps.map((m) => InventoryBatch.fromMap(m)).toList();
          final newItem =
              InventoryItem.fromMap(itemMaps.first, batches: batches);

          // Calculate new weighted average cost
          final newWeightedAvgCost = newItem.calculateWeightedAverageCost();
          final newStock = inventoryItem.currentStock + item.receivedQuantity;

          // Update inventory item
          await txn.update(
            'inventory_items',
            {
              'current_stock': newStock,
              'weighted_average_cost': newWeightedAvgCost,
              'cost_price': item.unitPrice, // Latest purchase price
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.itemId],
          );

          // Update purchase order item
          await txn.update(
            'purchase_order_items',
            {
              'received_quantity': item.receivedQuantity,
            },
            where: 'id = ?',
            whereArgs: [item.id],
          );

          // Create stock movement record
          await txn.insert('stock_movements', {
            'business_id': inventoryItem.businessId,
            'item_id': item.itemId,
            'movement_type': 'IN',
            'quantity': item.receivedQuantity,
            'unit_price': item.unitPrice,
            'total_price': item.unitPrice * item.receivedQuantity,
            'reference_type': 'PURCHASE_ORDER',
            'reference_id': orderId,
            'notes': 'Received from PO #$orderId',
            'date': DateTime.now().toIso8601String(),
          });
        }

        // Calculate total amount for supplier transaction
        double totalAmount = items.fold(
            0, (sum, item) => sum + (item.receivedQuantity * item.unitPrice));

        // Get supplier ID from purchase order
        final supplierId = orderMaps.first['supplier_id'] as int;
        final businessId = orderMaps.first['business_id'] as int;

        // Get current supplier balance
        final List<Map<String, dynamic>> supplierMaps = await txn.query(
          'suppliers',
          where: 'id = ?',
          whereArgs: [supplierId],
        );

        if (supplierMaps.isEmpty) {
          throw Exception('Supplier not found');
        }

        final currentBalance = supplierMaps.first['balance'] as double;
        final newBalance = currentBalance + totalAmount;

        // Create supplier transaction in transactions table
        await txn.insert('transactions', {
          'supplier_id': supplierId,
          'amount': totalAmount, // Positive amount for payable to supplier
          'date': DateTime.now().toIso8601String(),
          'notes': 'Purchase Order #$orderId received',
          'balance': newBalance,
          'reference_type': 'PURCHASE_ORDER',
          'reference_id': orderId,
          'customer_id': null, // This is a supplier transaction
          'business_id': businessId, // Add business_id
        });

        // Update supplier balance
        await txn.update(
          'suppliers',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [supplierId],
        );

        // Update supplier balances record using the transaction
        await upsertSupplierBalances(
          businessId,
          DateTime.now().toIso8601String().split('T')[0],
          newBalance,
          txn: txn,
        );
      });
    } catch (e) {
      debugPrint('Error receiving purchase order items: $e');
      rethrow;
    }
  }

  // Get current stock for an item
  Future<int> getItemStock(int itemId) async {
    final db = await database;
    final result = await db.query(
      'inventory_items',
      columns: ['current_stock'],
      where: 'id = ?',
      whereArgs: [itemId],
    );
    if (result.isEmpty) return 0;
    return result.first['current_stock'] as int;
  }

  // License management methods
  Future<void> incrementUsageCount(int licenseId, String featureType) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO usage_tracking (license_id, feature_type, count)
      VALUES (?, ?, 1)
      ON CONFLICT(license_id, feature_type) DO UPDATE SET
      count = count + 1,
      last_updated = CURRENT_TIMESTAMP
    ''', [licenseId, featureType]);
  }

  Future<int> getUsageCount(int licenseId, String featureType) async {
    final db = await database;
    final result = await db.query(
      'usage_tracking',
      columns: ['count'],
      where: 'license_id = ? AND feature_type = ?',
      whereArgs: [licenseId, featureType],
    );
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<void> incrementTransactionCount(
    int licenseId,
    String transactionType,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO transaction_tracking (
        license_id,
        transaction_type,
        count,
        period_start,
        period_end
      )
      VALUES (?, ?, 1, ?, ?)
      ON CONFLICT(license_id, transaction_type, period_start, period_end)
      DO UPDATE SET count = count + 1
    ''', [licenseId, transactionType, periodStart.toIso8601String(), periodEnd.toIso8601String()]);
  }

  Future<int> getTransactionCount(
    int licenseId,
    String transactionType,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final db = await database;
    final result = await db.query(
      'transaction_tracking',
      columns: ['count'],
      where: '''
        license_id = ? AND
        transaction_type = ? AND
        period_start = ? AND
        period_end = ?
      ''',
      whereArgs: [
        licenseId,
        transactionType,
        periodStart.toIso8601String(),
        periodEnd.toIso8601String(),
      ],
    );
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<License?> getCurrentLicense() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('licenses', orderBy: 'id DESC', limit: 1);

    if (maps.isEmpty) return null;

    final map = maps.first;
    
    // Parse features JSON string back to Map
    final featuresJson = map['features'] as String;
    final features = jsonDecode(featuresJson) as Map<String, dynamic>;
    
    return License(
      licenseKey: map['license_key'] as String,
      licenseType: LicenseType.values.firstWhere(
        (e) => e.toString().split('.').last == map['license_type']
      ),
      activationDate: DateTime.parse(map['activation_date'] as String),
      expiryDate: map['expiry_date'] != null 
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      features: features,
      customerEmail: map['customer_email'] as String?,
    );
  }

  Future<void> saveLicense(License license) async {
    final db = await database;
    
    // Convert features map to JSON string
    final featuresJson = jsonEncode(license.features);
    
    await db.insert(
      'licenses',
      {
        'license_key': license.licenseKey,
        'license_type': license.licenseType.toString().split('.').last,
        'activation_date': license.activationDate.toIso8601String(),
        'expiry_date': license.expiryDate?.toIso8601String(),
        'features': featuresJson,
        'customer_email': license.customerEmail,
        'last_validated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> updateLicense(License license) async {
    final db = await database;
    final map = license.toMap();
    map['features'] = json.encode(map['features']);
    await db.update(
      'licenses',
      map,
      where: 'id = ?',
      whereArgs: [license.id],
    );
  }

  Future<void> deleteLicense() async {
    final db = await database;
    await db.delete('licenses', where: 'is_active = 1');
  }

  Future<void> updateOfflineGracePeriod(int licenseId, DateTime? startTime) async {
    final db = await database;
    await db.update(
      'licenses',
      {'offline_grace_period_start': startTime?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [licenseId],
    );
  }

  Future<DateTime?> getOfflineGracePeriodStart(int licenseId) async {
    final db = await database;
    final result = await db.query(
      'licenses',
      columns: ['offline_grace_period_start'],
      where: 'id = ?',
      whereArgs: [licenseId],
    );

    if (result.isEmpty || result.first['offline_grace_period_start'] == null) {
      return null;
    }

    return DateTime.parse(result.first['offline_grace_period_start'] as String);
  }

  Future<void> updateLastValidatedAt(int licenseId) async {
    final db = await database;
    await db.update(
      'licenses',
      {'last_validated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [licenseId],
    );
  }

  Future<Map<String, dynamic>> exportData(int businessId) async {
    final db = await database;
    
    try {
      // Get all transactions for this business
      final transactions = await db.query(
        'transactions',
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      // Get all customers for this business
      final customers = await db.query(
        'customers',
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      // Get all suppliers for this business
      final suppliers = await db.query(
        'suppliers',
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      // Get all inventory items for this business
      final inventoryItems = await db.query(
        'inventory_items',
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      // Get all purchase orders for this business
      final purchaseOrders = await db.query(
        'purchase_orders',
        where: 'business_id = ?',
        whereArgs: [businessId],
      );

      // Get the business details
      final List<Map<String, dynamic>> businesses = await db.query(
        'businesses',
        where: 'id = ?',
        whereArgs: [businessId],
      );

      if (businesses.isEmpty) {
        throw Exception('Business not found');
      }

      // Create the backup data structure
      final backupData = {
        'version': 11,
        'timestamp': DateTime.now().toIso8601String(),
        'business': businesses.first,
        'customers': customers,
        'suppliers': suppliers,
        'transactions': transactions,
        'inventory_items': inventoryItems,
        'purchase_orders': purchaseOrders,
      };

      return _sanitizeData(backupData);
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  Future<void> importData(Map<String, dynamic> backup) async {
    final db = await database;
    
    try {
      print('Starting data import with backup data: $backup');
      
      // Convert numeric fields in the backup data
      final convertedBackup = Map<String, dynamic>.from(backup);
      _convertNumericFields(convertedBackup);
      
      print('Converted backup data: $convertedBackup');

      await db.transaction((txn) async {
        // Get the business data
        final businessData = convertedBackup['business'];
        if (businessData == null) {
          throw Exception('Business data is missing from backup');
        }
        if (businessData is! Map<String, dynamic>) {
          throw Exception('Business data is not a Map: ${businessData.runtimeType}');
        }
        
        final businessId = businessData['id'];
        if (businessId == null) {
          throw Exception('Business ID is missing');
        }

        print('Processing business data: $businessData');

        // Delete existing data for this business
        await txn.delete('transactions', where: 'business_id = ?', whereArgs: [businessId]);
        await txn.delete('customers', where: 'business_id = ?', whereArgs: [businessId]);
        await txn.delete('suppliers', where: 'business_id = ?', whereArgs: [businessId]);
        await txn.delete('inventory_items', where: 'business_id = ?', whereArgs: [businessId]);
        await txn.delete('purchase_orders', where: 'business_id = ?', whereArgs: [businessId]);
        await txn.delete('businesses', where: 'id = ?', whereArgs: [businessId]);

        // Insert the business
        await txn.insert('businesses', businessData);

        // Insert customers
        final customers = convertedBackup['customers'];
        if (customers != null) {
          if (customers is! List) {
            throw Exception('Customers data is not a List: ${customers.runtimeType}');
          }
          print('Processing ${customers.length} customers');
          for (var customer in customers) {
            if (customer is! Map<String, dynamic>) {
              print('Skipping invalid customer data: $customer');
              continue;
            }
            await txn.insert('customers', customer);
          }
        }

        // Insert suppliers
        final suppliers = convertedBackup['suppliers'];
        if (suppliers != null) {
          if (suppliers is! List) {
            throw Exception('Suppliers data is not a List: ${suppliers.runtimeType}');
          }
          print('Processing ${suppliers.length} suppliers');
          for (var supplier in suppliers) {
            if (supplier is! Map<String, dynamic>) {
              print('Skipping invalid supplier data: $supplier');
              continue;
            }
            await txn.insert('suppliers', supplier);
          }
        }

        // Insert transactions
        final transactions = convertedBackup['transactions'];
        if (transactions != null) {
          if (transactions is! List) {
            throw Exception('Transactions data is not a List: ${transactions.runtimeType}');
          }
          print('Processing ${transactions.length} transactions');
          for (var transaction in transactions) {
            if (transaction is! Map<String, dynamic>) {
              print('Skipping invalid transaction data: $transaction');
              continue;
            }
            final transactionData = Map<String, dynamic>.from(transaction);
            transactionData['business_id'] = businessId;
            await txn.insert('transactions', transactionData);
          }
        }

        // Insert inventory items
        final inventoryItems = convertedBackup['inventory_items'];
        if (inventoryItems != null) {
          if (inventoryItems is! List) {
            throw Exception('Inventory items data is not a List: ${inventoryItems.runtimeType}');
          }
          print('Processing ${inventoryItems.length} inventory items');
          for (var item in inventoryItems) {
            if (item is! Map<String, dynamic>) {
              print('Skipping invalid inventory item data: $item');
              continue;
            }
            await txn.insert('inventory_items', item);
          }
        }
      });
      
      print('Data import completed successfully');
    } catch (e, stackTrace) {
      print('Error importing data: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is List<Map<String, dynamic>>) {
      return data.map((item) => _sanitizeMap(item)).toList();
    } else if (data is Map<String, dynamic>) {
      return _sanitizeMap(data);
    }
    return data;
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    Map<String, dynamic> sanitized = {};
    map.forEach((key, value) {
      if (value is int || value is double) {
        sanitized[key] = value.toString(); // Convert numbers to strings
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  Map<String, dynamic> _convertNumericFields(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (var key in result.keys) {
      var value = result[key];
      if (value is String) {
        // Try to convert string to numeric if possible
        if (value.contains('.')) {
          final doubleValue = double.tryParse(value);
          if (doubleValue != null) {
            result[key] = doubleValue;
          }
        } else {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            result[key] = intValue;
          }
        }
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertNumericFields(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertNumericFields(item);
          }
          return item;
        }).toList();
      }
    }
    return result;
  }

  Future<int> getInventoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM inventory_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getMonthlyTransactionCount() async {
    final db = await database;
    final startOfMonth = DateTime.now().subtract(
      Duration(days: DateTime.now().day - 1)
    );
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE date >= ?',
      [startOfMonth.toIso8601String()]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
