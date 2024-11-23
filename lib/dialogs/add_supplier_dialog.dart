// add_supplier_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/supplier_model.dart';
import '../database/supplier_operations.dart';
import '../database/database_helper.dart';
import '../providers/business_provider.dart';

class AddSupplierDialog extends StatefulWidget {
  final int businessId;
  final Function(Supplier)? onSupplierAdded;

  const AddSupplierDialog({
    super.key,
    required this.businessId,
    this.onSupplierAdded,
  });

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();
  late final SupplierOperations _supplierOps;

  @override
  void initState() {
    super.initState();
    _supplierOps = SupplierOperations(DatabaseHelper.instance);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Supplier'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name*',
                  hintText: 'Enter supplier name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter supplier address',
                ),
                maxLines: 2,
              ),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST Number',
                  hintText: 'Enter GST number',
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
              ),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN',
                  hintText: 'Enter PAN number',
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final supplier = Supplier(
                id: 0,
                businessId: widget.businessId,
                name: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                gstin: _gstController.text,
                pan: _panController.text,
              );

              try {
                final newSupplier = await _supplierOps.addSupplier(supplier);
                if (mounted) {
                  Navigator.of(context).pop();
                  // Refresh supplier count in BusinessProvider
                  await Provider.of<BusinessProvider>(context, listen: false).refreshSuppliers();
                  widget.onSupplierAdded?.call(newSupplier);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supplier added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding supplier: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}