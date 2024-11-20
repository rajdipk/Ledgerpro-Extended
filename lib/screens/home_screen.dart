// home_screen.dart
// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../providers/business_provider.dart';
import 'home_screen_design.dart';
import 'navigation_panel.dart';
import 'settings.dart';
import 'customer_operations_screen.dart';
import 'supplier_operations_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Widget _currentContent = const HomeScreenDesign(); // Use HomeScreenDesign here

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/auth');
    if (Platform.isWindows) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  void _switchContent(Widget newContent) {
    setState(() {
      _currentContent = newContent;
    });
    // Any additional logic to handle business selection can go here
  }

  @override
  Widget build(BuildContext context) {
    // Access the BusinessProvider instance using Provider.of
    final businessProvider = Provider.of<BusinessProvider>(context);
    // Retrieve the selected business ID from the provider
    // ignore: unused_local_variable
    String? selectedBusinessId = businessProvider.selectedBusinessId;
    
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LedgerPro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade700,
                      Colors.teal.shade500,
                    ],
                  ),
                ),
              ),
              leading: Builder(
                builder: (context) => Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
            )
          : null,
      drawer: isSmallScreen
          ? Drawer(
              child: NavigationPanel(
                onLogout: () => _handleLogout(context),
                onSettings: () => _switchContent(const SettingsScreen()),
                onCustomers: () => _switchContent(const CustomerOperationsScreen()),
                onSuppliers: () => _switchContent(const SupplierOperationsScreen()),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            SizedBox(
              width: 300,
              child: NavigationPanel(
                onLogout: () => _handleLogout(context),
                onSettings: () => _switchContent(const SettingsScreen()),
                onCustomers: () => _switchContent(const CustomerOperationsScreen()),
                onSuppliers: () =>_switchContent(const SupplierOperationsScreen()),
              ),
            ),
          Expanded(
            child: _currentContent,
          ),
        ],
      ),
    );
  }
}
