// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/barcode_scanner_dialog.dart';
import '../../utils/sku_generator.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _initialStockController = TextEditingController();
  bool _autoGenerateSku = true;
  bool _isCustomUnit = false;

  // Common units for inventory items
  static const List<String> commonUnits = [
    'Pieces (pcs)',
    'Kilograms (kg)',
    'Grams (g)',
    'Liters (L)',
    'Milliliters (ml)',
    'Meters (m)',
    'Centimeters (cm)',
    'Square Meters (m²)',
    'Boxes',
    'Pairs',
    'Dozens',
    'Pouches',
    'Bags',
    'Custom...',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateSkuIfAuto);
    _categoryController.addListener(_updateSkuIfAuto);
    _unitController.text = commonUnits[0]; // Default to 'Pieces (pcs)'
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateSkuIfAuto);
    _categoryController.removeListener(_updateSkuIfAuto);
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _customUnitController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _reorderLevelController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  void _updateSkuIfAuto() async {
    if (_autoGenerateSku && _nameController.text.isNotEmpty) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final itemCount = provider.items.length;
      final generatedSku = SkuGenerator.generateSku(
        _nameController.text,
        _categoryController.text,
        itemCount,
      );
      _skuController.text = generatedSku;
    }
  }

  Widget _buildSkuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skuController,
                enabled: !_autoGenerateSku,
                decoration: InputDecoration(
                  labelText: 'SKU (Stock Keeping Unit)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: _autoGenerateSku ? Colors.grey[100] : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter or generate an SKU';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _autoGenerateSku 
                ? 'Auto-generating SKU based on name and category' 
                : 'Switch to auto-generate SKU',
              child: IconButton(
                icon: Icon(
                  _autoGenerateSku ? Icons.autorenew : Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _autoGenerateSku = !_autoGenerateSku;
                    if (_autoGenerateSku) {
                      _updateSkuIfAuto();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        if (_autoGenerateSku)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'SKU will be auto-generated based on category and name',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines ?? 1,
    );
  }

  Widget _buildPriceFormField(String label, TextEditingController controller, BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '${currencyProvider.currencySymbol} ',
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a $label';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCustomUnit)
          DropdownButtonFormField<String>(
            value: _unitController.text.isEmpty ? commonUnits[0] : _unitController.text,
            decoration: InputDecoration(
              labelText: 'Unit of Measurement',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: commonUnits.map((String unit) {
              return DropdownMenuItem<String>(
                value: unit,
                child: Text(unit),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                if (newValue == 'Custom...') {
                  _isCustomUnit = true;
                  _unitController.clear();
                } else {
                  _unitController.text = newValue ?? commonUnits[0];
                }
              });
            },
          ),
        if (_isCustomUnit) ...[
          TextFormField(
            controller: _customUnitController,
            decoration: InputDecoration(
              labelText: 'Custom Unit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isCustomUnit = false;
                    _customUnitController.clear();
                    _unitController.text = commonUnits[0];
                  });
                },
                tooltip: 'Switch back to common units',
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a unit';
              }
              return null;
            },
            onChanged: (value) {
              _unitController.text = value;
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your custom unit of measurement (e.g., "Rolls", "Sets")',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final now = DateTime.now().toIso8601String();

      final newItem = InventoryItem(
        businessId: provider.selectedBusinessId,
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        category: _categoryController.text,
        unit: _unitController.text,
        sellingPrice: double.parse(_sellingPriceController.text),
        costPrice: double.parse(_costPriceController.text),
        weightedAverageCost: double.parse(_costPriceController.text),
        reorderLevel: int.parse(_reorderLevelController.text),
        currentStock: int.parse(_initialStockController.text),
        createdAt: now,
        updatedAt: now,
      );

      await provider.addItem(newItem);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    }
  }
  
  void _scanBarcode() async {
    debugPrint('Starting barcode scan...');
    try {
      debugPrint('Opening BarcodeScannerDialog...');
      final String? result = await showDialog<String>(
        context: context,
        builder: (context) {
          debugPrint('Building BarcodeScannerDialog...');
          return const BarcodeScannerDialog();
        },
      );

      debugPrint('Barcode scan result: $result');

      if (result != null && mounted) {
        debugPrint('Setting barcode: $result');
        setState(() {
          _barcodeController.text = result;
        });
      } else {
        debugPrint('No barcode result received or widget not mounted');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _scanBarcode: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning barcode: $e')),
        );
      }
    }
  }
    
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 600.0;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
          maxWidth: 800,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(contentPadding),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_box, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Add New Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // IconButton(
                  //   icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  //   onPressed: _scanBarcode,
                  //   tooltip: 'Scan Barcode',
                  // ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Basic Information'),
                      _buildTextFormField(
                        'Name',
                        _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Description',
                        _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Classification'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              'Barcode',
                              _barcodeController,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                            tooltip: 'Scan Barcode',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Category',
                        _categoryController,
                      ),
                      const SizedBox(height: 16),
                      _buildSkuField(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Pricing'),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? double.infinity : (dialogWidth - contentPadding * 3) / 2,
                            child: _buildPriceFormField('Purchase Price', _costPriceController, context),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : (dialogWidth - contentPadding * 3) / 2,
                            child: _buildPriceFormField('Selling Price', _sellingPriceController, context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Stock Information'),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? double.infinity : (dialogWidth - contentPadding * 3) / 2,
                            child: _buildTextFormField(
                              'Initial Stock',
                              _initialStockController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter initial stock';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : (dialogWidth - contentPadding * 3) / 2,
                            child: _buildTextFormField(
                              'Reorder Level',
                              _reorderLevelController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter reorder level';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Additional Information'),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? double.infinity : (dialogWidth - contentPadding * 3) / 2,
                            child: _buildUnitField(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Item',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.teal[700],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
