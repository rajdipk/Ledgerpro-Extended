// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../database/supplier_operations.dart';
import '../../models/purchase_order_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/business_provider.dart';
import 'package:intl/intl.dart';

class PurchaseOrderDetailsDialog extends StatefulWidget {
  final PurchaseOrder order;

  const PurchaseOrderDetailsDialog({
    super.key,
    required this.order,
  });

  @override
  _PurchaseOrderDetailsDialogState createState() =>
      _PurchaseOrderDetailsDialogState();
}

class _PurchaseOrderDetailsDialogState extends State<PurchaseOrderDetailsDialog> {
  late final SupplierOperations _supplierOps;

  @override
  void initState() {
    super.initState();
    _supplierOps = SupplierOperations(DatabaseHelper.instance);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      final supplier = await _supplierOps.getSupplierById(widget.order.supplierId);
      if (supplier != null && mounted) {
        businessProvider.setSelectedSupplier(supplier);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? size.width * 0.95 : 800,
          maxHeight: size.height * 0.9,
        ),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            title: const Text('Purchase Order Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order Information',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildStatusChip(widget.order.status),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Order Number', widget.order.orderNumber),
                                _buildInfoRow(
                                  'Order Date',
                                  DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.orderDate)),
                                ),
                                if (widget.order.expectedDate != null)
                                  _buildInfoRow(
                                    'Expected Delivery',
                                    DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.expectedDate!)),
                                  ),
                                Consumer<BusinessProvider>(
                                  builder: (context, provider, _) {
                                    final supplier = provider.selectedSupplier;
                                    return _buildInfoRow(
                                      'Supplier',
                                      supplier?.name ?? 'Unknown Supplier',
                                    );
                                  },
                                ),
                                if (widget.order.notes?.isNotEmpty ?? false)
                                  _buildInfoRow('Notes', widget.order.notes!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order Items',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: isSmallScreen ? size.width * 0.9 : 750,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.teal.withOpacity(0.1),
                                    ),
                                    columnSpacing: isSmallScreen ? 16 : 24,
                                    horizontalMargin: isSmallScreen ? 8 : 16,
                                    columns: const [
                                      DataColumn(label: Text('Item')),
                                      DataColumn(label: Text('Quantity')),
                                      DataColumn(label: Text('Unit Price')),
                                      DataColumn(label: Text('Total')),
                                      DataColumn(label: Text('Received')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: widget.order.items.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Consumer<InventoryProvider>(
                                              builder: (context, provider, _) {
                                                final inventoryItem = provider.getItemById(item.itemId);
                                                return Text(inventoryItem?.name ?? 'Unknown Item');
                                              },
                                            ),
                                          ),
                                          DataCell(Text(item.quantity.toString())),
                                          DataCell(Text(NumberFormat.currency(
                                            symbol: '\$',
                                            decimalDigits: 2,
                                          ).format(item.unitPrice))),
                                          DataCell(Text(NumberFormat.currency(
                                            symbol: '\$',
                                            decimalDigits: 2,
                                          ).format(item.totalPrice))),
                                          DataCell(Text(item.receivedQuantity.toString())),
                                          DataCell(
                                            Container(
                                              constraints: BoxConstraints(
                                                minWidth: isSmallScreen ? 80 : 100,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (item.receivedQuantity < item.quantity)
                                                    SizedBox(
                                                      height: 36,
                                                      child: FilledButton.tonal(
                                                        style: FilledButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                        ),
                                                        onPressed: () => _showReceiveDialog(item),
                                                        child: const Text('Receive'),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Order Value: ',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        symbol: '\$',
                                        decimalDigits: 2,
                                      ).format(widget.order.items.fold(
                                        0.0,
                                        (sum, item) => sum + item.totalPrice,
                                      )),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
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
                if (widget.order.status.toLowerCase() != 'completed')
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _hasUnreceivedItems()
                              ? _showReceiveItemsDialog
                              : null,
                          icon: const Icon(Icons.inventory),
                          label: const Text('Receive Items'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _updateOrderStatus('completed'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete Order'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: statusColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: valueStyle,
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: _getStatusColor(status).withOpacity(0.1),
      labelStyle: TextStyle(
        color: _getStatusColor(status),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ordered':
        return Colors.teal;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showReceiveDialog(PurchaseOrderItem item) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController quantityController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Receive Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<InventoryProvider>(
                builder: (context, provider, _) {
                  final inventoryItem = provider.getItemById(item.itemId);
                  return Text('Item: ${inventoryItem?.name ?? 'Unknown Item'}');
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Please confirm the quantity received for this item:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ordered: ${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Received',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Receive'),
              onPressed: () async {
                final currentContext = context;
                // Update received quantity
                final receivedQty =
                    int.tryParse(quantityController.text) ?? 0;

                final updatedItem = item.copyWith(receivedQuantity: receivedQty);

                try {
                  final provider =
                      Provider.of<InventoryProvider>(currentContext, listen: false);
                  
                  if (widget.order.id == null) {
                    throw Exception('Invalid order ID');
                  }
                  
                  await provider.receivePurchaseOrder(
                      widget.order.id!, [updatedItem]);

                  if (!mounted) return;
                  Navigator.of(currentContext).pop(); // Close receive dialog
                  Navigator.of(currentContext).pop(); // Close order details dialog

                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Order received successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(currentContext).pop(); // Close receive dialog
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error receiving order: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateOrderStatus(String status) async {
    try {
      final provider =
          Provider.of<InventoryProvider>(context, listen: false);
      
      if (widget.order.id == null) {
        throw Exception('Invalid order ID');
      }
      
      await provider.updatePurchaseOrderStatus(widget.order.id!, status);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close order details dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _hasUnreceivedItems() {
    return widget.order.items.any((item) => item.receivedQuantity < item.quantity);
  }

  void _showReceiveItemsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final unreceivedItems = widget.order.items
            .where((item) => item.receivedQuantity < item.quantity)
            .toList();
        final Map<int, TextEditingController> controllers = {
          for (var item in unreceivedItems)
            item.itemId: TextEditingController()
        };

        return AlertDialog(
          title: const Text('Receive Items'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter received quantities for the following items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...unreceivedItems.map((item) {
                  final remainingQuantity = item.quantity - item.receivedQuantity;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Consumer<InventoryProvider>(
                            builder: (context, provider, _) {
                              final inventoryItem = provider.getItemById(item.itemId);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inventoryItem?.name ?? 'Unknown Item',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Ordered: ${item.quantity}, Received: ${item.receivedQuantity}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controllers[item.itemId],
                            decoration: InputDecoration(
                              labelText: 'Receive',
                              border: const OutlineInputBorder(),
                              helperText: 'Max: $remainingQuantity',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Receive All'),
              onPressed: () async {
                final currentContext = context;
                final updatedItems = <PurchaseOrderItem>[];

                for (var item in unreceivedItems) {
                  final receivedQty = int.tryParse(
                          controllers[item.itemId]?.text ?? '') ??
                      0;
                  if (receivedQty > 0) {
                    updatedItems.add(
                      item.copyWith(
                        receivedQuantity: item.receivedQuantity + receivedQty,
                      ),
                    );
                  }
                }

                if (updatedItems.isEmpty) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter at least one quantity'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final provider = Provider.of<InventoryProvider>(
                      currentContext,
                      listen: false);

                  if (widget.order.id == null) {
                    throw Exception('Invalid order ID');
                  }

                  await provider.receivePurchaseOrder(
                      widget.order.id!, updatedItems);

                  if (!mounted) return;
                  Navigator.of(currentContext).pop(); // Close receive dialog
                  Navigator.of(currentContext).pop(); // Close order details dialog

                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Items received successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(currentContext).pop(); // Close receive dialog
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error receiving items: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
