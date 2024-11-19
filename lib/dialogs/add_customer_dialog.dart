//add_customer_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart'; // Import BusinessProvider

void showAddCustomerDialog(BuildContext context) {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController gstinController = TextEditingController();

  // Access selectedBusinessId from BusinessProvider
  final String? selectedBusinessId =
      Provider.of<BusinessProvider>(context, listen: false).selectedBusinessId;

  // Ensure selectedBusinessId is not null or handle accordingly
  if (selectedBusinessId == null) {
    // Show an error or inform the user to select a business first
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Please select a business first.'),
          backgroundColor: Colors.red),
    );
    return; // Exit if no business is selected
  }

  void showSnackbar(String message, [Color bgColor = Colors.green]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor,
          duration: const Duration(seconds: 1)),
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: "Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(hintText: "Phone"),
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(hintText: "Address"),
                ),
                TextFormField(
                  controller: panController,
                  decoration: const InputDecoration(hintText: "PAN"),
                  onChanged: (value) {
                    panController.value = TextEditingValue(
                      text: value.toUpperCase(),
                      selection: panController.selection,
                    );
                  },
                ),
                TextFormField(
                    controller: gstinController,
                    decoration: const InputDecoration(hintText: "GSTIN"),
                    onChanged: (value) {
                      gstinController.value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: gstinController.selection,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.teal, // Text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ), // Adjust padding
            ),
            child: const Text('Add'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final Map<String, dynamic> customerData = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressController.text.trim(),
                  'pan': panController.text.trim(),
                  'gstin': gstinController.text.trim(),
                  'business_id': int.parse(
                      selectedBusinessId), // Use the selected business ID
                  'balance': 0.0,
                };
                // Use BusinessProvider to add a customer
                Provider.of<BusinessProvider>(context, listen: false)
                    .addCustomer(customerData)
                    .then((_) {
                  showSnackbar('Customer added successfully');
                  Navigator.of(context).pop();
                }).catchError((error) {
                  showSnackbar('Error adding customer: $error', Colors.red);
                });
              }
            },
          ),
        ],
      );
    },
  );
}
