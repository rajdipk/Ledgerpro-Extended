// ignore_for_file: use_super_parameters, library_private_types_in_public_api
//transaction_edit_popup.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';

class TransactionEditPopup extends StatefulWidget {
  final double initialAmount;
  final DateTime initialDate;
  final Function(double, DateTime) onConfirm;
  final int? transactionId;
  final int customerId;

  const TransactionEditPopup({
    Key? key,
    required this.initialAmount,
    required this.initialDate,
    required this.onConfirm,
    this.transactionId,
    required this.customerId,
  }) : super(key: key);

  @override
  _TransactionEditPopupState createState() => _TransactionEditPopupState();
}

class _TransactionEditPopupState extends State<TransactionEditPopup> {
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late bool _isReceived;
  bool _isTransactionUpdated = false;
  bool _isTransactionDeleted = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.initialAmount.abs().toStringAsFixed(2));
    _selectedDate = widget.initialDate;
    _isReceived = widget.initialAmount >= 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (!_isTransactionUpdated && !_isTransactionDeleted)
                    const Text('Edit Transaction'),
                  if (!_isTransactionUpdated && !_isTransactionDeleted)
                    IconButton(
                      icon: const Tooltip(
                        message: 'Delete Transaction',
                        child: Icon(Icons.delete),
                      ),
                      onPressed: () => _deleteTransaction(),
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isTransactionUpdated || _isTransactionDeleted)
                _buildSuccessWidget()
              else
                _buildEditWidget(),
              const SizedBox(height: 20),
              if (!_isTransactionUpdated && !_isTransactionDeleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActions(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: _updateTransaction,
        child: const Text('Update'),
      ),
    ];
  }

  Widget _buildEditWidget() {
    return Column(
      children: <Widget>[
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        ListTile(
          title: const Text('Transaction Type'),
          trailing: Switch(
            value: _isReceived,
            onChanged: (bool value) {
              setState(() {
                _isReceived = value;
              });
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.withOpacity(0.5),
          ),
          subtitle: Text(
            _isReceived ? "Received" : "Given",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: _isReceived
                  ? Colors.green
                  : Colors.red, // Change color based on switch
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => _pickDate(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 10),
              Text(
                  'Date: ${DateFormat('EEE, MMM d, ' 'yy').format(_selectedDate)}'), // Adjusted format
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessWidget() {
    return Column(
      children: <Widget>[
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 10),
        Text(
          _isTransactionDeleted ? 'Transaction Deleted' : 'Transaction Updated' ,
          style: const TextStyle(color: Colors.green),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateTransaction() {
    double? amount = double.tryParse(_amountController.text);
    if (amount != null) {
      double updatedAmount = _isReceived ? amount : -amount;
      widget.onConfirm(updatedAmount, _selectedDate);
      _showSuccessAnimation();
    }
  }

  void _deleteTransaction() {
    if (widget.transactionId != null) {
      Provider.of<BusinessProvider>(context, listen: false)
          .deleteTransaction(widget.transactionId!, widget.customerId);
      setState(() {
        _isTransactionDeleted = true;
      });
      _showSuccessAnimation();
    }
  }

  void _showSuccessAnimation() {
    setState(() {
      _isTransactionUpdated = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTransactionUpdated = false;
          _isTransactionDeleted = false;
        });
        Navigator.of(context).pop();
      }
    });
  }

}
