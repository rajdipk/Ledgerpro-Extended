// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase_order_model.dart';
import '../../providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class PurchaseOrderDetailsDialog extends StatefulWidget {
  final PurchaseOrder order;

  const PurchaseOrderDetailsDialog({
    super.key,
    required this.order,
  });

  @override
  _PurchaseOrderDetailsDialogState createState() => _PurchaseOrderDetailsDialogState();
}

class _PurchaseOrderDetailsDialogState extends State<PurchaseOrderDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Order #${widget.order.orderNumber}'),
              automaticallyImplyLeading: false,
              actions: [
                if (widget.order.status == 'ORDERED')
                  TextButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Receive',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _showReceiveDialog,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderHeader(),
                      const SizedBox(height: 24),
                      _buildOrderItems(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${widget.order.orderNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${widget.order.status}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(widget.order.status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.orderDate))}',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.order.expectedDate != null) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Expected Delivery Date'),
                subtitle: Text(
                  widget.order.expectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.expectedDate!))
                      : 'Not set',
                ),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Received Date'),
              subtitle: Text(
                widget.order.receivedDate != null
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.receivedDate!))
                    : widget.order.expectedDate != null
                        ? 'Expected: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.order.expectedDate!))}'
                        : 'Not received',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ${NumberFormat.currency(symbol: '\$').format(widget.order.totalAmount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.order.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.order.notes!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                final inventoryItem = provider.getItemById(item.itemId);
                if (inventoryItem == null) return const SizedBox.shrink();

                return Card(
                  child: ListTile(
                    title: Text(inventoryItem.name),
                    subtitle: Text(
                      'SKU: ${inventoryItem.sku ?? 'N/A'} | Ordered: ${item.quantity}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$')
                              .format(item.unitPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${NumberFormat.currency(symbol: '\$').format(item.totalPrice)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  void _showReceiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Order'),
        content: const Text(
          'Are you sure you want to mark this order as received? '
          'This will update the inventory levels.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Receive'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _receiveOrder();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _receiveOrder() async {
    try {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      
      // Create a new purchase order with updated status
      final updatedOrder = widget.order.copyWith(
        status: 'RECEIVED',
        receivedDate: DateTime.now().toIso8601String(),
      );

      await provider.updatePurchaseOrder(updatedOrder);
      
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order received successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error receiving order: $e')),
      );
    }
  }
}
