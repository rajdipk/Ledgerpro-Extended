// navigation_panel.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../dialogs/add_business_dialog.dart';
import 'package:intl/intl.dart';
import '../providers/business_provider.dart';
import 'inventory_coming_soon_screen.dart';

class NavigationPanel extends StatefulWidget {
  final Function onSettings;
  final Function onCustomers;
  final Function onLogout;
  final Function onSuppliers;

  const NavigationPanel({
    super.key,
    required this.onCustomers,
    required this.onSuppliers,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  late Timer _timer;
  late String _formattedDate;
  late String _formattedTime;
  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    setState(() {
      _formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
      _formattedTime = DateFormat('h:mm:ss a').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);
    var selectedBusiness = businessProvider.selectedBusinessId;
    List<DropdownMenuItem<String>> dropdownItems = businessProvider.businesses
        .map((business) => DropdownMenuItem<String>(
              value: business.id,
              child: Text(business.name),
            ))
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 304, // Standard drawer width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.shade700,
                    Colors.teal.shade500,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/accounting.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'LedgerPro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formattedDate,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade300),
                    ),
                  ),
                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(),
                  isExpanded: true,
                  value: selectedBusiness,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                  elevation: 3,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300,
                  onChanged: (String? newValue) async {
                    if (newValue == 'Add Business') {
                      _showAddBusinessDialog(context);
                    } else {
                      setState(() {
                        _selectedItem = null;
                      });
                      businessProvider.setSelectedBusinessId(newValue);
                      await businessProvider.loadCustomerCount();
                    }
                  },
                  items: [
                    ...dropdownItems,
                    const DropdownMenuItem(
                      value: 'Add Business',
                      child: Row(
                        children: [
                          Icon(Icons.add_business, color: Colors.teal),
                          SizedBox(width: 12),
                          Text('Add New Business'),
                        ],
                      ),
                    ),
                  ],
                  hint: Row(
                    children: [
                      Icon(Icons.business_center,
                          color: Colors.teal.withOpacity(0.7)),
                      const SizedBox(width: 12),
                      const Text(
                        "Select Business",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (selectedBusiness != null)
                      ..._buildDrawerOptions(businessProvider),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _buildSettingsAndLogout(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBusinessDialog(BuildContext context) async {
    final newBusinessId = await showDialog<String>(
      context: context,
      builder: (context) => AddBusinessDialog(),
    );

    if (newBusinessId != null && newBusinessId.isNotEmpty) {
      // Use the returned ID to set the selected business
      final businessProvider =
          Provider.of<BusinessProvider>(context, listen: false);
      // Assuming _loadBusinesses() refreshes the list including the new addition
      await _loadBusinesses();
      businessProvider.setSelectedBusinessId(newBusinessId);
      // This forces a rebuild to reflect the new selection, in case it's needed
      await businessProvider
          .loadCustomerCount(); // Load customer count for the new business

      setState(() {});
    }
  }

  Future<void> _loadBusinesses() async {
    // Access the BusinessProvider from the context within the method
    final businessProvider =
        Provider.of<BusinessProvider>(context, listen: false);
    await businessProvider.loadBusinessesFromDb();
  }

  List<Widget> _buildDrawerOptions(BusinessProvider businessProvider) {
    return [
      _buildDrawerItem(
        icon: Icons.dashboard_rounded,
        text: 'Home',
        onTap: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
      _buildDrawerItem(
        icon: Icons.people_alt_rounded,
        text: 'Customers',
        trailing: businessProvider.customerCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${businessProvider.customerCount}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          widget.onCustomers();
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
        },
      ),
      _buildDrawerItem(
        icon: Icons.local_shipping_outlined,
        text: 'Suppliers',
        trailing: businessProvider.supplierCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${businessProvider.supplierCount}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          widget.onSuppliers();
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
        },
      ),
      _buildDrawerItem(
        icon: Icons.inventory_2_rounded,
        text: 'Inventory',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InventoryComingSoonScreen(),
            ),
          );
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
        },
      ),
    ];
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isSelected = _selectedItem == text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            icon,
            color: isSelected ? Colors.teal : Colors.grey.shade700,
            size: 24,
          ),
          title: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 16,
              color: isSelected ? Colors.teal : Colors.grey.shade900,
            ),
          ),
          trailing: trailing,
          selected: isSelected,
          selectedTileColor: Colors.teal.withOpacity(0.1),
          onTap: () {
            setState(() {
              _selectedItem = text;
            });
            if (onTap != null) {
              onTap();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSettingsAndLogout() {
    return Column(
      children: [
        _buildDrawerItem(
          icon: Icons.settings_rounded,
          text: 'Settings',
          onTap: () => widget.onSettings(),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onLogout(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
