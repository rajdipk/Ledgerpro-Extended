//supplier_transaction_edit_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupplierTransactionEditPopup extends StatefulWidget {
  final double initialAmount;
  final DateTime initialDate;
  final Function(double, DateTime) onConfirm;
  final VoidCallback? onDelete;

  const SupplierTransactionEditPopup({
    super.key,
    required this.initialAmount,
    required this.initialDate,
    required this.onConfirm,
    this.onDelete,
  });

  @override
  State<SupplierTransactionEditPopup> createState() => _SupplierTransactionEditPopupState();
}

class _SupplierTransactionEditPopupState extends State<SupplierTransactionEditPopup> {
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount.abs().toStringAsFixed(2),
    );
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitData() {
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Preserve the sign of the original amount (payment or receipt)
    final finalAmount = widget.initialAmount < 0 ? -enteredAmount : enteredAmount;
    
    setState(() => _isUpdating = true);
    widget.onConfirm(finalAmount, _selectedDate);
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPayment = widget.initialAmount < 0;
    
    return AlertDialog(
      title: Text(isPayment ? 'Edit Payment' : 'Edit Receipt'),
      content: _isUpdating
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating transaction...'),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    hintText: isPayment ? 'Payment amount' : 'Receipt amount',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _submitData(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              _selectedDate.hour,
                              _selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: const Text('Choose Date'),
                    ),
                  ],
                ),
              ],
            ),
      actions: _isUpdating
          ? null
          : [
              if (widget.onDelete != null)
                TextButton(
                  onPressed: _confirmDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPayment ? Colors.red : Colors.green,
                ),
                child: const Text('Update'),
              ),
            ],
    );
  }
}
