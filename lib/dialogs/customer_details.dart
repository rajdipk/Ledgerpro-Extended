//customer_details.dart
// ignore_for_file: unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/business_provider.dart';

class CustomerDetailsDialog {
  static void show(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        
        return Consumer<BusinessProvider>(
          builder: (context, provider, _) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 40,
                vertical: isSmallScreen ? 24 : 40,
              ),
              child: Container(
                width: isSmallScreen ? screenSize.width : 600,
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.9,
                  maxWidth: 600,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Customer Details",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.teal,
                                ),
                              ),
                              IconButton(
                                icon: const Tooltip(
                                  message: 'Delete Customer',
                                  child: Icon(Icons.delete_outline_rounded),
                                ),
                                onPressed: () => _confirmDelete(context, customer),
                                color: Colors.red[400],
                              )
                            ],
                          ),
                          const Divider(thickness: 1, color: Colors.teal),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: LinearGradient(
                                      colors: [Colors.teal.shade50, Colors.white],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      if (isSmallScreen)
                                        // Stack items vertically on small screens
                                        Column(
                                          children: [
                                            Column(
                                              children: [
                                                _buildDetailItem("Name", customer.name, Icons.person_outline_rounded),
                                                _buildDetailItem("Phone", customer.phone, Icons.phone_outlined),
                                                _buildDetailItem("Address", customer.address, Icons.location_on_outlined),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Column(
                                              children: [
                                                _buildDetailItem("PAN", customer.pan, Icons.credit_card_outlined),
                                                _buildDetailItem("GSTIN", customer.gstin, Icons.numbers_outlined),
                                                const SizedBox(height: 8),
                                                _buildBalanceItem(provider.selectedCustomerBalance),
                                              ],
                                            ),
                                          ],
                                        )
                                      else
                                        // Use row layout for larger screens
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildDetailItem("Name", customer.name, Icons.person_outline_rounded),
                                                  _buildDetailItem("Phone", customer.phone, Icons.phone_outlined),
                                                  _buildDetailItem("Address", customer.address, Icons.location_on_outlined),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildDetailItem("PAN", customer.pan, Icons.credit_card_outlined),
                                                  _buildDetailItem("GSTIN", customer.gstin, Icons.numbers_outlined),
                                                  const SizedBox(height: 8),
                                                  _buildBalanceItem(provider.selectedCustomerBalance),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Close'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBalanceItem(double balance) {
    final isPositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isPositive ? Colors.green[700] : Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "₹${balance.abs().toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text.rich(
            TextSpan(
              text: "Are you sure you want to delete ",
              style: const TextStyle(
                fontSize: 16, // adjust font size as needed
              ),
              children: [
                TextSpan(
                  text: "${customer.name}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: " and its related transactions?",
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ), // Adjust padding
              ),
              onPressed: () {
                // Use the provider to access the selected business ID
                final provider =
                    Provider.of<BusinessProvider>(context, listen: false);
                final businessId =
                    int.tryParse(provider.selectedBusinessId ?? '');
                if (businessId != null) {
                  provider
                      .deleteCustomerAndTransactions(customer.id, businessId)
                      .then((_) {
                    // Check if the deleted customer was the selected customer
                    if (provider.selectedCustomer?.id == customer.id) {
                      provider.setSelectedCustomer(null);
                    }
                    // Navigate back to a previous screen, assuming a screen that does not require the deleted customer
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Customer deleted successfully"),
                      backgroundColor: Colors.green,
                    ));
                  }).catchError((error) {
                    // Handle any errors that might occur during the deletion
                    Navigator.of(context)
                        .pop(); // Close the confirmation dialog
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Failed to delete the customer: $error")));
                  });
                } else {
                  // Handle the case where business ID is not available
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Error: Business ID is not set.")));
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
