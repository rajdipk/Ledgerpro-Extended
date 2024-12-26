// ignore_for_file: use_build_context_synchronously, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_movement_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/barcode_scanner_dialog.dart';

class AddMovementDialog extends StatefulWidget {
  final InventoryItem? selectedItem;

  const AddMovementDialog({
    Key? key,
    this.selectedItem,
  }) : super(key: key);

  @override
  _AddMovementDialogState createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late InventoryItem? _selectedItem;
  String _movementType = 'IN';
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    if (_selectedItem != null) {
      _priceController.text = _movementType == 'IN'
          ? _selectedItem!.costPrice.toString()
          : _selectedItem!.sellingPrice.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) {
      return;
    }

    final movement = StockMovement(
      businessId: _selectedItem!.businessId,
      itemId: _selectedItem!.id!,
      movementType: _movementType,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_priceController.text),
      totalPrice: double.parse(_priceController.text) *
          int.parse(_quantityController.text),
      referenceType: _referenceController.text,
      notes: _notesController.text,
      date: _selectedDate.toIso8601String(),
    );

    try {
      await Provider.of<InventoryProvider>(context, listen: false)
          .addMovement(movement);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding movement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildItemDropdown() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final items = provider.items.where((item) {
          final searchLower = _searchQuery.toLowerCase();
          return item.name.toLowerCase().contains(searchLower) ||
              (item.sku?.toLowerCase().contains(searchLower) ?? false) ||
              (item.barcode?.toLowerCase().contains(searchLower) ?? false);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Items',
                      hintText: 'Search by name, SKU, or barcode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const BarcodeScannerDialog(),
                    );
                    
                    if (result != null && mounted) {
                      final barcode = result['barcode'] as String;
                      setState(() {
                        _searchController.text = barcode;
                        _searchQuery = barcode;
                      });
                      
                      // Auto-select the item if there's an exact barcode match
                      final matchedItem = provider.items.firstWhere(
                        (item) => item.barcode == barcode,
                        orElse: () => provider.items.firstWhere(
                          (item) => item.sku == barcode,
                          orElse: () => provider.items.first,
                        ),
                      );
                      
                      setState(() {
                        _selectedItem = matchedItem;
                        _priceController.text = _movementType == 'IN'
                            ? matchedItem.costPrice.toString()
                            : matchedItem.sellingPrice.toString();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Select Item ${items.isNotEmpty ? '(${items.length} items)' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedItem?.id == item.id;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                              _priceController.text = _movementType == 'IN'
                                  ? item.costPrice.toString()
                                  : item.sellingPrice.toString();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.withOpacity(0.1)
                                  : null,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SKU: ${item.sku ?? 'N/A'} | Current Stock: ${item.currentStock} ${item.unit}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Category: ${item.category ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: Colors.teal),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedItem == null) ...[
              const SizedBox(height: 8),
              Text(
                'Please select an item',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMovementTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Movement Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Stock In'),
                value: 'IN',
                groupValue: _movementType,
                activeColor: Colors.teal,
                onChanged: (value) {
                  setState(() {
                    _movementType = value!;
                    if (_selectedItem != null) {
                      _priceController.text =
                          _selectedItem!.costPrice.toString();
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
                activeColor: Colors.teal,
                onChanged: (value) {
                  setState(() {
                    _movementType = value!;
                    if (_selectedItem != null) {
                      _priceController.text =
                          _selectedItem!.sellingPrice.toString();
                    }
                  });
                },
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            helperText: helperText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 600.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(_selectedItem != null ? 'Add Movement for ${_selectedItem!.name}' : 'Add Stock Movement'),
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
                            if (_movementType == 'OUT' &&
                                _selectedItem != null &&
                                int.parse(value) > _selectedItem!.currentStock) {
                              return 'Insufficient stock';
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Save Movement',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
}