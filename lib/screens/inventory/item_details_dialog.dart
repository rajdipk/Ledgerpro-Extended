// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_movement_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/currency_provider.dart';
import 'package:intl/intl.dart';

class ItemDetailsDialog extends StatefulWidget {
  final InventoryItem item;

  const ItemDetailsDialog({super.key, required this.item});

  @override
  _ItemDetailsDialogState createState() => _ItemDetailsDialogState();
}

class _ItemDetailsDialogState extends State<ItemDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _categoryController;
  late TextEditingController _unitController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _costPriceController;
  late TextEditingController _reorderLevelController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(text: widget.item.description);
    _skuController = TextEditingController(text: widget.item.sku);
    _barcodeController = TextEditingController(text: widget.item.barcode);
    _categoryController = TextEditingController(text: widget.item.category);
    _unitController = TextEditingController(text: widget.item.unit);
    _sellingPriceController = TextEditingController(text: widget.item.sellingPrice.toString());
    _costPriceController = TextEditingController(text: widget.item.costPrice.toString());
    _reorderLevelController = TextEditingController(text: widget.item.reorderLevel.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _reorderLevelController.dispose();
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
              title: Text(widget.item.name),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditing) {
                      _saveChanges();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
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
                      _buildDetailsSection(context),
                      const Divider(height: 32),
                      _buildStockMovementsSection(),
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

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Name', _nameController.text, context),
        _buildDetailRow('Description', _descriptionController.text, context),
        _buildDetailRow('SKU', _skuController.text, context),
        _buildDetailRow('Barcode', _barcodeController.text, context),
        _buildDetailRow('Category', _categoryController.text, context),
        _buildDetailRow('Unit', _unitController.text, context),
        _buildDetailRow('Selling Price', double.parse(_sellingPriceController.text), context, isPrice: true),
        _buildDetailRow('Cost Price', double.parse(_costPriceController.text), context, isPrice: true),
        _buildDetailRow('Reorder Level', _reorderLevelController.text, context),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: ${widget.item.currentStock}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, _) => Text(
                    'Stock Value: ${NumberFormat.currency(
                      symbol: currencyProvider.currencySymbol,
                      decimalDigits: 2,
                    ).format(widget.item.currentStock * widget.item.costPrice)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockMovementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock Movements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<InventoryProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<List<StockMovement>>(
              future: provider.getItemMovements(widget.item.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No stock movements found'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final movement = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          movement.movementType == 'IN'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: movement.movementType == 'IN'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          '${movement.movementType}: ${movement.quantity} units',
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(movement.date),
                          ),
                        ),
                        trailing: Text(
                          NumberFormat.currency(symbol: '\$')
                              .format(movement.totalPrice),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value, BuildContext context, {bool isPrice = false}) {
    if (isPrice) {
      return Consumer<CurrencyProvider>(
        builder: (context, currencyProvider, _) {
          final displayValue = NumberFormat.currency(
            symbol: currencyProvider.currencySymbol,
            decimalDigits: 2,
          ).format(value as double);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(displayValue),
                ),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    try {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        category: _categoryController.text,
        unit: _unitController.text,
        sellingPrice: double.parse(_sellingPriceController.text),
        costPrice: double.parse(_costPriceController.text),
        reorderLevel: int.parse(_reorderLevelController.text),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await Provider.of<InventoryProvider>(context, listen: false)
          .updateItem(updatedItem);

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    }
  }
}