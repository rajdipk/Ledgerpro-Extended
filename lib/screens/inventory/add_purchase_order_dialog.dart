// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/purchase_order_model.dart';
import '../../models/supplier_model.dart';
import '../../models/inventory_item_model.dart';
import 'package:intl/intl.dart';

class AddPurchaseOrderDialog extends StatefulWidget {
  const AddPurchaseOrderDialog({super.key});

  @override
  _AddPurchaseOrderDialogState createState() => _AddPurchaseOrderDialogState();
}

class _AddPurchaseOrderDialogState extends State<AddPurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expectedDeliveryDate;
  final List<PurchaseOrderItem> _items = [];
  Supplier? _selectedSupplier;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _orderNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
              title: const Text('Create Purchase Order'),
              automaticallyImplyLeading: false,
              actions: [
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextFormField(
                          'Order Number',
                          _orderNumberController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an order number';
                            }
                            return null;
                          },
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
                        ),
                        const SizedBox(height: 24),
                        _buildItemsList(),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          onPressed: _showAddItemDialog,
                        ),
                        const SizedBox(height: 24),
                        if (_items.isNotEmpty)
                          ElevatedButton(
                            onPressed: _savePurchaseOrder,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Create Purchase Order',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines ?? 1,
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
        ),
        child: Text(
          DateFormat('MMM dd, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return Consumer<BusinessProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getSuppliers(
            int.parse(provider.selectedBusinessId ?? '0')
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No suppliers found');
            }

            final suppliers = snapshot.data!.map((map) => Supplier(
              id: map['id'],
              businessId: map['business_id'],
              name: map['name'],
              phone: map['phone'] ?? '',
              address: map['address'] ?? '',
              pan: map['pan'] ?? '',
              gstin: map['gstin'] ?? '',
              balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
            )).toList();

            return DropdownButtonFormField<Supplier>(
              decoration: const InputDecoration(
                labelText: 'Select Supplier',
                border: OutlineInputBorder(),
              ),
              value: _selectedSupplier,
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSupplier = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a supplier';
                }
                return null;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_items.isNotEmpty) ...[
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
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final inventoryItem = provider.getItemById(item.itemId);
                  if (inventoryItem == null) return const SizedBox.shrink();

                  return Card(
                    child: ListTile(
                      title: Text(inventoryItem.name),
                      subtitle: Text(
                        'Quantity: ${item.quantity} | Unit Price: ${NumberFormat.currency(symbol: '\$').format(item.unitPrice)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(item.totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$')
                        .format(_calculateTotal()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddOrderItemDialog(
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  double _calculateTotal() {
    return _items.fold(
        0, (total, item) => total + (item.quantity * item.unitPrice));
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
        businessId: Provider.of<InventoryProvider>(context, listen: false).selectedBusinessId,
        supplierId: _selectedSupplier!.id, // Using null check since we validated above
        orderNumber: _orderNumberController.text,
        status: 'DRAFT',
        totalAmount: _calculateTotal(),
        notes: _notesController.text,
        orderDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        expectedDate: _expectedDeliveryDate != null ? DateFormat('yyyy-MM-dd').format(_expectedDeliveryDate!) : null,
        receivedDate: null,
        createdAt: now,
        updatedAt: now,
        items: _items.map((item) => PurchaseOrderItem(
          id: 0,
          purchaseOrderId: 0,
          itemId: item.itemId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
          receivedQuantity: 0,
        )).toList(),
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

  const _AddOrderItemDialog({required this.onItemAdded});

  @override
  _AddOrderItemDialogState createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<_AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  InventoryItem? _selectedItem;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Order Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final items = provider.items;
                return DropdownButtonFormField<InventoryItem>(
                  decoration: const InputDecoration(
                    labelText: 'Select Item',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedItem,
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text('${item.name} (${item.sku ?? 'No SKU'})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItem = value;
                      if (value != null) {
                        _priceController.text = value.costPrice.toString();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an item';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addItem() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }

    final item = PurchaseOrderItem(
      id: 0, // Will be set by database
      purchaseOrderId: 0, // Will be set after order creation
      itemId: _selectedItem!.id!,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_priceController.text),
      totalPrice: int.parse(_quantityController.text) * double.parse(_priceController.text),
      receivedQuantity: 0,
    );

    setState(() {
      widget.onItemAdded(item);
    });

    // Clear the form
    _selectedItem = null;
    _quantityController.clear();
    _priceController.clear();
    Navigator.of(context).pop();
  }
}
