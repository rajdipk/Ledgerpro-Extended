// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/stock_movement_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/currency_provider.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  _StockMovementsScreenState createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedMovementType = 'All';
  final List<String> _movementTypes = ['All', 'IN', 'OUT'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double price, BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    return '${currencyProvider.currencySymbol} ${price.toStringAsFixed(2)}';
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.teal.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search movements...',
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedMovementType,
                items: _movementTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMovementType = value!;
                  });
                },
                style: const TextStyle(color: Colors.teal),
                underline: Container(
                  height: 2,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate == null
                      ? 'Start Date'
                      : DateFormat('MMM dd, yyyy').format(_startDate!)),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate == null
                      ? 'End Date'
                      : DateFormat('MMM dd, yyyy').format(_endDate!)),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement, InventoryProvider provider) {
    final item = provider.items.firstWhere((item) => item.id == movement.itemId);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: movement.movementType == 'IN'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movement.movementType,
                style: TextStyle(
                  color: movement.movementType == 'IN'
                      ? Colors.green[700]
                      : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity: ${movement.quantity} ${item.unit.split('(').last.split(')').first.trim()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: movement.movementType == 'IN' 
                      ? Colors.green[700]
                      : Colors.red[700],
                  ),
                ),
                Text(
                  'Unit Price: ${_formatPrice(movement.unitPrice, context)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reference: ${movement.referenceType}${movement.referenceId ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(movement.date)),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (movement.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${movement.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<StockMovement> _filterMovements(List<StockMovement> movements) {
    return movements.where((movement) {
      // Filter by search query
      final item = Provider.of<InventoryProvider>(context, listen: false)
          .items
          .firstWhere((item) => item.id == movement.itemId);
      
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(searchLower) &&
            !(movement.referenceType?.toLowerCase() ?? '').contains(searchLower) &&
            !(movement.notes?.toLowerCase() ?? '').contains(searchLower)) {
          return false;
        }
      }

      // Filter by movement type
      if (_selectedMovementType != 'All' &&
          movement.movementType != _selectedMovementType) {
        return false;
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        final movementDate = DateTime.parse(movement.date);
        if (_startDate != null && movementDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && movementDate.isAfter(_endDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final filteredMovements = _filterMovements(provider.movements);

        return Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: filteredMovements.isEmpty
                  ? Center(
                      child: Text(
                        'No stock movements found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMovements.length,
                      itemBuilder: (context, index) {
                        return _buildMovementCard(
                            filteredMovements[index], provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
