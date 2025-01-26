// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../services/print_service.dart';
import '../home_screen.dart';
import 'bills_screen.dart';

class BillDetailsScreen extends StatelessWidget {
  final Bill bill;

  const BillDetailsScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final isNarrowScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill #${bill.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => HomeScreen.of(context)
              .switchContent(const BillsScreen(), '/bills'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Preparing bill for printing...')),
                );
                await PrintService.instance.printBill(bill);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error printing bill: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrowScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive grid for customer details and status
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isNarrowScreen
                      ? double.infinity
                      : MediaQuery.of(context).size.width * 0.4,
                  child: _buildCustomerDetailsCard(),
                ),
                if (!isNarrowScreen)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: _buildBillSummaryCard(context),
                  ),
              ],
            ),
            if (isNarrowScreen) ...[
              const SizedBox(height: 16),
              _buildBillSummaryCard(context),
            ],
            const SizedBox(height: 16),
            _buildItemsTable(isNarrowScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Name: ${bill.customer.name}'),
            Text('Phone: ${bill.customer.phone}'),
            Text('Date: ${dateFormat.format(bill.createdAt)}'),
            if (bill.status == 'paid' && bill.paidAt != null)
              Text('Paid on: ${dateFormat.format(bill.paidAt!)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummaryCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(currencyFormat.format(bill.subTotal)),
              ],
            ),
            if (bill.items.any((item) => item.gstRate > 0)) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'GST Breakdown',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              // Group items by GST rate and show subtotals
              ...bill.items
                  .where((item) => item.gstRate > 0)
                  .fold<Map<double, double>>(
                    {},
                    (map, item) {
                      final rate = item.gstRate;
                      map[rate] = (map[rate] ?? 0) + item.gstAmount;
                      return map;
                    },
                  )
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key}% GST'),
                          Text(currencyFormat.format(entry.value)),
                        ],
                      ),
                    ),
                  ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total GST:'),
                  Text(currencyFormat.format(bill.gstAmount)),
                ],
              ),
            ],
            if (bill.deliveryCharge > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Charge:'),
                  Text(currencyFormat.format(bill.deliveryCharge)),
                ],
              ),
            ],
            if (bill.discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:'),
                  Text(
                    '- ${currencyFormat.format(bill.discount)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  currencyFormat.format(bill.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(bool isNarrowScreen) {
    return Builder(  // Add Builder widget to get context
      builder: (BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (isNarrowScreen)
                _buildMobileItemsList(context)
              else
                _buildDesktopItemsTable(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileItemsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bill.items.length,
      itemBuilder: (context, index) {
        final item = bill.items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.notes?.isNotEmpty ?? false)
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.quantity} ${item.item.unit}'),
                    Text('₹${item.price.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GST: ${item.gstRate}%'),
                    Text(
                      '₹${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopItemsTable(BuildContext context) {  // Add context parameter
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Qty',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                'Rate',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                'GST',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bill.items.length,
          itemBuilder: (context, index) {
            final item = bill.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.item.name),
                        if (item.notes?.isNotEmpty ?? false)
                          Text(
                            item.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity} ${item.item.unit}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      currencyFormat.format(item.price),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.gstRate.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      currencyFormat.format(item.total),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
