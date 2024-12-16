// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../database/supplier_operations.dart';
import '../../models/purchase_order_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/currency_provider.dart';
import 'package:intl/intl.dart';
import 'add_item_dialog.dart';

// Controller class for managing receive item text fields
class ReceiveItemController {
  final TextEditingController quantityController;
  final int itemId;
  final int remainingQuantity;

  ReceiveItemController({
    required this.itemId,
    required this.remainingQuantity,
  }) : quantityController = TextEditingController(text: '0');

  void dispose() {
    quantityController.dispose();
  }
}

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

class _PurchaseOrderDetailsDialogState
    extends State<PurchaseOrderDetailsDialog> {
  late final SupplierOperations _supplierOps;

  @override
  void initState() {
    super.initState();
    _supplierOps = SupplierOperations(DatabaseHelper.instance);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final businessProvider =
          Provider.of<BusinessProvider>(context, listen: false);
      final supplier =
          await _supplierOps.getSupplierById(widget.order.supplierId);
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
              if (widget.order.status.toLowerCase() == 'pending')
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Order',
                  onPressed: _showDeleteOrderDialog,
                ),
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
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildStatusChip(widget.order.status),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                    'Order Number', widget.order.orderNumber),
                                _buildInfoRow(
                                  'Order Date',
                                  DateFormat('MMM dd, yyyy').format(
                                      DateTime.parse(widget.order.orderDate)),
                                ),
                                if (widget.order.expectedDate != null)
                                  _buildInfoRow(
                                    'Expected Delivery',
                                    DateFormat('MMM dd, yyyy').format(
                                        DateTime.parse(
                                            widget.order.expectedDate!)),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timeline,
                                        color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order Timeline',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTimeline(),
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
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
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
                                    minWidth:
                                        isSmallScreen ? size.width * 0.9 : 750,
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
                                                final inventoryItem = provider
                                                    .getItemById(item.itemId);
                                                return Text(
                                                    inventoryItem?.name ??
                                                        'Unknown Item');
                                              },
                                            ),
                                          ),
                                          DataCell(Text(item.quantity.toString())),
                                          DataCell(
                                            Consumer<CurrencyProvider>(
                                              builder: (context, currencyProvider, _) => Text(
                                                NumberFormat.currency(
                                                  symbol: currencyProvider.currencySymbol,
                                                  decimalDigits: 2,
                                                ).format(item.unitPrice),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Consumer<CurrencyProvider>(
                                              builder: (context, currencyProvider, _) => Text(
                                                NumberFormat.currency(
                                                  symbol: currencyProvider.currencySymbol,
                                                  decimalDigits: 2,
                                                ).format(item.totalPrice),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(item.receivedQuantity.toString())),
                                          DataCell(
                                            widget.order.status.toLowerCase() == 'draft'
                                                ? Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit,
                                                            size: 20),
                                                        onPressed: () =>
                                                            _showEditItemDialog(item),
                                                        tooltip: 'Edit Item',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            size: 20,
                                                            color: Colors.red),
                                                        onPressed: () =>
                                                            _showDeleteItemDialog(item),
                                                        tooltip: 'Remove Item',
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox.shrink(),
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
                                    Consumer<CurrencyProvider>(
                                      builder: (context, currencyProvider, _) => Text(
                                        NumberFormat.currency(
                                          symbol: currencyProvider.currencySymbol,
                                          decimalDigits: 2,
                                        ).format(widget.order.items.fold(
                                          0.0,
                                          (sum, item) => sum + item.totalPrice,
                                        )),
                                        style:
                                            theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.order.status.toLowerCase() == 'draft')
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FilledButton.tonal(
                                  onPressed: _showAddItemDialog,
                                  child: const Text('Add Item'),
                                ),
                                FilledButton.tonal(
                                  onPressed: _showEditOrderDetailsDialog,
                                  child: const Text('Edit Order Details'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.order.status.toLowerCase() != 'received')
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
                        _buildActionButton(),
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
      case 'draft':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _updateOrderStatus(String status) async {
    try {
      final provider = Provider.of<InventoryProvider>(context, listen: false);

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
    return widget.order.items
        .any((item) => item.receivedQuantity < item.quantity);
  }

  void _showReceiveItemsDialog() {
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        final unreceivedItems = widget.order.items
            .where((item) => item.receivedQuantity < item.quantity)
            .toList();
            
        // Create separate controllers for each item
        final List<ReceiveItemController> itemControllers = unreceivedItems
            .map((item) => ReceiveItemController(
                  itemId: item.itemId,
                  remainingQuantity: item.quantity - item.receivedQuantity,
                ))
            .toList();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.inventory, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Receive Items'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    maxWidth: 500,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter received quantities for all items:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(unreceivedItems.length, (index) {
                          final item = unreceivedItems[index];
                          final controller = itemControllers[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Consumer<InventoryProvider>(
                                    builder: (context, provider, _) {
                                      final inventoryItem = provider.getItemById(item.itemId);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inventoryItem?.name ?? 'Unknown Item',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: ${inventoryItem?.sku ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ordered: ${item.quantity}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.outline,
                                              ),
                                            ),
                                            Text(
                                              'Previously Received: ${item.receivedQuantity}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.outline,
                                              ),
                                            ),
                                            Text(
                                              'Remaining: ${controller.remainingQuantity}',
                                              style: const TextStyle(
                                                color: Colors.teal,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 120,
                                        child: TextFormField(
                                          key: ValueKey('receive_${item.itemId}_$index'),
                                          controller: controller.quantityController,
                                          decoration: const InputDecoration(
                                            labelText: 'Receive',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            final qty = int.tryParse(value);
                                            if (qty == null) {
                                              return 'Invalid number';
                                            }
                                            if (qty < 0) {
                                              return 'Cannot be negative';
                                            }
                                            if (qty > controller.remainingQuantity) {
                                              return 'Exceeds remaining';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    // Dispose all controllers
                    for (var controller in itemControllers) {
                      controller.dispose();
                    }
                    Navigator.of(context).pop();
                  },
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Receive Items'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final updatedItems = <PurchaseOrderItem>[];
                    for (var i = 0; i < unreceivedItems.length; i++) {
                      final item = unreceivedItems[i];
                      final controller = itemControllers[i];
                      final receivedQty = int.parse(controller.quantityController.text);
                      if (receivedQty > 0) {
                        updatedItems.add(
                          item.copyWith(
                            receivedQuantity: item.receivedQuantity + receivedQty,
                          ),
                        );
                      }
                    }

                    try {
                      final provider = Provider.of<InventoryProvider>(
                        context,
                        listen: false,
                      );

                      if (widget.order.id == null) {
                        throw Exception('Invalid order ID');
                      }

                      await provider.receivePurchaseOrder(
                        widget.order.id!,
                        updatedItems,
                      );

                      if (!mounted) return;
                      
                      // Dispose all controllers
                      for (var controller in itemControllers) {
                        controller.dispose();
                      }
                      
                      Navigator.of(context).pop(); // Close receive dialog
                      Navigator.of(context).pop(); // Close order details dialog

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Items received successfully'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error receiving items: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTimeline() {
    final statuses = ['draft', 'pending', 'confirmed', 'received'];
    final currentIndex = statuses.indexOf(widget.order.status.toLowerCase());

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: index ~/ 2 < currentIndex
                  ? Colors.teal
                  : Colors.grey.withOpacity(0.3),
            ),
          );
        }

        final statusIndex = index ~/ 2;
        final status = statuses[statusIndex];
        final isCompleted = statusIndex <= currentIndex;

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.teal : Colors.grey.withOpacity(0.3),
          ),
          child: Icon(
            _getStatusIcon(status),
            size: 16,
            color: Colors.white,
          ),
        );
      }),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'received':
        return Icons.inventory;
      default:
        return Icons.circle;
    }
  }

  Widget _buildActionButton() {
    final status = widget.order.status.toLowerCase();

    if (status == 'received') {
      return const SizedBox.shrink(); // No button when received
    }

    if (status == 'draft') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _updateOrderStatus('pending'),
        icon: const Icon(Icons.check_circle),
        label: const Text('Confirm Order'),
      );
    }

    if (status == 'pending') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _updateOrderStatus('confirmed'),
        icon: const Icon(Icons.check_circle),
        label: const Text('Confirm Order'),
      );
    }

    final hasUnreceivedItems = _hasUnreceivedItems();

    // Show Receive Items button only in confirmed state
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      onPressed: hasUnreceivedItems ? _showReceiveItemsDialog : null,
      icon: const Icon(Icons.inventory),
      label: const Text('Receive Items'),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: AddItemDialog(
          key: UniqueKey(),
        ),
      ),
    );
  }

  void _showEditOrderDetailsDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController notesController =
        TextEditingController(text: widget.order.notes);
    DateTime selectedDeliveryDate = widget.order.expectedDate != null
        ? DateTime.parse(widget.order.expectedDate!)
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.teal),
            SizedBox(width: 8),
            Text('Edit Order Details'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<BusinessProvider>(
                builder: (context, provider, _) {
                  final supplier = provider.selectedSupplier;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.business, color: Colors.teal),
                      title: const Text('Supplier'),
                      subtitle: Text(
                        supplier?.name ?? 'Unknown Supplier',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: const Text('Expected Delivery Date'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(selectedDeliveryDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    try {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDeliveryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.teal,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          selectedDeliveryDate = date;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error selecting date: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note, color: Colors.teal),
                  helperText: 'Add any additional notes or instructions',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Notes cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final updatedOrder = widget.order.copyWith(
                    expectedDate: selectedDeliveryDate.toIso8601String(),
                    notes: notesController.text.trim(),
                    updatedAt: DateTime.now().toIso8601String(),
                  );

                  await Provider.of<InventoryProvider>(context, listen: false)
                      .updatePurchaseOrder(updatedOrder);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order details updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating order: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).then((_) {
      // Clean up the controller
      notesController.dispose();
    });
  }

  void _showEditItemDialog(PurchaseOrderItem item) {
    final TextEditingController quantityController =
        TextEditingController(text: item.quantity.toString());
    final TextEditingController priceController =
        TextEditingController(text: item.unitPrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<InventoryProvider>(
              builder: (context, provider, _) {
                final inventoryItem = provider.getItemById(item.itemId);
                return Text('Item: ${inventoryItem?.name ?? 'Unknown Item'}');
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Unit Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (quantity > 0 && price > 0) {
                final updatedItem = item.copyWith(
                  quantity: quantity,
                  unitPrice: price,
                  totalPrice: quantity * price,
                );

                await DatabaseHelper.instance
                    .updatePurchaseOrderItem(updatedItem);
                if (mounted) {
                  Provider.of<InventoryProvider>(context, listen: false)
                      .refreshInventory();
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(PurchaseOrderItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text(
            'Are you sure you want to remove this item from the order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseHelper.instance.deletePurchaseOrderItem(item.id!);
              if (mounted) {
                Provider.of<InventoryProvider>(context, listen: false)
                    .refreshInventory();
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeleteOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this order?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Order Number: ${widget.order.orderNumber}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Consumer<BusinessProvider>(
              builder: (context, provider, _) {
                final supplier = provider.selectedSupplier;
                return Text(
                  'Supplier: ${supplier?.name ?? 'Unknown Supplier'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All order data will be permanently deleted.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                // Delete the order
                await Provider.of<InventoryProvider>(context, listen: false)
                    .deletePurchaseOrder(widget.order.id!);

                if (mounted) {
                  // Close both dialogs
                  Navigator.pop(context); // Close confirmation dialog
                  Navigator.pop(context); // Close order details dialog

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close confirmation dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting order: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Order'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
