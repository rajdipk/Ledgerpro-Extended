// supplier_transaction_screen.dart

// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../dialogs/transaction_input_popup.dart';
import '../dialogs/supplier_transaction_edit_popup.dart';
import '../dialogs/supplier_details_dialog.dart';
import '../models/supplier_model.dart';
import '../models/transaction_model.dart';
import '../screens/supplier_report_screen.dart';
import '../providers/currency_provider.dart';

class SupplierTransactionScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierTransactionScreen({
    required this.supplier,
    Key? key,
  }) : super(key: key);

  @override
  _SupplierTransactionScreenState createState() =>
      _SupplierTransactionScreenState();
}

class _SupplierTransactionScreenState extends State<SupplierTransactionScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<BusinessProvider>(context, listen: false)
        .refreshSupplierTransactions(widget.supplier.id);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: screenWidth < 600
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              title: Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.report),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupplierReportScreen(
                          supplier: widget.supplier,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: InkWell(
              onTap: () {
                SupplierDetailsDialog.show(context, widget.supplier);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Consumer<BusinessProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.supplier.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.supplier.phone,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: widget.supplier.balance >= 0
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Balance ($currencySymbol)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.supplier.balance >= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    widget.supplier.balance.abs().toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.supplier.balance >= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: screenWidth > 600 ? 2 : 1,
                  child: Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (screenWidth > 400) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Type',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildTransactionList(),
            ),
          ),
          _buildTransactionButtons(),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final transactions = businessProvider.selectedSupplier?.transactions ?? [];
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a transaction using the buttons below',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isReceived = transaction.amount > 0;
            final formattedDate = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(transaction.date));
            final textColor = isReceived ? Colors.green : Colors.red;

            return Hero(
              tag: 'transaction-${transaction.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEditTransactionDialog(transaction),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: screenWidth > 600 ? 2 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate.split(',')[0],
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (screenWidth <= 600)
                                  Text(
                                    formattedDate.split(',')[1],
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (screenWidth > 400) ...[
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: textColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isReceived ? 'Received' : 'Given',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${isReceived ? "+" : "-"}$currencySymbol${transaction.amount.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditTransactionDialog(transaction);
                                    } else if (value == 'delete') {
                                      _showEditTransactionDialog(transaction);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Edit',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_downward, size: 20),
              label: Text(
                'Received',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _showAddTransactionDialog(context, false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_upward, size: 20),
              label: Text(
                'Given',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _showAddTransactionDialog(context, true),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF616161),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupplierReportScreen(
                      supplier: widget.supplier,
                    ),
                  ),
                );
              },
              child: const Tooltip(
                message: 'Generate Report',
                child: Icon(Icons.summarize_outlined, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, bool isPayment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransactionInputPopup(
          isReceived: !isPayment,
          onConfirm: (amount, date) async {
            final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
            final formattedDate = DateFormat('yyyy-MM-dd').format(date);
            
            if (isPayment) {
              await businessProvider.addSupplierPayment(amount, formattedDate);
            } else {
              await businessProvider.addSupplierReceipt(amount, formattedDate);
            }
          },
        );
      },
    );
  }

  void _showEditTransactionDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SupplierTransactionEditPopup(
          initialAmount: transaction.amount,
          initialDate: DateTime.parse(transaction.date),
          onConfirm: (amount, date) async {
            final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
            await businessProvider.updateSupplierTransaction(
              Transaction(
                id: transaction.id,
                customerId: transaction.customerId,
                amount: amount,
                date: date.toIso8601String(),
                balance: 0, // Will be recalculated
              ),
            );
          },
          onDelete: transaction.id != null && transaction.supplierId != null
              ? () async {
                  final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
                  await businessProvider.deleteSupplierTransaction(
                    transaction.id!,
                    transaction.supplierId!,
                  );
                }
              : null,
        );
      },
    );
  }
}
