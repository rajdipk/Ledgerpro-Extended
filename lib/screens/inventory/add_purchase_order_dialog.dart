// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/purchase_order_model.dart';
import '../../models/supplier_model.dart';
import '../../models/inventory_item_model.dart';
import '../../widgets/barcode_scanner_dialog.dart';
import 'package:intl/intl.dart';
import '../../dialogs/add_supplier_dialog.dart';
import '../../providers/currency_provider.dart';

class AddPurchaseOrderDialog extends StatefulWidget {
  const AddPurchaseOrderDialog({super.key});

  @override
  _AddPurchaseOrderDialogState createState() => _AddPurchaseOrderDialogState();
}

class _AddPurchaseOrderDialogState extends State<AddPurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _expectedDeliveryDate;
  Supplier? _selectedSupplier;
  final List<PurchaseOrderItem> _items = [];
  String _orderNumber = '';

  @override
  void initState() {
    super.initState();
    _generateOrderNumber();
  }

  Future<void> _generateOrderNumber() async {
    final businessId = Provider.of<InventoryProvider>(context, listen: false)
        .selectedBusinessId;
    final orderNumber =
        await DatabaseHelper.instance.generatePurchaseOrderNumber(businessId);
    setState(() {
      _orderNumber = orderNumber;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenSize.width * 0.95 : 1200,
          maxHeight: isSmallScreen ? screenSize.height * 0.95 : 900,
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              title: const Text(
                'Create Purchase Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isSmallScreen) {
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildOrderInformationCard(context, isDesktop: false),
                                  const SizedBox(height: 16),
                                  _buildOrderItemsCard(context, isDesktop: false),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_items.isNotEmpty)
                          _buildTotalSection(context, isDesktop: false),
                      ],
                    );
                  } else if (isMediumScreen) {
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildOrderInformationCard(context, isDesktop: false),
                                  const SizedBox(height: 24),
                                  _buildOrderItemsCard(context, isDesktop: false),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_items.isNotEmpty)
                          _buildTotalSection(context, isDesktop: true),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildOrderInformationCard(context, isDesktop: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: Colors.teal.withOpacity(0.2),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: _buildOrderItemsCard(context, isDesktop: true),
                                ),
                              ),
                              if (_items.isNotEmpty)
                                _buildTotalSection(context, isDesktop: true),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInformationCard(BuildContext context, {required bool isDesktop}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Order Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                        'Order Number',
                        TextEditingController(text: _orderNumber),
                        enabled: false,
                        prefixIcon: Icons.tag,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _buildSupplierDropdown(),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Notes',
                        _notesController,
                        maxLines: 3,
                        prefixIcon: Icons.note,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              'Order Number',
                              TextEditingController(text: _orderNumber),
                              enabled: false,
                              prefixIcon: Icons.tag,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDatePicker()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSupplierDropdown(),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Notes',
                        _notesController,
                        maxLines: 3,
                        prefixIcon: Icons.note,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, {required bool isDesktop}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (!isMobile) ...[
                          FilledButton.icon(
                            onPressed: () => _showBarcodeScanner(),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Barcode'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _showAddItemDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ],
                    ),
                    if (isMobile) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showBarcodeScanner(),
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan Barcode'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showAddItemDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items added yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Item" to start adding items to your order',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildItemsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => _buildMobileItemTile(index, context),
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Unit Price')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('')),
                ],
                rows: _items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildDesktopItemRow(index, item, context);
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  DataRow _buildDesktopItemRow(int index, PurchaseOrderItem item, BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final inventoryItem = inventoryProvider.getItemById(item.itemId);

    return DataRow(
      cells: [
        DataCell(Text(inventoryItem?.name ?? 'Unknown')),
        DataCell(Text(inventoryItem?.sku ?? 'N/A')),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileItemTile(int index, BuildContext context) {
    final item = _items[index];
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final inventoryItem = provider.getItemById(item.itemId);
        if (inventoryItem == null) return const SizedBox.shrink();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            inventoryItem.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'SKU: ${inventoryItem.sku ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, _) => Text(
                  'Quantity: ${item.quantity} × ${NumberFormat.currency(symbol: currencyProvider.currencySymbol, decimalDigits: 2).format(item.unitPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, _) => Text(
                  NumberFormat.currency(
                    symbol: currencyProvider.currencySymbol,
                    decimalDigits: 2,
                  ).format(item.totalPrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSection(BuildContext context, {required bool isDesktop}) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.teal.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile) ...[
            Text(
              'Total:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
          ],
          Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, _) => Text(
              NumberFormat.currency(
                symbol: currencyProvider.currencySymbol,
                decimalDigits: 2,
              ).format(_calculateTotal()),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 24 : 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _savePurchaseOrder,
            icon: const Icon(Icons.save),
            label: Text(isMobile ? 'Save' : 'Save Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.teal) : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.teal,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Order Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
        ),
        child: Text(
          DateFormat('MMM dd, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return Row(
      children: [
        Expanded(
          child: Consumer<BusinessProvider>(
            builder: (context, businessProvider, _) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getSuppliers(
                  int.parse(businessProvider.selectedBusinessId ?? '0'),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No suppliers found');
                  }

                  final suppliers = snapshot.data!.map((map) => Supplier(
                    id: map['id'] as int,
                    businessId: map['business_id'] as int,
                    name: map['name'] as String,
                    phone: (map['phone'] as String?) ?? '',
                    address: (map['address'] as String?) ?? '',
                    pan: (map['pan'] as String?) ?? '',
                    gstin: (map['gstin'] as String?) ?? '',
                    balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
                  )).toList();

                  return DropdownButtonFormField<Supplier>(
                    value: _selectedSupplier,
                    decoration: InputDecoration(
                      labelText: 'Select Supplier',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                    ),
                    items: suppliers.map((supplier) {
                      return DropdownMenuItem<Supplier>(
                        value: supplier,
                        child: Text(supplier.name),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a supplier';
                      }
                      return null;
                    },
                    onChanged: (Supplier? newValue) {
                      setState(() {
                        _selectedSupplier = newValue;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final businessId = Provider.of<BusinessProvider>(context, listen: false)
                .selectedBusinessId;
            if (businessId == null) return;

            final supplier = await showDialog<Supplier>(
              context: context,
              builder: (context) => AddSupplierDialog(
                businessId: int.parse(businessId),
              ),
            );

            if (supplier != null) {
              setState(() {
                _selectedSupplier = supplier;
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Supplier'),
        ),
      ],
    );
  }

  Future<void> _showBarcodeScanner() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const BarcodeScannerDialog(),
      );

      if (result != null) {
        final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
        final items = inventoryProvider.items;

        final item = items.firstWhere(
          (item) => item.barcode == result || item.sku == result,
          orElse: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item not found')),
            );
            return throw Exception('Item not found');
          },
        );

        _showAddItemDialog(preSelectedItem: item);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing barcode: $e')),
      );
    }
  }

  void _showAddItemDialog({InventoryItem? preSelectedItem}) {
    showDialog(
      context: context,
      builder: (context) => _AddOrderItemDialog(
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
          });
        },
        preSelectedItem: preSelectedItem,
      ),
    );
  }

  double _calculateTotal() {
    return _items.fold(
        0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  Future<void> _savePurchaseOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')),
        );
        return;
      }

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      final now = DateTime.now().toIso8601String();
      final purchaseOrder = PurchaseOrder(
        id: 0, // Will be set by database
        businessId: Provider.of<InventoryProvider>(context, listen: false)
            .selectedBusinessId,
        supplierId:
            _selectedSupplier!.id, // Using null check since we validated above
        orderNumber: _orderNumber,
        status: 'DRAFT',
        totalAmount: _calculateTotal(),
        notes: _notesController.text,
        orderDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        expectedDate: _expectedDeliveryDate != null
            ? DateFormat('yyyy-MM-dd').format(_expectedDeliveryDate!)
            : null,
        receivedDate: null,
        createdAt: now,
        updatedAt: now,
        items: _items
            .map((item) => PurchaseOrderItem(
                  id: 0,
                  purchaseOrderId: 0,
                  itemId: item.itemId,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  totalPrice: item.totalPrice,
                  receivedQuantity: 0,
                ))
            .toList(),
      );

      try {
        final provider = Provider.of<InventoryProvider>(context, listen: false);
        await provider.addPurchaseOrder(purchaseOrder);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating purchase order: $e')),
        );
      }
    }
  }
}

class _AddOrderItemDialog extends StatefulWidget {
  final Function(PurchaseOrderItem) onItemAdded;
  final InventoryItem? preSelectedItem;

  const _AddOrderItemDialog({
    required this.onItemAdded,
    this.preSelectedItem,
  });

  @override
  _AddOrderItemDialogState createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<_AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  InventoryItem? _selectedItem;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedItem != null) {
      _selectedItem = widget.preSelectedItem;
      _unitPriceController.text = widget.preSelectedItem!.costPrice.toString();
    }
    _updateFilteredItems('');
  }

  void _updateFilteredItems(String query) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    setState(() {
      _filteredItems = provider.items.where((item) {
        final searchLower = query.toLowerCase();
        final nameLower = item.name.toLowerCase();
        final skuLower = (item.sku ?? '').toLowerCase();
        final barcodeLower = (item.barcode ?? '').toLowerCase();

        return nameLower.contains(searchLower) ||
               skuLower.contains(searchLower) ||
               barcodeLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenSize.width * 0.95 : 600,
          maxHeight: isSmallScreen ? screenSize.height * 0.95 : 700,
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_shopping_cart, color: Colors.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Order Item',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isSmallScreen) const SizedBox(height: 4),
                          if (!isSmallScreen)
                            Text(
                              'Add items to your purchase order',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Items',
                              hintText: 'Search by name, SKU, or barcode',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (context) => const BarcodeScannerDialog(),
                                  );
                                  if (result != null) {
                                    _searchController.text = result;
                                    _updateFilteredItems(result);
                                  }
                                },
                              ),
                            ),
                            onChanged: _updateFilteredItems,
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<InventoryItem>(
                            decoration: const InputDecoration(
                              labelText: 'Select Item',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedItem,
                            items: _filteredItems.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text('${item.name} (${item.sku ?? 'No SKU'})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedItem = value;
                                if (value != null) {
                                  _unitPriceController.text = value.costPrice.toString();
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select an item';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a quantity';
                                    }
                                    final quantity = int.tryParse(value);
                                    if (quantity == null || quantity <= 0) {
                                      return 'Please enter a valid quantity';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {}); // Trigger rebuild for total price
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Consumer<CurrencyProvider>(
                                  builder: (context, currencyProvider, _) {
                                    return TextFormField(
                                      controller: _unitPriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Unit Price',
                                        border: const OutlineInputBorder(),
                                        prefixText: currencyProvider.currencySymbol,
                                        prefixStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a unit price';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        setState(() {}); // Trigger rebuild for total price
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Consumer<CurrencyProvider>(
                            builder: (context, currencyProvider, _) {
                              final quantity = int.tryParse(_quantityController.text) ?? 0;
                              final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
                              final total = quantity * unitPrice;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.teal.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantity:',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        Text(
                                          quantity.toString(),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Unit Price:',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        Text(
                                          NumberFormat.currency(
                                            symbol: currencyProvider.currencySymbol,
                                            decimalDigits: 2,
                                          ).format(unitPrice),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total:',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        Text(
                                          NumberFormat.currency(
                                            symbol: currencyProvider.currencySymbol,
                                            decimalDigits: 2,
                                          ).format(total),
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Order'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final itemId = _selectedItem?.id;
    if (itemId == null) return;

    final quantity = int.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);

    if (quantity == null || unitPrice == null) return;

    final newItem = PurchaseOrderItem(
      id: 0,
      purchaseOrderId: 0,
      itemId: itemId,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      receivedQuantity: 0,
    );

    widget.onItemAdded(newItem);
    Navigator.of(context).pop();
  }
}
