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
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 900,
        ),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            title: const Text('Create Purchase Order'),
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
                final isDesktop = constraints.maxWidth > 900;
                final isMobile = constraints.maxWidth <= 600;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildOrderInformationCard(theme),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildOrderItemsCard(theme),
                              ),
                            ),
                            if (_items.isNotEmpty)
                              _buildTotalSection(theme),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildOrderInformationCard(theme),
                                SizedBox(height: isMobile ? 16 : 24),
                                _buildOrderItemsCard(theme),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_items.isNotEmpty)
                        _buildTotalSection(theme),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInformationCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Order Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
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

  Widget _buildOrderItemsCard(ThemeData theme) {
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
                        Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Order Items',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
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
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items added yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Item" to start adding items to your order',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildItemsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => _buildMobileItemTile(index, theme),
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
                  return _buildDesktopItemRow(index, item, theme);
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  DataRow _buildDesktopItemRow(int index, PurchaseOrderItem item, ThemeData theme) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final inventoryItem = inventoryProvider.getItemById(item.itemId);
    
    return DataRow(
      cells: [
        DataCell(Text(inventoryItem?.name ?? 'Unknown')),
        DataCell(Text(inventoryItem?.sku ?? 'N/A')),
        DataCell(Text(item.quantity.toString())),
        DataCell(Text(NumberFormat.currency(symbol: '\$').format(item.unitPrice))),
        DataCell(Text(
          NumberFormat.currency(symbol: '\$').format(item.totalPrice),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        )),
        DataCell(
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileItemTile(int index, ThemeData theme) {
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
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'SKU: ${inventoryItem.sku ?? 'N/A'}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Quantity: ${item.quantity} × ${NumberFormat.currency(symbol: '\$').format(item.unitPrice)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                NumberFormat.currency(symbol: '\$').format(item.totalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total:',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(width: 16),
          Text(
            NumberFormat.currency(symbol: '\$').format(_calculateTotal()),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: _savePurchaseOrder,
            icon: const Icon(Icons.save),
            label: const Text('Save Order'),
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
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Order Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
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
                    decoration: const InputDecoration(
                      labelText: 'Select Supplier',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
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
                    onChanged: (Supplier? value) {
                      setState(() {
                        _selectedSupplier = value;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () async {
            final businessId = int.parse(
              Provider.of<BusinessProvider>(context, listen: false)
                  .selectedBusinessId ?? '0',
            );
            final result = await showDialog(
              context: context,
              builder: (context) => AddSupplierDialog(businessId: businessId),
            );
            if (result == true) {
              setState(() {}); // Refresh the supplier list
            }
          },
          icon: const Icon(Icons.add),
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_shopping_cart, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            'Add Order Item',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Items',
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a unit price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
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
