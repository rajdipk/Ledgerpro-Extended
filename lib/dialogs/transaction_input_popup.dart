//transaction_input_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionInputPopup extends StatefulWidget {
  final Function(double, DateTime) onConfirm;
  final bool isReceived;

  const TransactionInputPopup({
    super.key,
    required this.onConfirm,
    required this.isReceived,
  });

  @override
  State<TransactionInputPopup> createState() => _TransactionInputPopupState();
}

class _TransactionInputPopupState extends State<TransactionInputPopup> {
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isTransactionAdded = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitData() {
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      return; // Basic validation
    }
    widget.onConfirm(enteredAmount, _selectedDate);
    _showSuccessAnimation();
  }

  Widget _buildSuccessWidget() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 48),
        SizedBox(height: 10),
        Text(
          'Transaction Added',
          style: TextStyle(color: Colors.green, fontSize: 16),
        ),
      ],
    );
  }

  void _showSuccessAnimation() {
    setState(() {
      _isTransactionAdded = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child:
            _isTransactionAdded ? _buildSuccessWidget() : _buildInputWidget(),
      ),
      actions: _isTransactionAdded ? null : _buildActions(),
    );
  }

  Widget _buildInputWidget() {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Amount'),
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
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: const Text('Choose Date'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      ),
      TextButton(
        onPressed: _submitData,
        child: const Text('Confirm'),
      ),
    ];
  }
}
