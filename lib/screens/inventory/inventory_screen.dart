import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item_model.dart';
import '../../models/purchase_order_model.dart';
import 'package:intl/intl.dart';
import 'item_details_dialog.dart';
import 'add_item_dialog.dart';
import 'add_movement_dialog.dart';
import 'add_purchase_order_dialog.dart';
import 'purchase_order_details_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
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
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Movements'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInventoryItemsTab(),
                          _buildStockMovementsTab(),
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

  Widget _buildInventoryItemsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final items = provider.items.where((item) {
          return item.name.toLowerCase().contains(_searchQuery) ||
              (item.sku?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('SKU: ${item.sku ?? 'N/A'} | Stock: ${item.currentStock}'),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(item.unitPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _showItemDetails(item),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockMovementsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final movements = provider.movements;
        return ListView.builder(
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            final item = provider.getItemById(movement.itemId);
            if (item == null) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(
                  movement.movementType == 'IN'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: movement.movementType == 'IN'
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(item.name),
                subtitle: Text(
                  'Quantity: ${movement.quantity} | ${DateFormat('MMM dd, yyyy').format(DateTime.parse(movement.date))}',
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(movement.totalPrice),
                ),
              ),
            );
          },
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
                title: Text('Order #${order.orderNumber}'),
                subtitle: Text(
                  'Status: ${order.status} | ${DateFormat('MMM dd, yyyy').format(DateTime.parse(order.orderDate))}',
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(order.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _showOrderDetails(order),
              ),
            );
          },
        );
      },
    );
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

  void _showItemDetails(InventoryItem item) {
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

  void _showAddMovementDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddMovementDialog(),
    );
  }

  void _showAddPurchaseOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseOrderDialog(),
    );
  }
}
