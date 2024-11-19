// ignore_for_file: use_build_context_synchronously, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_movement_model.dart';
import '../../providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class AddMovementDialog extends StatefulWidget {
  const AddMovementDialog({Key? key}) : super(key: key);

  @override
  _AddMovementDialogState createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  InventoryItem? _selectedItem;
  String _movementType = 'IN';
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Add Stock Movement'),
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
                        _buildItemDropdown(),
                        const SizedBox(height: 16),
                        _buildMovementTypeSelector(),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          'Quantity',
                          _quantityController,
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
                        _buildTextFormField(
                          'Price per Unit',
                          _priceController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          'Reference',
                          _referenceController,
                          helperText: 'e.g., Invoice number, PO number',
                        ),
                        _buildTextFormField(
                          'Notes',
                          _notesController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveMovement,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Save Movement',
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

  Widget _buildItemDropdown() {
    return Consumer<InventoryProvider>(
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
                _priceController.text = _movementType == 'IN'
                    ? value.costPrice.toString()
                    : value.unitPrice.toString();
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
    );
  }

  Widget _buildMovementTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Stock In'),
            value: 'IN',
            groupValue: _movementType,
            onChanged: (value) {
              setState(() {
                _movementType = value!;
                if (_selectedItem != null) {
                  _priceController.text = _selectedItem!.costPrice.toString();
                }
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Stock Out'),
            value: 'OUT',
            groupValue: _movementType,
            onChanged: (value) {
              setState(() {
                _movementType = value!;
                if (_selectedItem != null) {
                  _priceController.text = _selectedItem!.unitPrice.toString();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          helperText: helperText,
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines ?? 1,
      ),
    );
  }

  Future<void> _saveMovement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final movement = StockMovement(
        id: null,
        businessId: Provider.of<InventoryProvider>(context, listen: false).selectedBusinessId,
        itemId: _selectedItem!.id!,
        movementType: _movementType,
        quantity: int.parse(_quantityController.text),
        unitPrice: double.parse(_priceController.text),
        totalPrice: int.parse(_quantityController.text) * double.parse(_priceController.text),
        referenceType: null,
        referenceId: null,
        notes: _notesController.text,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      try {
        final provider = Provider.of<InventoryProvider>(context, listen: false);
        await provider.addMovement(movement);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock movement added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding stock movement: $e')),
        );
      }
    }
  }
}
