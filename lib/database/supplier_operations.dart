// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import '../models/supplier_model.dart';
import '../models/transaction_model.dart' as my_model;
import 'database_helper.dart';

class SupplierOperations {
  final DatabaseHelper _databaseHelper;

  SupplierOperations(this._databaseHelper);

  Future<Database> get database async => await _databaseHelper.database;

  Future<Supplier> addSupplier(Supplier supplier) async {
    final db = await database;
    final id = await db.insert('suppliers', supplier.toMap());
    return supplier.copyWith(id: id);
  }

  Future<List<Supplier>> getSuppliers(int businessId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: 'business_id = ?',
      whereArgs: [businessId],
    );
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  Future<Supplier?> getSupplierById(int supplierId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [supplierId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getSupplierBalance(int supplierId, {Transaction? txn}) async {
    final db = txn ?? await database;
    final result = await db.query(
      'suppliers',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [supplierId],
    );
    if (result.isNotEmpty) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }

  Future<List<my_model.Transaction>> getSupplierTransactions(
      int supplierId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return my_model.Transaction(
        id: maps[i]['id'] as int,
        supplierId: maps[i]['supplier_id'] as int,
        amount: maps[i]['amount'] as double,
        date: maps[i]['date'] as String,
        balance: maps[i]['balance'] as double,
      );
    });
  }

  Future<int> addSupplierTransaction(my_model.Transaction transaction) async {
    if (transaction.supplierId == null) {
      throw Exception('Supplier ID cannot be null');
    }
    if (transaction.businessId == null) {
      throw Exception('Business ID cannot be null');
    }

    final db = await database;

    // Start a transaction to ensure data consistency
    return await db.transaction((txn) async {
      // Get current supplier balance
      final currentBalance =
          await getSupplierBalance(transaction.supplierId!, txn: txn);

      // Calculate new balance
      final newBalance = currentBalance + transaction.amount;

      // Insert transaction
      final transactionId = await txn.insert(
        'transactions',
        {
          'supplier_id': transaction.supplierId,
          'business_id': transaction.businessId,
          'customer_id': null,
          'amount': transaction.amount,
          'date': transaction.date,
          'balance': newBalance,
        },
      );

      // Update supplier balance
      await txn.update(
        'suppliers',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [transaction.supplierId],
      );

      return transactionId;
    });
  }

  Future<void> updateSupplierTransaction(
      my_model.Transaction transaction) async {
    if (transaction.id == null || transaction.supplierId == null) {
      throw Exception('Transaction ID and Supplier ID cannot be null');
    }

    final db = await database;
    await db.transaction((txn) async {
      // Update the transaction
      await txn.update(
        'transactions',
        {
          'amount': transaction.amount,
          'date': transaction.date,
        },
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Recalculate balances for all transactions after this one
      await _recalculateBalances(transaction.supplierId!, transaction.id!, txn);
    });
  }

  Future<void> deleteSupplierTransaction(
      int transactionId, int supplierId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete the transaction
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // Recalculate balances for all transactions after this one
      await _recalculateBalances(supplierId, transactionId, txn);
    });
  }

  Future<void> _recalculateBalances(
      int supplierId, int fromTransactionId, Transaction txn) async {
    // Get all transactions after the given transaction ID
    final List<Map<String, dynamic>> subsequentTransactions = await txn.query(
      'transactions',
      where: 'supplier_id = ? AND id >= ?',
      whereArgs: [supplierId, fromTransactionId],
      orderBy: 'date ASC',
    );

    double runningBalance = 0;
    // Get the balance from the last transaction before this one
    final previousTransactions = await txn.query(
      'transactions',
      where: 'supplier_id = ? AND id < ?',
      whereArgs: [supplierId, fromTransactionId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (previousTransactions.isNotEmpty) {
      runningBalance = previousTransactions.first['balance'] as double;
    }

    // Update balances for all subsequent transactions
    for (var transaction in subsequentTransactions) {
      runningBalance += transaction['amount'] as double;
      await txn.update(
        'transactions',
        {'balance': runningBalance},
        where: 'id = ?',
        whereArgs: [transaction['id']],
      );
    }

    // Update supplier's balance
    await txn.update(
      'suppliers',
      {'balance': runningBalance},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  Future<void> recalculateSupplierBalance(int supplierId) async {
    final db = await database;

    await db.transaction((txn) async {
      // Get all transactions for the supplier
      final transactions = await txn.query(
        'transactions',
        where: 'supplier_id = ?',
        whereArgs: [supplierId],
        orderBy: 'date ASC',
      );

      double balance = 0.0;

      // Recalculate balance for each transaction
      for (final transaction in transactions) {
        balance += transaction['amount'] as double;
        await txn.rawUpdate(
          'UPDATE transactions SET balance = ? WHERE id = ?',
          [balance, transaction['id']],
        );
      }

      // Update supplier balance
      await txn.rawUpdate(
        'UPDATE suppliers SET balance = ? WHERE id = ?',
        [balance, supplierId],
      );
    });
  }

  // Test method to verify supplier transactions
  Future<void> testSupplierTransactions(int supplierId) async {
    final db = await database;

    await db.transaction((txn) async {
      print('Starting transaction test...');

      // Get current supplier balance using transaction object
      final currentBalance = await getSupplierBalance(supplierId, txn: txn);
      print('Current balance: $currentBalance');

      // Add a test payment transaction
      final paymentTransaction = my_model.Transaction(
        supplierId: supplierId,
        amount: -1000.0, // Payment of 1000
        date: DateTime.now().toIso8601String(),
        balance: 0,
      );

      print('Adding payment transaction...');
      final newBalance = currentBalance - 1000.0;

      // Insert payment transaction
      final paymentId = await txn.insert(
        'transactions',
        {
          'supplier_id': supplierId,
          'customer_id': null,
          'amount': -1000.0,
          'date': paymentTransaction.date,
          'balance': newBalance,
        },
      );

      // Update supplier balance
      await txn.update(
        'suppliers',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      print('Payment transaction added. Balance: $newBalance');
      print('Adding receipt transaction...');

      // Add a test receipt transaction
      final receiptTransaction = my_model.Transaction(
        supplierId: supplierId,
        amount: 500.0, // Receipt of 500
        date: DateTime.now().toIso8601String(),
        balance: 0,
      );

      // Calculate new balance after receipt
      final finalBalance = newBalance + 500.0;

      // Insert receipt transaction
      final receiptId = await txn.insert(
        'transactions',
        {
          'supplier_id': supplierId,
          'customer_id': null,
          'amount': 500.0,
          'date': receiptTransaction.date,
          'balance': finalBalance,
        },
      );

      // Update supplier balance
      await txn.update(
        'suppliers',
        {'balance': finalBalance},
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      print('Receipt transaction added. Balance: $finalBalance');
      print('\nVerifying all transactions in database:');

      final allTransactions = await txn.query('transactions',
          where: 'supplier_id = ?',
          whereArgs: [supplierId],
          orderBy: 'date DESC');

      for (var transaction in allTransactions) {
        print('Transaction: ${transaction.toString()}');
      }

      print('\nFinal supplier balance: $finalBalance');

      // Clean up test transactions
      await txn.delete(
        'transactions',
        where: 'id IN (?, ?)',
        whereArgs: [paymentId, receiptId],
      );

      // Restore original balance
      await txn.update(
        'suppliers',
        {'balance': currentBalance},
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      print(
          'Test completed and cleaned up. Balance restored to: $currentBalance');
    });
  }
}
