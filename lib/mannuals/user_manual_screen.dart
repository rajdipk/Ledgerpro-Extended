// user_manual_screen.dart
import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Welcome Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.waving_hand, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Welcome to LedgerPro!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s help you get started with managing your business better.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Quick Start Guide
          _buildSection(
            context,
            title: 'Quick Start Guide',
            icon: Icons.rocket_launch,
            items: [
              const _GuideItem(
                title: 'Set Up Your Account',
                description: '1. Create a secure password\n2. Enable biometric login (optional)\n3. Accept terms & conditions',
                icon: Icons.person_add,
                color: Colors.blue,
              ),
              const _GuideItem(
                title: 'Add Your Business',
                description: '1. Tap "+" to add business\n2. Enter business name\n3. Choose currency\n4. Start managing!',
                icon: Icons.business,
                color: Colors.green,
              ),
            ],
          ),

          // Daily Operations
          _buildSection(
            context,
            title: 'Daily Operations',
            icon: Icons.calendar_today,
            items: [
              const _GuideItem(
                title: 'Customer Management',
                description: '• Add new customers\n• Record transactions\n• View customer history\n• Generate statements',
                icon: Icons.people,
                color: Colors.orange,
              ),
              const _GuideItem(
                title: 'Supplier Management',
                description: '• Add suppliers\n• Track purchases\n• Manage payments\n• View balances',
                icon: Icons.inventory,
                color: Colors.purple,
              ),
              const _GuideItem(
                title: 'Transaction Recording',
                description: '• Choose customer/supplier\n• Enter amount\n• Add description\n• Save transaction',
                icon: Icons.receipt_long,
                color: Colors.red,
              ),
            ],
          ),

          // Reports & Analysis
          _buildSection(
            context,
            title: 'Reports & Analysis',
            icon: Icons.insights,
            items: [
              const _GuideItem(
                title: 'Dashboard Overview',
                description: '• View total balances\n• Check daily transactions\n• Monitor business growth\n• Track customer stats',
                icon: Icons.dashboard,
                color: Colors.indigo,
              ),
              const _GuideItem(
                title: 'Generate Reports',
                description: '• Select date range\n• Choose report type\n• Export as PDF\n• Share reports',
                icon: Icons.summarize,
                color: Colors.teal,
              ),
            ],
          ),

          // Tips & Tricks
          _buildSection(
            context,
            title: 'Tips & Tricks',
            icon: Icons.lightbulb_outline,
            items: [
              const _GuideItem(
                title: 'Keyboard Shortcuts',
                description: '• Ctrl+N: New entry\n• Ctrl+S: Save\n• Ctrl+P: Print\n• Esc: Close popup',
                icon: Icons.keyboard,
                color: Colors.amber,
              ),
              const _GuideItem(
                title: 'Data Backup',
                description: '• Regular auto-backup\n• Export data manually\n• Secure cloud storage\n• Quick restore',
                icon: Icons.backup,
                color: Colors.cyan,
              ),
            ],
          ),

          // Bottom Padding
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_GuideItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal[700], size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildGuideItemCard(context, item)),
      ],
    );
  }

  Widget _buildGuideItemCard(BuildContext context, _GuideItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: item.color.withOpacity(0.1),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(
            item.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _GuideItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
