// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/business_provider.dart';
import '../dialogs/add_customer_dialog.dart';
import '../database/database_helper.dart';
import '../models/customer_model.dart';
import 'transaction_details_screen.dart';
import '../widgets/animated_add_button.dart';
import '../mixins/license_checker_mixin.dart';

class CustomerOperationsScreen extends StatefulWidget {
  const CustomerOperationsScreen({super.key});

  @override
  State<CustomerOperationsScreen> createState() => _CustomerOperationsScreenState();
}

class _CustomerOperationsScreenState extends State<CustomerOperationsScreen> with LicenseCheckerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final bool isWideScreen = screenWidth > 600;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel with customer list
                Expanded(
                  flex: isWideScreen ? 4 : 5,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Consumer<BusinessProvider>(
                              builder: (context, businessProvider, child) {
                                if (businessProvider.selectedBusinessId != null) {
                                  return _CustomerList(
                                    businessProvider.selectedBusinessId!,
                                  );
                                } else {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.business_outlined,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No business selected',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: AnimatedAddButton(
                          onPressed: () async {
                            final currentCount = await DatabaseHelper.instance.getCustomerCount(
                              int.parse(Provider.of<BusinessProvider>(context, listen: false).selectedBusinessId!)
                            );
                            if (!await checkWithinLimit(context, 'max_customers', currentCount)) {
                              return;
                            }
                            if (!mounted) return;
                            await showDialog(
                              context: context,
                              builder: (context) => const AddCustomerDialog(),
                            );
                          },
                          label: 'Add Customer',
                          icon: Icons.person_add,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vertical divider
                if (isWideScreen)
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          Theme.of(context).colorScheme.outline.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                // Right panel with transaction details
                if (isWideScreen)
                  Expanded(
                    flex: 5,
                    child: Consumer<BusinessProvider>(
                      builder: (context, provider, child) {
                        final customer = provider.selectedCustomer;
                        if (customer != null) {
                          return TransactionDetailsScreen(
                            businessId: int.parse(provider.selectedBusinessId!),
                            customerId: customer.id,
                            isSupplier: false,
                          );
                        } else {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_sharp,
                                  size: 72,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Select a customer to view details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerList extends StatefulWidget {
  final String businessId;

  const _CustomerList(this.businessId);

  @override
  State<_CustomerList> createState() => __CustomerListState();
}

class __CustomerListState extends State<_CustomerList> with LicenseCheckerMixin {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  late BusinessProvider _businessProvider;
  bool _isListening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (!_isListening) {
      _businessProvider.addListener(_loadCustomers);
      _isListening = true;
      _loadCustomers();
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _businessProvider.removeListener(_loadCustomers);
      _isListening = false;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_CustomerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId) {
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final customerMaps = await DatabaseHelper.instance
          .getCustomers(int.parse(widget.businessId));
      final List<Customer> customers = [];

      for (final map in customerMaps) {
        final customer = Customer.fromMap(map);
        final lastTransactionDate =
            await DatabaseHelper.instance.getLastTransactionDate(customer.id);
        if (lastTransactionDate != null) {
          final parsedDate = DateTime.parse(lastTransactionDate);
          customer.lastTransactionDate = parsedDate;
        }
        customers.add(customer);
      }

      customers.sort((a, b) {
        if (a.lastTransactionDate == null && b.lastTransactionDate == null) {
          return 0;
        } else if (a.lastTransactionDate == null) {
          return 1;
        } else if (b.lastTransactionDate == null) {
          return -1;
        } else {
          return b.lastTransactionDate!.compareTo(a.lastTransactionDate!);
        }
      });

      // Calculate balances before updating state
      if (mounted) {
        await _businessProvider.calculateBalances();
        
        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDashboard(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _filterCustomers,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No customers found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCustomers.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final isSelected = Provider.of<BusinessProvider>(context)
                                    .selectedCustomer
                                    ?.id ==
                                customer.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              elevation: isSelected ? 2 : 0,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  customer.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      NumberFormat.currency(
                                        symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol,
                                        locale: 'en_IN',
                                        decimalDigits: 2,
                                      ).format(customer.balance),
                                      style: TextStyle(
                                        color: customer.balance < 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    if (customer.lastTransactionDate != null)
                                      Text(
                                        'Last Transaction: ${DateFormat('d MMMM y').format(customer.lastTransactionDate!)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                                onTap: () async {
                                  Provider.of<BusinessProvider>(context, listen: false)
                                      .setSelectedCustomer(customer);
                                  
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  if (screenWidth < 600) {
                                    // For small screens, navigate to full screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransactionDetailsScreen(
                                          businessId: int.parse(widget.businessId),
                                          customerId: customer.id,
                                          isSupplier: false,
                                        ),
                                      ),
                                    );
                                  }
                                  // Refresh transactions for the selected customer
                                  await Provider.of<BusinessProvider>(context, listen: false)
                                      .refreshTransactions(customer.id);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        final totalBalance = businessProvider.customerReceivableBalance - businessProvider.customerPayableBalance;
        final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
        final numberFormat = NumberFormat.currency(
          symbol: currencySymbol,
          locale: 'en_IN',
          decimalDigits: 2,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardItem(
                      'Receivable Balance',
                      numberFormat.format(businessProvider.customerReceivableBalance.abs()),
                      Icons.account_balance_wallet_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardItem(
                      'Payable Balance',
                      numberFormat.format(businessProvider.customerPayableBalance.abs()),
                      Icons.payments_outlined,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardItem(
                      'Total Balance',
                      numberFormat.format(totalBalance.abs()),
                      Icons.trending_up,
                      totalBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardItem(String title, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _customers
          .where((customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
}
