import 'package:flutter/material.dart';
import '../../mixins/license_checker_mixin.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with LicenseCheckerMixin {
  Future<void> _generateReport(String reportType) async {
    if (!await checkFeatureAvailability(context, '${reportType}_reports')) {
      return;
    }

    // Generate report based on type...
  }

  Future<void> _exportReport(String reportType) async {
    if (!await checkFeatureAvailability(context, 'report_export')) {
      return;
    }

    // Export report...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.teal[700],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildReportCard(
            'Sales Reports',
            Icons.point_of_sale,
            () => _generateReport('sales'),
          ),
          _buildReportCard(
            'Inventory Reports',
            Icons.inventory,
            () => _generateReport('inventory'),
          ),
          _buildReportCard(
            'Customer Reports',
            Icons.people,
            () => _generateReport('customer'),
          ),
          _buildReportCard(
            'Financial Reports',
            Icons.attach_money,
            () => _generateReport('financial'),
          ),
          _buildReportCard(
            'Tax Reports',
            Icons.receipt_long,
            () => _generateReport('tax'),
          ),
          _buildReportCard(
            'Analytics',
            Icons.analytics,
            () => _generateReport('analytics'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.teal[700]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
