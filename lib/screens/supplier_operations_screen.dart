//supplier_operations_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

import '../providers/business_provider.dart';
import '../dialogs/add_supplier_dialog.dart';
import '../database/database_helper.dart';
import '../models/supplier_model.dart';
import 'supplier_transaction_screen.dart';
import '../widgets/animated_add_button.dart';

class SupplierOperationsScreen extends StatefulWidget {
  const SupplierOperationsScreen({super.key});

  @override
  State<SupplierOperationsScreen> createState() => _SupplierOperationsScreenState();
}

class _SupplierOperationsScreenState extends State<SupplierOperationsScreen> {
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
                // Left panel with supplier list
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
                                  return _SupplierList(
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
                          onPressed: () => showAddSupplierDialog(context),
                          label: 'Add Supplier',
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
                        final supplier = provider.selectedSupplier;
                        if (supplier != null) {
                          return SupplierTransactionScreen(
                            supplier: supplier,
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
                                  "Select a supplier to view details",
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

  void showAddSupplierDialog(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (businessProvider.selectedBusinessId != null) {
      showDialog(
        context: context,
        builder: (context) => AddSupplierDialog(
          businessId: int.parse(businessProvider.selectedBusinessId!),
          onSupplierAdded: () {
            Provider.of<BusinessProvider>(context, listen: false).refreshSuppliers();
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a business first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SupplierList extends StatefulWidget {
  final String businessId;

  const _SupplierList(this.businessId);

  @override
  __SupplierListState createState() => __SupplierListState();
}

class __SupplierListState extends State<_SupplierList> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  late BusinessProvider _businessProvider;
  bool _isListening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (!_isListening) {
      _businessProvider.addListener(_loadSuppliers);
      _isListening = true;
      _loadSuppliers();
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _businessProvider.removeListener(_loadSuppliers);
      _isListening = false;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(_SupplierList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId) {
      _loadSuppliers();
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final supplierMaps = await DatabaseHelper.instance
          .getSuppliers(int.parse(widget.businessId));
      final List<Supplier> suppliers = [];

      for (final map in supplierMaps) {
        final supplier = Supplier.fromMap(map);
        final lastTransactionDate =
            await DatabaseHelper.instance.getLastSupplierTransactionDate(supplier.id);
        if (lastTransactionDate != null) {
          final parsedDate = DateTime.parse(lastTransactionDate);
          supplier.lastTransactionDate = parsedDate;
        }
        suppliers.add(supplier);
      }

      suppliers.sort((a, b) {
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

      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _filteredSuppliers = suppliers;
        });

        await _businessProvider.calculateBalances();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suppliers: $e')),
        );
      }
    }
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers
            .where((supplier) =>
                supplier.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Widget _buildDashboard() {
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    final totalBalance = Provider.of<BusinessProvider>(context).supplierPayableBalance - Provider.of<BusinessProvider>(context).supplierReceivableBalance;
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
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
                      NumberFormat.currency(
                        symbol: currencySymbol,
                        locale: 'en_IN',
                        decimalDigits: 2,
                      ).format(businessProvider.supplierReceivableBalance.abs()),
                      Icons.account_balance_wallet_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardItem(
                      'Payable Balance',
                      NumberFormat.currency(
                        symbol: currencySymbol,
                        locale: 'en_IN',
                        decimalDigits: 2,
                      ).format(businessProvider.supplierPayableBalance.abs()),
                      Icons.payments_outlined,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardItem(
                      'Total Balance',
                      NumberFormat.currency(
                        symbol: currencySymbol,
                        locale: 'en_IN',
                        decimalDigits: 2,
                      ).format(totalBalance.abs()),
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
                    onChanged: _filterSuppliers,
                    decoration: InputDecoration(
                      hintText: 'Search suppliers...',
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
                  child: _filteredSuppliers.isEmpty
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
                                'No suppliers found',
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
                          itemCount: _filteredSuppliers.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final supplier = _filteredSuppliers[index];
                            final isSelected = Provider.of<BusinessProvider>(context)
                                    .selectedSupplier
                                    ?.id ==
                                supplier.id;

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
                                  supplier.name,
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
                                      ).format(supplier.balance),
                                      style: TextStyle(
                                        color: supplier.balance < 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    if (supplier.lastTransactionDate != null)
                                      Text(
                                        'Last Transaction: ${DateFormat('d MMMM y').format(supplier.lastTransactionDate!)}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                                onTap: () {
                                  Provider.of<BusinessProvider>(context, listen: false)
                                      .setSelectedSupplier(supplier);
                                  
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  if (screenWidth < 600) {
                                    // For small screens, navigate to full screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SupplierTransactionScreen(
                                          supplier: supplier,
                                        ),
                                      ),
                                    );
                                  }
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
}
