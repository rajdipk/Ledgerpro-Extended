// add_business_dialog.dart
// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddBusinessDialog extends StatelessWidget {
  final TextEditingController businessNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Business'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: businessNameController,
            decoration: InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
                borderSide: const BorderSide(color: Colors.grey), // Grey border
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0), // Adjust padding
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700], // Darker text color
          ), // Close dialog
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String businessName = businessNameController.text.trim();
            if (businessName.isNotEmpty) {
              // Save the business name to the database
              int newBusinessId = await DatabaseHelper.instance.addBusiness(businessName);

              // Return the new business ID when popping the dialog
              Navigator.pop(context, newBusinessId.toString()); // Close dialog after saving

              // Delay showing the SnackBar until after the UI has updated
              Future.delayed(Duration.zero, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Business $businessName added successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.teal[700], shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ), // White text on button
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0), // Adjust padding
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
