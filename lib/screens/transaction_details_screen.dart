//transaction_details_screen.dart

// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../dialogs/customer_details.dart';
import '../dialogs/transaction_edit_popup.dart';
import '../dialogs/transaction_input_popup.dart';
import '../models/transaction_model.dart';
import 'transaction_report_screen.dart';
import '../providers/currency_provider.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final int businessId;
  final int customerId;
  final bool isSupplier;

  const TransactionDetailsScreen({
    super.key,
    required this.businessId,
    required this.customerId,
    required this.isSupplier,
  });

  @override
  _TransactionDetailsScreenState createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late final BusinessProvider _businessProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    Future.microtask(() async {
      await _businessProvider.setSelectedCustomerById(widget.customerId);
      await _businessProvider.refreshTransactions(widget.customerId);
    });
  }

  String _getDateLabel(DateTime txnDate) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    if (DateTime(txnDate.year, txnDate.month, txnDate.day) == today) {
      return 'Today';
    } else if (DateTime(txnDate.year, txnDate.month, txnDate.day) ==
        yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat("yyyy-MM-dd").format(txnDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
            )
          : null,
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          final customer = provider.selectedCustomer;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Info Card
              if (customer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: InkWell(
                    onTap: () {
                      CustomerDetailsDialog.show(context, customer);
                    },
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.phone,
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
                                color: customer.balance >= 0
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Balance (${Provider.of<CurrencyProvider>(context, listen: false).currencySymbol})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: customer.balance >= 0
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          customer.balance.abs().toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: customer.balance >= 0
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
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
              // Transaction List Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
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
              const Divider(),
              Expanded(
                child: Consumer<BusinessProvider>(
                  builder: (context, provider, _) {
                    final transactions =
                        provider.selectedCustomer?.transactions ?? [];
                    Map<String, List<Transaction>> groupedTransactions = {};

                    for (var transaction in transactions) {
                      final String dateKey =
                          _getDateLabel(DateTime.parse(transaction.date));
                      groupedTransactions
                          .putIfAbsent(dateKey, () => [])
                          .add(transaction);
                    }

                    List<String> dates = groupedTransactions.keys.toList();
                    dates.sort((a, b) {
                      // Special cases handling
                      if (a == 'Today') return -1; // 'Today' should come first
                      if (b == 'Today') return 1;
                      if (a == 'Yesterday' && b != 'Today') {
                        return -1; // 'Yesterday' comes before regular dates
                      }
                      if (b == 'Yesterday' && a != 'Today') return 1;

                      // Regular date comparison
                      return DateTime.parse(b).compareTo(DateTime.parse(a));
                    });

                    return ListView.builder(
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        String date = dates[index];
                        List<Transaction> dailyTransactions =
                            groupedTransactions[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Text(
                                date,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                            ...dailyTransactions.map((transaction) {
                              final bool isReceived = transaction.amount >= 0;
                              final Color textColor =
                                  isReceived ? Colors.green : Colors.red;
                              final IconData icon = isReceived
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward;
                              final formattedDate = DateFormat("EEEE, dd/MM")
                                  .format(DateTime.parse(transaction.date));

                              return GestureDetector(
                                onTap: () async {
                                  if (transaction.id != null) {
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return TransactionEditPopup(
                                          initialAmount: transaction.amount,
                                          initialDate: DateTime.parse(transaction.date),
                                          transactionId: transaction.id,
                                          customerId: widget.customerId,
                                          onConfirm: (amount, date) async {
                                            // Update the transaction with new details
                                            await _businessProvider.updateTransaction(
                                              transaction.id!,
                                              Transaction(
                                                id: transaction.id,
                                                customerId: widget.customerId,
                                                amount: amount,
                                                date: date.toString(),
                                                balance: transaction.balance,
                                              ),
                                            );
                                            // Refresh the transactions screen after update
                                            await _businessProvider.refreshTransactions(widget.customerId);
                                          },
                                        );
                                      },
                                    );
                                  }
                                },
                                child: Card(
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formattedDate,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'Balance: ${NumberFormat.currency(symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol, locale: 'en_IN', decimalDigits: 2).format(transaction.balance)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: transaction.balance >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        if (screenWidth > 400)
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isReceived ? "Received" : "Given",
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(icon, color: textColor, size: 16),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${isReceived ? "+" : "-"}${NumberFormat.currency(symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol, locale: 'en_IN', decimalDigits: 2).format(transaction.amount.abs())}',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final customer = _businessProvider.selectedCustomer;
                        if (customer != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TransactionReportScreen(customer: customer),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.red, width: 2), // Thicker red outline
                      ),
                      child: const Text(
                        'Report',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold), // Red text color
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return TransactionInputPopup(
                              isReceived: true,  // For receiving money
                              onConfirm: (amount, date) async {
                                try {
                                  await _businessProvider.addAmountGiven(
                                    widget.customerId,
                                    amount,  // Keep positive for "Received"
                                    date.toString(),
                                  );
                                  if (mounted) {
                                    await _businessProvider
                                        .refreshTransactions(widget.customerId);
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print("Error occurred: $e");
                                  }
                                } finally {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Amount Received',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return TransactionInputPopup(
                              isReceived: false,  // For giving money
                              onConfirm: (amount, date) async {
                                try {
                                  await _businessProvider.addAmountReceived(
                                    widget.customerId,
                                    -amount,  // Make negative for "Given"
                                    date.toString(),
                                  );
                                  if (mounted) {
                                    await _businessProvider
                                        .refreshTransactions(widget.customerId);
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print("Error occurred: $e");
                                  }
                                } finally {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Amount Given',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
