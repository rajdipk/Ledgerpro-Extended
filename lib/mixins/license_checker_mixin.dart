// license_checker_mixin.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/license_provider.dart';

mixin LicenseCheckerMixin<T extends StatefulWidget> on State<T> {
  Future<bool> checkFeatureAvailability(
    BuildContext context,
    String featureName, {
    bool showError = true,
  }) async {
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
    final isAvailable = await licenseProvider.isFeatureAvailable(featureName);

    if (!isAvailable && showError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This feature is not available in your current license. Please upgrade to access this feature.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    return isAvailable;
  }

  Future<bool> checkWithinLimit(
    BuildContext context,
    String limitName,
    int currentCount, {
    bool showError = true,
  }) async {
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
    final isWithinLimit = await licenseProvider.isWithinLimit(limitName, currentCount);

    if (!isWithinLimit && showError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have reached the limit for this feature in your current license. Please upgrade to increase the limit.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    return isWithinLimit;
  }

  void showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'This feature requires a higher license tier. Would you like to upgrade now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to upgrade screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
