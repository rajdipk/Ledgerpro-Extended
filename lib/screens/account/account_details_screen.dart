import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/license_provider.dart';
import '../../models/license_model.dart';
import '../../services/storage_service.dart';
import '../license/license_activation_screen.dart';
import '../../database/database_helper.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  Map<String, int> _usageStats = {};

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    try {
      final db = DatabaseHelper.instance;
      final stats = await Future.wait([
        db.getCustomerCount(),
        db.getInventoryCount(),
        db.getMonthlyTransactionCount(),
      ]);

      if (mounted) {
        setState(() {
          _usageStats = {
            'customers': stats[0],
            'inventory': stats[1],
            'transactions': stats[2],
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading usage stats: $e');
      if (mounted) {
        setState(() {
          _usageStats = {
            'customers': 0,
            'inventory': 0,
            'transactions': 0,
          };
        });
      }
    }
  }

  Future<void> _handleActivateLicense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LicenseActivationScreen()),
    );

    if (result == true) {
      // License was activated successfully
      setState(() {
        _loadUsageStats();
      });
    }
  }

  Future<void> _handleDeactivateLicense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate License?'),
        content: const Text('This will remove your current license. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
      await licenseProvider.deactivateLicense();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('License deactivated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LicenseProvider>(
      builder: (context, licenseProvider, child) {
        final license = licenseProvider.currentLicense;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account Details'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              if (license != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleDeactivateLicense,
                  tooltip: 'Deactivate License',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadUsageStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (license == null)
                    _buildActivationCard()
                  else
                    _buildLicenseCard(license),
                  const SizedBox(height: 24),
                  if (license != null) ...[
                    _buildUsageSection(license),
                    const SizedBox(height: 24),
                    _buildFeaturesList(license),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'No Active License',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Activate a license to unlock premium features and increase usage limits.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleActivateLicense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Activate License'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(License? license) {
    if (license == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No active license'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'License Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Type', license.licenseType.toString().split('.').last.toUpperCase()),
            _buildInfoRow('Key', license.licenseKey),
            _buildInfoRow('Email', license.customerEmail ?? 'N/A'),
            _buildInfoRow(
              'Expiry Date', 
              license.expiryDate?.toString().split(' ')[0] ?? 'Never'
            ),
            _buildInfoRow(
              'Status', 
              license.isExpired() ? 'Expired' : 'Active',
              valueColor: license.isExpired() ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(License license) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildUsageBar(
              'Customers', 
              license.getFeatureLimit('customer_limit') ?? 0,
              _usageStats['customers'] ?? 0,
            ),
            const SizedBox(height: 16),
            _buildUsageBar(
              'Inventory Items',
              license.getFeatureLimit('inventory_limit') ?? 0,
              _usageStats['inventory'] ?? 0,
            ),
            const SizedBox(height: 16),
            _buildUsageBar(
              'Monthly Transactions',
              license.getFeatureLimit('monthly_transaction_limit') ?? 0,
              _usageStats['transactions'] ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(License? license) {
    if (license == null) return const SizedBox();

    final features = license.features.entries
        .where((e) => e.value is bool)
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...features.map((feature) => _buildFeatureRow(
              feature.key.split('_').map((word) => 
                word[0].toUpperCase() + word.substring(1)
              ).join(' '),
              feature.value as bool,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(String label, int limit, int current) {
    final percentage = limit <= 0 ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isUnlimited = limit < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(isUnlimited 
              ? '$current / Unlimited' 
              : '$current / $limit'
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isUnlimited) LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 0.9 ? Colors.red : Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String feature, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}
