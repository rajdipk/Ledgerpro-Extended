// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer_model.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../bills/bills_screen.dart';
import '../home_screen.dart';
import 'select_customer_dialog.dart';
import 'add_bill_item_dialog.dart';
import '../../widgets/barcode_scanner_dialog.dart'; // Import BarcodeScannerDialog
// Import NavigationPanel

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  final TextEditingController _deliveryChargeController =
      TextEditingController(text: '0');
  final TextEditingController _gstRateController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = Provider.of<BusinessProvider>(context, listen: false)
          .selectedBusinessId;
      debugPrint('BillingScreen - Selected Business ID: $businessId');
      if (businessId != null) {
        final intBusinessId = int.parse(businessId);
        debugPrint('BillingScreen - Parsed Business ID: $intBusinessId');
        // Set business ID for both providers
        Provider.of<InventoryProvider>(context, listen: false)
            .setSelectedBusiness(intBusinessId);
        Provider.of<BillProvider>(context, listen: false)
            .setSelectedBusiness(intBusinessId);
      } else {
        debugPrint('BillingScreen - No business selected!');
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _deliveryChargeController.dispose();
    _gstRateController.dispose();
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
      final price = result['price'] as double;
      final gstRate = result['gstRate'] as double;
      debugPrint('Adding item to bill: $result');
      Provider.of<BillProvider>(context, listen: false).addItem(
        item,
        quantity,
        price: price,
        gstRate: gstRate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

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
              // Make app bar more responsive
              toolbarHeight: isNarrowScreen ? kToolbarHeight : 80,
              automaticallyImplyLeading: isNarrowScreen,
              title: Consumer<BillProvider>(
                builder: (context, provider, child) {
                  final bill = provider.currentBill;
                  return isNarrowScreen
                      ? Text(bill?.customer == null
                          ? 'New Bill'
                          : 'Bill for ${bill!.customer.name}')
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              bill?.customer == null
                                  ? 'New Bill'
                                  : 'Bill for ${bill!.customer.name}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        );
                },
              ),
              actions: [
                if (!isNarrowScreen) ...{
                  Consumer<BillProvider>(
                    builder: (context, provider, child) {
                      final bill = provider.currentBill;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bill?.customer != null) ...[
                            FilledButton.icon(
                              onPressed: () => _addItem(context),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Add Item'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (bill != null && bill.items.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Discard Bill?'),
                                    content: const Text(
                                        'Are you sure you want to discard this bill?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          provider.clearCurrentBill();
                                          _notesController.clear();
                                          _discountController.text = '0';
                                          _gstRateController.text = '0';
                                          _deliveryChargeController.text = '0';
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onError,
                                        ),
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(width: 16),
                        ],
                      );
                    },
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Bills'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    onPressed: () {
                      HomeScreen.of(context)
                          .switchContent(const BillsScreen(), '/bills');
                    },
                  ),
                  const SizedBox(width: 16),
                } else
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (context.read<BillProvider>().currentBill?.customer !=
                          null)
                        const PopupMenuItem(
                          value: 'add_item',
                          child: Text('Add Item'),
                        ),
                      const PopupMenuItem(
                        value: 'view_bills',
                        child: Text('View Bills'),
                      ),
                      if (context.read<BillProvider>().currentBill != null)
                        const PopupMenuItem(
                          value: 'clear_bill',
                          child: Text('Clear Bill'),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'add_item':
                          _addItem(context);
                          break;
                        case 'view_bills':
                          HomeScreen.of(context)
                              .switchContent(const BillsScreen(), '/bills');
                          break;
                        case 'clear_bill':
                          context.read<BillProvider>().clearCurrentBill();
                          break;
                      }
                    },
                  ),
              ],
            ),
            body: Consumer<BillProvider>(
              builder: (context, provider, child) {
                final bill = provider.currentBill;

                if (bill == null) {
                  return Center(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Start a New Bill',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select a customer to begin creating a new bill.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _selectCustomer(context),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Select Customer'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return _buildMobileLayout(bill);
                    } else {
                      return _buildDesktopLayout(bill);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Bill bill) {
    return Column(
      children: [
        if (bill.items.isEmpty) _buildEmptyBillHint(),
        Expanded(
          child: _buildBillItemsList(bill),
        ),
        SafeArea(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:'),
                      Text(
                        '₹${bill.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showMobileBalanceSummary(context, bill),
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _saveBill(context),
                          child: const Text('Save Bill'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Bill bill) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildBillItemsList(bill),
        ),
        if (bill.items.isNotEmpty)
          Expanded(
            flex: 2,
            child: _buildBalanceSummary(context, bill),
          ),
      ],
    );
  }

  void _showMobileBalanceSummary(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bill Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBalanceSummaryContent(context, bill),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillItemsList(Bill? bill) {
    if (bill == null || bill.items.isEmpty) {
      return const Center(
        child: Text('No items added to bill yet'),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Item',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  'Qty',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  'GST',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: Text(
                  'Price',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                alignment: Alignment.centerRight,
                child: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 48), // Space for delete button
            ],
          ),
        ),
        const Divider(),
        // Items List
        Expanded(
          child: Consumer<BillProvider>(
            builder: (context, billProvider, child) {
              final currentBill = billProvider.currentBill;
              if (currentBill == null || currentBill.items.isEmpty) {
                return const Center(
                  child: Text('No items added to bill yet'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: currentBill.items.length,
                itemBuilder: (context, index) {
                  final item = currentBill.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (item.notes?.isNotEmpty ?? false)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: GestureDetector(
                              onTap: () => _editItemQuantity(context, index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.gstRate}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '₹${(item.totalWithGst).toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => Provider.of<BillProvider>(
                                      context,
                                      listen: false)
                                  .removeItem(index),
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
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(BuildContext context, Bill bill) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        context,
                        'Subtotal:',
                        '₹${bill.subTotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'GST:',
                        '₹${bill.gstAmount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'Delivery Charge:',
                        TextField(
                          controller: _deliveryChargeController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            final charge = double.tryParse(value) ?? 0;
                            Provider.of<BillProvider>(context, listen: false)
                                .updateDeliveryCharge(charge);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'Discount:',
                        TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            final discount = double.tryParse(value) ?? 0;
                            Provider.of<BillProvider>(context, listen: false)
                                .updateDiscount(discount);
                          },
                        ),
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        context,
                        'Total:',
                        '₹${bill.total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<BillProvider>(context, listen: false)
                          .cancelBill();
                      _notesController.clear();
                      _discountController.text = '0';
                      _deliveryChargeController.text = '0';
                      _gstRateController.text = '0';
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _saveBill(context),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Bill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    dynamic value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyMedium,
        ),
        if (value is String)
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
          )
        else
          SizedBox(
            width: 100,
            child: value,
          ),
      ],
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    );

    if (barcode != null) {
      final items = await Provider.of<InventoryProvider>(context, listen: false)
          .searchItems(barcode);
      if (items.isNotEmpty) {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const AddBillItemDialog(),
        );

        if (result != null) {
          Provider.of<BillProvider>(context, listen: false).addItem(
            result['item'] as InventoryItem,
            result['quantity'] as int,
            price: result['price'] as double,
            gstRate: result['gstRate'] as double,
          );
        }
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No item found with this barcode'),
          ),
        );
      }
    }
  }

  void _editItemQuantity(BuildContext context, int index) {
    final item = Provider.of<BillProvider>(context, listen: false)
        .currentBill!
        .items[index];
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
            text: item.quantity.toString());
        return AlertDialog(
          title: const Text('Edit Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantity',
              suffixText: 'Available: ${item.item.currentStock}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final quantity = int.tryParse(controller.text) ?? 0;
                if (quantity > 0) {
                  Provider.of<BillProvider>(context, listen: false)
                      .updateItemQuantity(index, quantity);
                }
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBill(BuildContext context) async {
    final provider = Provider.of<BillProvider>(context, listen: false);
    try {
      await provider.saveBill();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill saved successfully')),
      );
      // Clear controllers
      _notesController.clear();
      _discountController.text = '0';
      _deliveryChargeController.text = '0';
      _gstRateController.text = '0';
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bill: $e')),
      );
    }
  }

  Widget _buildEmptyBillHint() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Add items to the bill using the "Add Item" button above.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummaryContent(BuildContext context, Bill bill) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Subtotal'),
          trailing: Text('₹${bill.subTotal.toStringAsFixed(2)}'),
        ),
        if (bill.gstAmount > 0)
          ListTile(
            title: const Text('GST'),
            trailing: Text('₹${bill.gstAmount.toStringAsFixed(2)}'),
          ),
        ListTile(
          title: const Text('Delivery Charge'),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              controller: _deliveryChargeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                final charge = double.tryParse(value) ?? 0;
                Provider.of<BillProvider>(context, listen: false)
                    .updateDeliveryCharge(charge);
              },
            ),
          ),
        ),
        ListTile(
          title: const Text('Discount'),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                final discount = double.tryParse(value) ?? 0;
                Provider.of<BillProvider>(context, listen: false)
                    .updateDiscount(discount);
              },
            ),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text(
            'Total',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '₹${bill.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
