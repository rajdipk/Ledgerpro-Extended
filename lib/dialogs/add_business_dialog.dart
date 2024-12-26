// add_business_dialog.dart
// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../providers/currency_provider.dart';
import 'add_supplier_dialog.dart';

class AddBusinessDialog extends StatefulWidget {
  const AddBusinessDialog({super.key});

  @override
  _AddBusinessDialogState createState() => _AddBusinessDialogState();
}

class _AddBusinessDialogState extends State<AddBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _businessTypeController = TextEditingController();
  String _selectedCurrency = 'INR';

  final List<String> _currencies = [
    'INR',
    'USD',
    'EUR',
    'GBP',
    'AED',
    'AUD',
    'CAD',
    'CNY',
    'JPY',
    'SGD'
  ];

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _gstinFocusNode = FocusNode();
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _businessTypeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Update with the provider's value after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedCurrency = Provider.of<CurrencyProvider>(context, listen: false).currencyCode;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _businessTypeController.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _gstinFocusNode.dispose();
    _panFocusNode.dispose();
    _businessTypeFocusNode.dispose();
    super.dispose();
  }

  void _saveBusiness() async {
    if (_formKey.currentState!.validate()) {
      try {
        final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
        await businessProvider.addBusiness(_nameController.text);
        
        // Close the dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding business: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        content: Container(
          width: 400,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: Colors.teal[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Add Business',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[700]),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.business, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a business name' : null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.location_on, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.phone, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _gstinFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, child) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money, color: Colors.teal[700]),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                          ),
                        ),
                        items: _currencies.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                          }
                          _panFocusNode.requestFocus();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstinController,
                    focusNode: _gstinFocusNode,
                    decoration: InputDecoration(
                      labelText: 'GSTIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.receipt_long, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _panFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _panController,
                    focusNode: _panFocusNode,
                    decoration: InputDecoration(
                      labelText: 'PAN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.credit_card, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _businessTypeFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessTypeController,
                    focusNode: _businessTypeFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Business Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.category, color: Colors.teal[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveBusiness(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveBusiness,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
