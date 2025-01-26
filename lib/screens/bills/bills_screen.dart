import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bill_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/bill_model.dart';
import '../billing/billing_screen.dart';
import 'bill_details_screen.dart';
import '../home_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load bills when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<BusinessProvider>().selectedBusinessId;
      if (businessId != null) {
        context.read<BillProvider>().loadBills(int.parse(businessId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HomeScreen.of(context)
                .switchContent(const BillingScreen(), '/billing');
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bills by customer name or bill number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          if (billProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (billProvider.error != null) {
            return Center(child: Text(billProvider.error!));
          }

          final bills = billProvider.bills;
          if (bills.isEmpty) {
            return const Center(child: Text('No bills found'));
          }

          final filteredBills = bills.where((bill) {
            final searchStr = _searchQuery.toLowerCase();
            return bill.customer.name.toLowerCase().contains(searchStr) ||
                bill.id.toString().contains(searchStr);
          }).toList();

          if (filteredBills.isEmpty) {
            return const Center(child: Text('No matching bills found'));
          }

          return ListView.builder(
            itemCount: filteredBills.length,
            itemBuilder: (context, index) {
              final bill = filteredBills[index];
              return BillListItem(bill: bill);
            },
          );
        },
      ),
    );
  }
}

class BillListItem extends StatelessWidget {
  final Bill bill;

  const BillListItem({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final isNarrowScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () {
          HomeScreen.of(context)
              .switchContent(BillDetailsScreen(bill: bill), '/bill-details');
        },
        title: isNarrowScreen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill #${bill.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.customer.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Bill #${bill.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(bill.customer.name),
                  ),
                  _buildStatusBadge(),
                ],
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    bill.customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(bill.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items: ${bill.items.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (bill.gstAmount > 0)
                      Text(
                        'GST: ${currencyFormat.format(bill.gstAmount)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    if (bill.discount > 0)
                      Text(
                        'Discount: ${currencyFormat.format(bill.discount)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                Text(
                  currencyFormat.format(bill.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bill.status == 'paid'
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        bill.status.toUpperCase(),
        style: TextStyle(
          color: bill.status == 'paid' ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
