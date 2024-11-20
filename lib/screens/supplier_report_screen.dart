//supplier_report_screen.dart

// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/business_provider.dart';
import '../models/business_model.dart';
import '../models/supplier_model.dart';
import '../models/transaction_model.dart';
import '../utils/pdf_util.dart';
import '../providers/currency_provider.dart';

class SupplierReportScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierReportScreen({Key? key, required this.supplier})
      : super(key: key);

  @override
  _SupplierReportScreenState createState() => _SupplierReportScreenState();
}

class _SupplierReportScreenState extends State<SupplierReportScreen> {
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
                  await PdfUtil.shareSupplierPdf(
                    widget.supplier,
                    Business(
                      id: Provider.of<BusinessProvider>(context, listen: false)
                              .selectedBusinessId ??
                          '',
                      name: Provider.of<BusinessProvider>(context, listen: false)
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
                    widget.supplier.transactions ?? [],
                    fromDate: _fromDate,
                    toDate: _toDate,
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
                  final result = await PdfUtil.saveSupplierPdf(
                    widget.supplier,
                    Business(
                      id: Provider.of<BusinessProvider>(context, listen: false)
                              .selectedBusinessId ??
                          '',
                      name: Provider.of<BusinessProvider>(context, listen: false)
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
                    widget.supplier.transactions ?? [],
                    fromDate: _fromDate,
                    toDate: _toDate,
                  );
                  if (mounted) {
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF saved to: ${result.path}'),
                        ),
                      );
                    }
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
        title: Text('Transaction Report for ${widget.supplier.name}'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDateRangeDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(context),
          ),
        ],
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, _) {
          final transactions = List<Transaction>.from(widget.supplier.transactions ?? []);

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

          // Sort transactions by date
          transactions.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

          List<Transaction> filteredTransactions = transactions;
          List<Transaction> previousTransactions = [];

          if (_fromDate != null && _toDate != null) {
            filteredTransactions = transactions.where((transaction) {
              final transactionDate = DateTime.parse(transaction.date);
              return transactionDate.isAtSameMomentAs(_fromDate!) ||
                  transactionDate.isAtSameMomentAs(_toDate!) ||
                  (transactionDate.isAfter(_fromDate!) &&
                      transactionDate.isBefore(_toDate!.add(const Duration(days: 1))));
            }).toList();

            previousTransactions = transactions.where((transaction) {
              final transactionDate = DateTime.parse(transaction.date);
              return transactionDate.isBefore(_fromDate!);
            }).toList();
          }

          double totalReceived = 0;
          double totalGiven = 0;
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
                supplierId: widget.supplier.id,
                balance: widget.supplier.balance,
              ),
            );
          }

          for (var transaction in filteredTransactions) {
            if (transaction.amount >= 0) {
              totalReceived += transaction.amount;
            } else {
              totalGiven += transaction.amount.abs();
            }
          }

          if (previousTransactions.isNotEmpty) {
            runningBalance = filteredTransactions[0].amount;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Name: ${widget.supplier.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${widget.supplier.phone.isNotEmpty ? widget.supplier.phone : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${widget.supplier.address.isNotEmpty ? widget.supplier.address : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'PAN: ${widget.supplier.pan.isNotEmpty ? widget.supplier.pan : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'GSTIN: ${widget.supplier.gstin.isNotEmpty ? widget.supplier.gstin : 'Not available'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(thickness: 2),
                if (_fromDate != null && _toDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Period: ${DateFormat('MMM dd, yyyy').format(_fromDate!)} to ${DateFormat('MMM dd, yyyy').format(_toDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Received',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Given',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Balance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
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

                      if (index > 0) {
                        runningBalance += transaction.amount;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(DateTime.parse(transaction.date)),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isReceived ? NumberFormat.currency(
                                  symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                  locale: 'en_IN',
                                  decimalDigits: 2,
                                ).format(transaction.amount) : '',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                !isReceived ? NumberFormat.currency(
                                  symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                  locale: 'en_IN',
                                  decimalDigits: 2,
                                ).format(transaction.amount.abs()) : '',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                NumberFormat.currency(
                                  symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                  locale: 'en_IN',
                                  decimalDigits: 2,
                                ).format(runningBalance),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: runningBalance >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2, height: 32),
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
                        ).format(totalGiven)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Received: ${NumberFormat.currency(
                          symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                          locale: 'en_IN',
                          decimalDigits: 2,
                        ).format(totalReceived)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Final Balance: ${NumberFormat.currency(
                          symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                          locale: 'en_IN',
                          decimalDigits: 2,
                        ).format(runningBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: runningBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        (totalReceived - totalGiven) >= 0
                            ? '${widget.supplier.name} will get ${NumberFormat.currency(
                              symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                              locale: 'en_IN',
                              decimalDigits: 2,
                            ).format((totalReceived - totalGiven).abs())} from $businessName.'
                            : '$businessName will receive ${NumberFormat.currency(
                              symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                              locale: 'en_IN',
                              decimalDigits: 2,
                            ).format((totalReceived - totalGiven).abs())} from ${widget.supplier.name}.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (totalReceived - totalGiven) >= 0 ? Colors.green : Colors.red,
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
