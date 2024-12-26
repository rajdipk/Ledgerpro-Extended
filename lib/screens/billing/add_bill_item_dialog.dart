import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/barcode_scanner_dialog.dart';

class AddBillItemDialog extends StatefulWidget {
  const AddBillItemDialog({super.key});

  @override
  State<AddBillItemDialog> createState() => _AddBillItemDialogState();
}

class _AddBillItemDialogState extends State<AddBillItemDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  InventoryItem? _selectedItem;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    );

    if (barcode != null) {
      final items = await Provider.of<InventoryProvider>(context, listen: false)
          .searchItems(barcode);
      if (items.isNotEmpty) {
        setState(() {
          _selectedItem = items.first;
          _searchController.text = items.first.name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Add Item to Bill',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Items',
                        hintText: 'Enter item name, SKU, or barcode',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild to filter items
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scan Barcode',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    final query = _searchController.text.toLowerCase();
                    final items = provider.items
                        .where((item) =>
                            item.name.toLowerCase().contains(query) ||
                            item.sku!.toLowerCase().contains(query) ||
                            (item.barcode?.toLowerCase().contains(query) ??
                                false))
                        .toList();

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              query.isEmpty
                                  ? 'No items in inventory'
                                  : 'No items match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedItem?.id == item.id;

                        return Card(
                          elevation: isSelected ? 2 : 0,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                  fontWeight:
                                      isSelected ? FontWeight.bold : null,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              'SKU: ${item.sku} • Stock: ${item.currentStock}',
                              style: TextStyle(
                                color: item.currentStock > 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            trailing: Text(
                              '₹${item.sellingPrice}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight:
                                        isSelected ? FontWeight.bold : null,
                                  ),
                            ),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedItem = item;
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selectedItem != null) ...[
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Stock',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          _selectedItem!.currentStock.toString(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: _selectedItem!.currentStock > 0
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedItem == null
                        ? null
                        : () {
                            final quantity =
                                int.tryParse(_quantityController.text) ?? 0;
                            if (quantity <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please enter a valid quantity'),
                                ),
                              );
                              return;
                            }
                            if (quantity > _selectedItem!.currentStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Insufficient stock. Available: ${_selectedItem!.currentStock}',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop({
                              'item': _selectedItem,
                              'quantity': quantity,
                              'price': _selectedItem!.sellingPrice,
                              'gstRate': _selectedItem!.gstRate,
                            });
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Bill'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
