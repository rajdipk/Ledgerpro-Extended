import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import 'package:provider/provider.dart';

class AddBillItemDialog extends StatefulWidget {
  final InventoryItem? preSelectedItem;

  const AddBillItemDialog({
    Key? key,
    this.preSelectedItem,
  }) : super(key: key);

  @override
  State<AddBillItemDialog> createState() => _AddBillItemDialogState();
}

class _AddBillItemDialogState extends State<AddBillItemDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  String _searchQuery = '';
  InventoryItem? _selectedItem;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedItem != null) {
      _selectedItem = widget.preSelectedItem;
      _searchController.text = widget.preSelectedItem!.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Item to Bill',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedItem == null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    final items = provider.items
                        .where((item) =>
                            item.name.toLowerCase().contains(_searchQuery) ||
                            (item.barcode?.contains(_searchQuery) ?? false))
                        .toList();

                    return items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No items found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Text('Stock: ${item.currentStock}'),
                                trailing: Text(
                                  '₹${item.sellingPrice.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedItem = item;
                                    _searchController.text = item.name;
                                  });
                                },
                              );
                            },
                          );
                  },
                ),
              ),
            ] else ...[
              Card(
                child: ListTile(
                  title: Text(_selectedItem!.name),
                  subtitle: Text('Stock: ${_selectedItem!.currentStock}'),
                  trailing: Text(
                    '₹${_selectedItem!.sellingPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        setState(() {
                          _quantity = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _quantity++;
                            _quantityController.text = _quantity.toString();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                  _quantityController.text = _quantity.toString();
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedItem = null;
                        _searchController.clear();
                        _quantity = 1;
                        _quantityController.text = '1';
                      });
                    },
                    child: const Text('Change Item'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _quantity > 0 &&
                            _quantity <= _selectedItem!.currentStock
                        ? () {
                            Navigator.pop(
                              context,
                              {
                                'item': _selectedItem,
                                'quantity': _quantity,
                              },
                            );
                          }
                        : null,
                    child: const Text('Add to Bill'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
