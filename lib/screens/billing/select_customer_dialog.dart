import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer_model.dart';
import '../../dialogs/add_customer_dialog.dart' as dialog;
import '../../database/database_helper.dart';

class SelectCustomerDialog extends StatefulWidget {
  const SelectCustomerDialog({Key? key}) : super(key: key);

  @override
  State<SelectCustomerDialog> createState() => _SelectCustomerDialogState();
}

class _SelectCustomerDialogState extends State<SelectCustomerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (businessProvider.selectedBusinessId == null) return;

    final customerMaps = await DatabaseHelper.instance
        .getCustomers(int.parse(businessProvider.selectedBusinessId!));
    setState(() {
      _customers = customerMaps.map((map) => Customer.fromMap(map)).toList();
      _filteredCustomers = _customers;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredCustomers = _customers
          .where((customer) =>
              customer.name.toLowerCase().contains(_searchQuery) ||
              customer.phone.contains(_searchQuery) ||
              customer.address.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Customer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Customers',
                hintText: 'Enter name, phone, or address',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCustomers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterCustomers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              dialog.showAddCustomerDialog(context);
                              // Since showAddCustomerDialog handles its own navigation and state management,
                              // we'll just reload customers after a short delay to ensure the new customer is added
                              Future.delayed(const Duration(milliseconds: 500)).then((_) {
                                if (mounted) {
                                  _loadCustomers();
                                }
                              });
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add New Customer'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customer.phone.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(customer.phone),
                                    ],
                                  ),
                                if (customer.address.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customer.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: Text(
                              'Balance: ₹${customer.balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: customer.balance >= 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(customer),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
