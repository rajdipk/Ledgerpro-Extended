import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/license_provider.dart';
import '../../models/license_model.dart';
import '../../services/payment_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final PaymentService _paymentService = PaymentService();
  LicenseType _selectedType = LicenseType.professional;
  bool _isProcessing = false;

  final Map<LicenseType, Map<String, dynamic>> _licenseDetails = {
    LicenseType.demo: {
      'name': 'Demo',
      'price': 'Free',
      'features': [
        {'name': 'Basic inventory management', 'included': true},
        {'name': 'Up to 10 customers', 'included': true},
        {'name': 'Basic reporting', 'included': true},
        {'name': 'PDF export', 'included': false},
        {'name': 'Advanced analytics', 'included': false},
        {'name': 'Multi-business support', 'included': false},
      ],
    },
    LicenseType.professional: {
      'name': 'Professional',
      'price': '\$9.99/month',
      'features': [
        {'name': 'Advanced inventory management', 'included': true},
        {'name': 'Up to 1000 customers', 'included': true},
        {'name': 'Advanced reporting', 'included': true},
        {'name': 'PDF export', 'included': true},
        {'name': 'Basic analytics', 'included': true},
        {'name': 'Multi-business support', 'included': false},
      ],
    },
    LicenseType.enterprise: {
      'name': 'Enterprise',
      'price': '\$99.99/month',
      'features': [
        {'name': 'Unlimited inventory management', 'included': true},
        {'name': 'Unlimited customers', 'included': true},
        {'name': 'Custom reporting', 'included': true},
        {'name': 'Advanced PDF customization', 'included': true},
        {'name': 'Advanced analytics', 'included': true},
        {'name': 'Multi-business support', 'included': true},
      ],
    },
  };

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _upgradeLicense() async {
    setState(() => _isProcessing = true);

    try {
      final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
      
      await _paymentService.startPayment(
        _selectedType,
        licenseProvider.customerId!,
        (String licenseKey) async {
          // Payment successful, activate the license
          await licenseProvider.activateLicense(
            licenseKey,
            licenseProvider.customerEmail!,
            _selectedType,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('License upgraded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        (String error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error upgrading license: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upgrading license: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade License'),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final type in LicenseType.values)
              if (type != LicenseType.demo) // Don't show demo in upgrade screen
                _buildLicenseCard(type),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _upgradeLicense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(LicenseType type) {
    final details = _licenseDetails[type]!;
    final isSelected = _selectedType == type;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.teal[700]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<LicenseType>(
                    value: type,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                    activeColor: Colors.teal[700],
                  ),
                  Text(
                    details['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    details['price'],
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              ...details['features'].map<Widget>((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        feature['included']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: feature['included']
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(feature['name']),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
