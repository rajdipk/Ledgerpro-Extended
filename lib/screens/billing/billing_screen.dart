// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer_model.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import 'select_customer_dialog.dart';
import 'add_bill_item_dialog.dart';
import '../../services/print_service.dart';
import '../../widgets/barcode_scanner_dialog.dart'; // Import BarcodeScannerDialog

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _selectCustomer(BuildContext context) async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (context) => const SelectCustomerDialog(),
    );

    if (customer != null) {
      final businessId = Provider.of<BusinessProvider>(context, listen: false)
          .selectedBusinessId;
      if (businessId != null) {
        Provider.of<BillProvider>(context, listen: false)
            .startNewBill(int.parse(businessId), customer);
      }
    }
  }

  void _addItem(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddBillItemDialog(),
    );

    if (result != null) {
      final item = result['item'] as InventoryItem;
      final quantity = result['quantity'] as int;
      Provider.of<BillProvider>(context, listen: false)
          .addItem(item, quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: KeyboardShortcutsService.getShortcuts(context),
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback.call(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 2,
              title: const Text(
                'Create Bill',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              actions: [
                Tooltip(
                  message: 'Scan Barcode (Ctrl+B)',
                  child: IconButton.outlined(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _scanBarcode(context),
                  ),
                ),
                const SizedBox(width: 8),
                if (Provider.of<BillProvider>(context, listen: false).currentBill != null) ...[
                  Tooltip(
                    message: 'Print Bill (Ctrl+P)',
                    child: IconButton.outlined(
                      icon: const Icon(Icons.print),
                      onPressed: () async {
                        try {
                          await PrintService.printBill(
                            Provider.of<BillProvider>(context, listen: false).currentBill!,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error printing bill: ${e.toString()}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (Provider.of<BillProvider>(context).missingItems.isNotEmpty)
                  Badge(
                    label: Text(Provider.of<BillProvider>(context).missingItems.length.toString()),
                    child: IconButton.outlined(
                      icon: const Icon(Icons.warning_amber, color: Colors.amber),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Missing Items'),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'The following items could not be loaded:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...Provider.of<BillProvider>(context)
                                      .missingItems
                                      .map((item) => Card(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            child: ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.error_outline, color: Colors.amber),
                                              title: Text(item),
                                            ),
                                          )),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  Provider.of<BillProvider>(context, listen: false)
                                      .clearMissingItems();
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear All'),
                              ),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                label: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: Consumer<BillProvider>(
              builder: (context, billProvider, child) {
                final bill = billProvider.currentBill;

                return Row(
                  children: [
                    // Left Panel - Bill Form
                    Expanded(
                      flex: 3,
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Customer Selection
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Customer Details',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const Spacer(),
                                      FilledButton.icon(
                                        onPressed: () => _selectCustomer(context),
                                        icon: Icon(bill == null ? Icons.person_add : Icons.edit),
                                        label: Text(bill == null ? 'Select' : 'Change'),
                                      ),
                                    ],
                                  ),
                                  if (bill != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bill.customer.name,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (bill.customer.phone.isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(bill.customer.phone),
                                              ],
                                            ),
                                          if (bill.customer.address.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    bill.customer.address,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (bill.customer.balance != 0) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: bill.customer.balance >= 0
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    bill.customer.balance >= 0
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    size: 16,
                                                    color: bill.customer.balance >= 0
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Balance: ₹${bill.customer.balance.abs().toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: bill.customer.balance >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Items List
                            Expanded(
                              child: bill == null || bill.items.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 64,
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No items added',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: Theme.of(context).colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Scan barcode or add items manually',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () => _scanBarcode(context),
                                                icon: const Icon(Icons.qr_code_scanner),
                                                label: const Text('Scan Barcode'),
                                              ),
                                              const SizedBox(width: 16),
                                              FilledButton.icon(
                                                onPressed: () => _addItem(context),
                                                icon: const Icon(Icons.add_shopping_cart),
                                                label: const Text('Add Item'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: bill.items.length,
                                      itemBuilder: (context, index) {
                                        final item = bill.items[index];
                                        return Dismissible(
                                          key: ValueKey(item.item.id),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.errorContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 16.0),
                                            child: Icon(
                                              Icons.delete,
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                          onDismissed: (_) => billProvider.removeItem(index),
                                          child: Card(
                                            child: ListTile(
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.item.name,
                                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${item.totalWithGst.toStringAsFixed(2)}',
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(2)}',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                      if (item.gstRate > 0) ...[
                                                        const Text(' • '),
                                                        Text(
                                                          'GST: ${item.gstRate}%',
                                                          style: Theme.of(context).textTheme.bodyMedium,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (item.notes?.isNotEmpty ?? false)
                                                    Text(
                                                      item.notes!,
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _editItemQuantity(context, index),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Panel - Bill Summary
                    if (bill != null && bill.items.isNotEmpty)
                      SizedBox(
                        width: 300,
                        child: Card(
                          margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bill Summary',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSummaryRow('Subtotal', bill.subTotal),
                                      if (bill.gstAmount > 0) ...[
                                        const Divider(height: 24),
                                        _buildSummaryRow('GST', bill.gstAmount),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          Text(
                                            'Discount',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _discountController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                prefixText: '₹',
                                                border: const OutlineInputBorder(),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    _discountController.text = '0.00';
                                                    billProvider.updateDiscount(0);
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                final discount = double.tryParse(value) ?? 0.0;
                                                billProvider.updateDiscount(discount);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Total',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  '₹${bill.total.toStringAsFixed(2)}',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            if (bill.customer.balance != 0) ...[
                                              const Divider(height: 24),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('Previous Balance'),
                                                  Text(
                                                    '₹${bill.customer.balance.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: bill.customer.balance >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('Final Balance'),
                                                  Text(
                                                    '₹${(bill.customer.balance + bill.total).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: bill.customer.balance + bill.total >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TextFormField(
                                        controller: _notesController,
                                        decoration: const InputDecoration(
                                          labelText: 'Notes',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.note),
                                        ),
                                        maxLines: 3,
                                        onChanged: (value) => billProvider.updateNotes(value),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () => _saveBill(context),
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save Bill'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        billProvider.cancelBill();
                                        _notesController.clear();
                                        _discountController.text = '0.00';
                                      },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addItem(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add Item'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => BarcodeScannerDialog(
          continuousMode: true,
          onMultiScan: (barcodes) async {
            final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
            final List<InventoryItem> items = [];
            final List<String> notFound = [];

            // Find items for each barcode
            for (final barcode in barcodes) {
              try {
                final item = inventoryProvider.items.firstWhere(
                  (item) => item.barcode == barcode,
                  orElse: () => inventoryProvider.items.firstWhere(
                    (item) => item.sku == barcode,
                    orElse: () => throw Exception('Item not found'),
                  ),
                );
                items.add(item);
              } catch (e) {
                notFound.add(barcode);
              }
            }

            // Show not found items if any
            if (notFound.isNotEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Items not found: ${notFound.join(", ")}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }

            // Add found items to bill
            for (final item in items) {
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (context) => AddBillItemDialog(
                    preSelectedItem: item,
                  ),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editItemQuantity(BuildContext context, int index) {
    final bill = Provider.of<BillProvider>(context, listen: false).currentBill;
    if (bill == null) return;

    final item = bill.items[index];
    final controller = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 0;
              if (quantity > 0 && quantity <= item.item.currentStock) {
                Provider.of<BillProvider>(context, listen: false)
                    .updateItemQuantity(index, quantity);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid quantity (1-${item.item.currentStock})',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBill(BuildContext context) async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    try {
      await billProvider.saveBill();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _notesController.clear();
        _discountController.text = '0.00';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bill: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
