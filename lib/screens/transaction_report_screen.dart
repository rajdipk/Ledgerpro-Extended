//transaction_report_screen.dart

// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/business_provider.dart';
import '../models/business_model.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../utils/pdf_util.dart';
import '../providers/currency_provider.dart';

class TransactionReportScreen extends StatefulWidget {
  final Customer customer;

  const TransactionReportScreen({Key? key, required this.customer})
      : super(key: key);

  @override
  _TransactionReportScreenState createState() =>
      _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share PDF'),
          content: const Text(
              'Do you want to share the transaction report as a PDF?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Share'),
              onPressed: () async {
                try {
                  await PdfUtil.sharePdf(
                    widget.customer,
                    Business(
                      id: Provider.of<BusinessProvider>(context, listen: false)
                              .selectedBusinessId ??
                          '',
                      name:
                          Provider.of<BusinessProvider>(context, listen: false)
                              .businesses
                              .firstWhere(
                                  (business) =>
                                      business.id ==
                                      Provider.of<BusinessProvider>(context,
                                              listen: false)
                                          .selectedBusinessId,
                                  orElse: () =>
                                      Business(id: '', name: 'the business'))
                              .name,
                    ),
                    Provider.of<BusinessProvider>(context, listen: false)
                            .selectedCustomer
                            ?.transactions ??
                        [],
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing PDF: $e'),
                      ),
                    );
                  }
                }
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  final result = await PdfUtil.savePdf(
                    widget.customer,
                    Business(
                      id: Provider.of<BusinessProvider>(context, listen: false)
                              .selectedBusinessId ??
                          '',
                      name:
                          Provider.of<BusinessProvider>(context, listen: false)
                              .businesses
                              .firstWhere(
                                  (business) =>
                                      business.id ==
                                      Provider.of<BusinessProvider>(context,
                                              listen: false)
                                          .selectedBusinessId,
                                  orElse: () =>
                                      Business(id: '', name: 'the business'))
                              .name,
                    ),
                    Provider.of<BusinessProvider>(context, listen: false)
                            .selectedCustomer
                            ?.transactions ??
                        [],
                  );
                  if (result != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF saved to $result'),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving PDF: $e'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDateRangeDialog());
  }

  Future<void> _showDateRangeDialog() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Report for ${widget.customer.name}'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, _) {
          // Fetch the original transaction list from the provider
          final transactions = List<Transaction>.from(
              provider.selectedCustomer?.transactions ?? []);

          final businessName = provider.businesses
              .firstWhere(
                  (business) => business.id == provider.selectedBusinessId,
                  orElse: () => Business(id: '', name: 'the business'))
              .name;

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions found.'),
            );
          }

          // Sort the local list by date in ascending order (oldest first)
          transactions.sort((a, b) =>
              DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

          List<Transaction> filteredTransactions = transactions;
          List<Transaction> previousTransactions = [];

          if (_fromDate != null && _toDate != null) {
            filteredTransactions = transactions.where((transaction) {
              final transactionDate = DateTime.parse(transaction.date);
              return transactionDate.isAtSameMomentAs(_fromDate!) ||
                  transactionDate.isAtSameMomentAs(_toDate!) ||
                  (transactionDate.isAfter(_fromDate!) &&
                      transactionDate
                          .isBefore(_toDate!.add(const Duration(days: 1))));
            }).toList();

            previousTransactions = transactions.where((transaction) {
              final transactionDate = DateTime.parse(transaction.date);
              return transactionDate.isBefore(_fromDate!);
            }).toList();
          }

          double totalCredits = 0;
          double totalDebits = 0;
          double runningBalance = 0;

          for (var transaction in previousTransactions) {
            runningBalance += transaction.amount;
          }

          if (previousTransactions.isNotEmpty) {
            filteredTransactions.insert(
              0,
              Transaction(
                date: DateFormat('yyyy-MM-dd')
                    .format(_fromDate!.subtract(const Duration(days: 1))),
                amount: runningBalance,
                customerId: widget.customer.id,
                balance: widget.customer.balance,
              ),
            );
          }

          for (var transaction in filteredTransactions) {
            if (transaction.amount >= 0) {
              totalCredits += transaction.amount;
            } else {
              totalDebits += transaction.amount.abs();
            }
          }

          double finalBalance = totalCredits - totalDebits;

          if (previousTransactions.isNotEmpty) {
            runningBalance = filteredTransactions[0].amount;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Name: ${widget.customer.name}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${widget.customer.phone.isNotEmpty ? widget.customer.phone : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${widget.customer.address.isNotEmpty ? widget.customer.address : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'PAN: ${widget.customer.pan.isNotEmpty ? widget.customer.pan : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'GSTIN: ${widget.customer.gstin.isNotEmpty ? widget.customer.gstin : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(thickness: 2),
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('Date',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('Received (₹)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('Given (₹)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Text('Balance (₹)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final isReceived = transaction.amount >= 0;
                      final textColor = isReceived ? Colors.green : Colors.red;

                      if (index != 0 || previousTransactions.isEmpty) {
                        runningBalance += transaction.amount;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                DateFormat("dd/MM/yyyy")
                                    .format(DateTime.parse(transaction.date)),
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                isReceived
                                    ? NumberFormat.currency(
                                        symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                        locale: 'en_IN',
                                        decimalDigits: 2,
                                      ).format(transaction.amount)
                                    : '',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                isReceived
                                    ? ''
                                    : NumberFormat.currency(
                                        symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                        locale: 'en_IN',
                                        decimalDigits: 2,
                                      ).format(transaction.amount.abs()),
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.currency(
                                  symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                  locale: 'en_IN',
                                  decimalDigits: 2,
                                ).format(runningBalance),
                                style: TextStyle(
                                  color: runningBalance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Given: ${NumberFormat.currency(
                          symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                          locale: 'en_IN',
                          decimalDigits: 2,
                        ).format(totalDebits)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Received: ${NumberFormat.currency(
                          symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                          locale: 'en_IN',
                          decimalDigits: 2,
                        ).format(totalCredits)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Final Balance: ${NumberFormat.currency(
                          symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                          locale: 'en_IN',
                          decimalDigits: 2,
                        ).format(finalBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: finalBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        finalBalance >= 0
                            ? '${widget.customer.name} will get ${NumberFormat.currency(
                              symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                              locale: 'en_IN',
                              decimalDigits: 2,
                            ).format(finalBalance.abs())} from $businessName.'
                            : '$businessName will receive ${NumberFormat.currency(
                              symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                              locale: 'en_IN',
                              decimalDigits: 2,
                            ).format(finalBalance.abs())} from ${widget.customer.name}.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: finalBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShareDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.share),
      ),
    );
  }
}
