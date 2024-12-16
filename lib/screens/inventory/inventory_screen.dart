// ignore_for_file: library_private_types_in_public_api, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../models/purchase_order_model.dart';
import '../../providers/currency_provider.dart';
import 'item_details_dialog.dart';
import 'add_item_dialog.dart';
import 'add_movement_dialog.dart';
import 'add_purchase_order_dialog.dart';
import 'purchase_order_details_dialog.dart';
import '../../widgets/barcode_scanner_dialog.dart';
import '../../services/sound_service.dart';
import 'stock_movements_screen.dart'; // Import the new screen

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _soundService = SoundService();
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      await provider.refreshInventory();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inventory Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false).refreshInventory();
            },
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          // Quick Stats Cards
                          SizedBox(
                            height: 70,
                            child: Row(
                              children: [
                                _buildStatCard(
                                  'Total Items',
                                  provider.items.length.toString(),
                                  Icons.inventory_2,
                                  Colors.blue,
                                ),
                                _buildStatCard(
                                  'Low Stock',
                                  provider.items
                                      .where((item) =>
                                          item.currentStock <= item.reorderLevel)
                                      .length
                                      .toString(),
                                  Icons.warning,
                                  Colors.orange,
                                ),
                                _buildStatCard(
                                  'Pending Orders',
                                  provider.purchaseOrders
                                      .where((order) => order.status == 'pending')
                                      .length
                                      .toString(),
                                  Icons.shopping_cart,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom Tab Bar
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Inventory'),
                          Tab(text: 'Stock Movements'),
                          Tab(text: 'Purchase Orders'),
                        ],
                      ),
                    ),
                    // Tab Bar View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInventoryList(context, provider),
                          const StockMovementsScreen(), // Use the new screen
                          _buildPurchaseOrdersTab(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _formatPrice(double price, BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, _) => Text(
        NumberFormat.currency(
          symbol: currencyProvider.currencySymbol,
          decimalDigits: 2,
        ).format(price),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Category'),
            _buildFilterOption('Stock Status'),
            _buildFilterOption('Price Range'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Handle filter option selection
      },
    );
  }

  Widget _buildInventoryList(BuildContext context, InventoryProvider provider) {
    final items = provider.items.where((item) {
      if (item.name == null && item.sku == null && item.category == null) {
        return false;
      }
      return _itemMatchesSearch(item);
    }).toList();

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ItemDetailsDialog(item: item),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${item.sku ?? 'N/A'} | Barcode: ${item.barcode ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.currentStock <= item.reorderLevel
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Stock: ${item.currentStock}',
                              style: TextStyle(
                                color: item.currentStock <= item.reorderLevel
                                    ? Colors.red[700]
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _formatPrice(item.currentStock * item.weightedAverageCost, context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${item.category ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Purchase Price: ${NumberFormat.currency(
                                symbol: Provider.of<CurrencyProvider>(context).currencySymbol,
                                decimalDigits: 2,
                              ).format(item.costPrice)}',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Avg. Cost: ${NumberFormat.currency(
                                symbol: Provider.of<CurrencyProvider>(context).currencySymbol,
                                decimalDigits: 2,
                              ).format(item.weightedAverageCost)}',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selling Price:  ${NumberFormat.currency(
                                symbol: Provider.of<CurrencyProvider>(context)
                                    .currencySymbol,
                                decimalDigits: 2,
                              ).format(item.sellingPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reorder Level: ${item.reorderLevel} units',
                              style: TextStyle(
                                color: item.currentStock <= item.reorderLevel
                                    ? Colors.red[700]
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last Updated: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(item.updatedAt))}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showItemDetails(context, item),
                            tooltip: 'Edit Item',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                            onPressed: () => _showAddMovementDialog(context, item),
                            tooltip: 'Add Movement',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildPurchaseOrdersTab() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final orders = provider.purchaseOrders;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Row(
                  children: [
                    Text('Order #${order.orderNumber}'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(order.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(order.orderDate)),
                ),
                trailing: _formatPrice(order.totalAmount, context),
                onTap: () => _showOrderDetails(order),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'ORDERED':
        return Colors.blue;
      case 'RECEIVED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 0:
            _showAddItemDialog();
            break;
          case 1:
            _showAddMovementDialog();
            break;
          case 2:
            _showAddPurchaseOrderDialog();
            break;
        }
      },
      child: const Icon(Icons.add),
    );
  }

  void _showItemDetails(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => ItemDetailsDialog(item: item),
    );
  }

  void _showOrderDetails(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => PurchaseOrderDetailsDialog(order: order),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddItemDialog(),
    );
  }

  void _showAddMovementDialog([BuildContext? context, InventoryItem? item]) {
    showDialog(
      context: this.context,
      builder: (context) => AddMovementDialog(selectedItem: item),
    );
  }

  void _showAddPurchaseOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseOrderDialog(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    if (!mounted) return;
    
    final String? scannedBarcode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BarcodeScannerDialog(),
    );

    if (scannedBarcode != null && mounted) {
      await _soundService.playBeep();
      setState(() {
        _searchController.text = scannedBarcode;
        _searchQuery = scannedBarcode.toLowerCase();
      });
    }
  }

  bool _itemMatchesSearch(InventoryItem item) {
    final search = _searchQuery.toLowerCase();
    return item.name.toLowerCase().contains(search) ||
        (item.sku?.toLowerCase() ?? '').contains(search) ||
        (item.barcode?.toLowerCase() ?? '').contains(search);
  }
}
