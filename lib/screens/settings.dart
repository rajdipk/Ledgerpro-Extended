// settings.dart

// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/business_model.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:math' as math;
import '../mannuals/user_manual_screen.dart';
import '../providers/business_provider.dart';

class SignaturePainter extends CustomPainter {
  final Color color;
  final int seed;
  
  SignaturePainter(this.color) : seed = math.Random().nextInt(4);

  void drawPolygon(Canvas canvas, Size size, int sides, double radius, Paint paint, {double rotation = 0}) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) + rotation;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void drawStarPattern(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;
    
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x1 = centerX + radius * math.cos(angle);
      final y1 = centerY + radius * math.sin(angle);
      final x2 = centerX + radius * 0.3 * math.cos(angle + math.pi / 4);
      final y2 = centerY + radius * 0.3 * math.sin(angle + math.pi / 4);
      
      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2);
      canvas.drawPath(path, paint);
    }
  }

  void drawSpiral(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width * 0.4;
    
    var radius = maxRadius;
    var angle = 0.0;
    path.moveTo(centerX + radius, centerY);
    
    while (radius > maxRadius * 0.1) {
      angle += 0.2;
      radius *= 0.95;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void drawFlower(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.3;
    const petalCount = 6;
    
    for (var i = 0; i < petalCount; i++) {
      final angle = i * 2 * math.pi / petalCount;
      final path = Path();
      
      path.moveTo(centerX, centerY);
      path.quadraticBezierTo(
        centerX + radius * math.cos(angle + math.pi / petalCount),
        centerY + radius * math.sin(angle + math.pi / petalCount),
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );
      path.quadraticBezierTo(
        centerX + radius * math.cos(angle - math.pi / petalCount),
        centerY + radius * math.sin(angle - math.pi / petalCount),
        centerX,
        centerY,
      );
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (seed) {
      case 0:
        // Concentric polygons with connecting lines
        drawPolygon(canvas, size, 6, size.width * 0.4, paint);
        drawPolygon(canvas, size, 3, size.width * 0.25, paint, rotation: math.pi / 6);
        drawStarPattern(canvas, size, paint);
        break;
      case 1:
        // Spiral pattern
        drawSpiral(canvas, size, paint);
        drawPolygon(canvas, size, 4, size.width * 0.2, paint, rotation: math.pi / 4);
        break;
      case 2:
        // Flower pattern
        drawFlower(canvas, size, paint);
        drawPolygon(canvas, size, 6, size.width * 0.2, paint);
        break;
      case 3:
        // Star burst pattern
        drawPolygon(canvas, size, 8, size.width * 0.4, paint);
        drawStarPattern(canvas, size, paint);
        drawPolygon(canvas, size, 4, size.width * 0.2, paint, rotation: math.pi / 4);
        break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Key _signatureKey = UniqueKey();
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void _regenerateSignature() {
    setState(() {
      _signatureKey = UniqueKey();
    });
  }

  void _showDeleteBusinessDialog(BuildContext context, List<Business> businesses) {
    final TextEditingController passwordController = TextEditingController();
    final FocusNode passwordFocusNode = FocusNode();
    String? selectedBusinessId;

    void cleanup() {
      passwordController.dispose();
      passwordFocusNode.dispose();
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Business'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Business',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    value: selectedBusinessId,
                    hint: const Text('Select business to delete'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBusinessId = newValue;
                      });
                    },
                    items: businesses.map((Business business) {
                      return DropdownMenuItem<String>(
                        value: business.id,
                        child: Text(business.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Warning: This action cannot be undone. All data associated with this business will be permanently deleted.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    passwordFocusNode.unfocus();
                    cleanup();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedBusinessId == null
                      ? null
                      : () async {
                          passwordFocusNode.unfocus();
                          cleanup();
                          Navigator.of(context).pop();
                          
                          final businessProvider = Provider.of<BusinessProvider>(
                              context,
                              listen: false);
                          
                          try {
                            await businessProvider.deleteBusiness(
                                selectedBusinessId!, passwordController.text);
                            
                            if (businessProvider.isPasswordValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Business deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // If there are remaining businesses, select the first one
                              if (businessProvider.businesses.isNotEmpty) {
                                businessProvider.setSelectedBusinessId(
                                  businessProvider.businesses.first.id
                                );
                              } else {
                                businessProvider.setSelectedBusinessId(null);
                              }

                              // Navigate to home screen
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (Route<dynamic> route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Incorrect password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting business: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Ensure cleanup happens if dialog is dismissed in any way
      cleanup();
    });
  }

  void _showEditBusinessDialog(
    BuildContext context,
    Business business,
    String field,
    String title,
  ) {
    final TextEditingController controller = TextEditingController(
      text: switch (field) {
        'name' => business.name,
        'address' => business.address,
        'phone' => business.phone,
        'gstin' => business.gstin,
        _ => '',
      },
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.substring(0, 1).toUpperCase() + field.substring(1),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: field == 'gstin' 
            ? TextCapitalization.characters 
            : TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Field cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedBusiness = switch (field) {
                'name' => business.copyWith(name: newValue),
                'address' => business.copyWith(address: newValue),
                'phone' => business.copyWith(phone: newValue),
                'gstin' => business.copyWith(gstin: newValue.toUpperCase()),
                _ => business,
              };

              await Provider.of<BusinessProvider>(context, listen: false)
                  .updateBusiness(updatedBusiness);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Business $field updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 600, // Only show back button on small screens
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // User Manual Card
            _buildSettingsCard(
              context,
              title: 'Help & Support',
              icon: Icons.menu_book_outlined,
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'User Manual',
                    subtitle: 'Learn how to use LedgerPro',
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManualScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme Settings Card
            _buildSettingsCard(
              context,
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'Dark Mode',
                    subtitle: 'Toggle dark theme',
                    trailing: Switch(
                      value: Provider.of<ThemeProvider>(context).isDarkMode,
                      onChanged: (value) =>
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Currency Settings Card
            _buildSettingsCard(
              context,
              title: 'Currency',
              icon: Icons.attach_money_outlined,
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'Currency Symbol',
                    subtitle: 'Change currency symbol',
                    trailing: DropdownButton<String>(
                      value: Provider.of<CurrencyProvider>(context).currencySymbol,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          Provider.of<CurrencyProvider>(context, listen: false)
                              .updateCurrencySymbol(newValue);
                        }
                      },
                      items: ['₹', '\$', '€', '£', '¥']
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Business Management Card
            _buildSettingsCard(
              context,
              title: 'Business Management',
              icon: Icons.business_outlined,
              child: Consumer<BusinessProvider>(
                builder: (context, businessProvider, child) {
                  final businesses = businessProvider.businesses;
                  final selectedBusiness = businesses.firstWhere(
                    (business) => business.id == businessProvider.selectedBusinessId,
                    orElse: () => Business(
                      name: 'No business selected',
                    ),
                  );

                  return Column(
                    children: [
                      // Business Details Section
                      if (selectedBusiness.id != null) ...[
                        _buildSettingsTile(
                          context,
                          title: 'Business Name',
                          subtitle: selectedBusiness.name,
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditBusinessDialog(
                              context,
                              selectedBusiness,
                              'name',
                              'Edit Business Name',
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          context,
                          title: 'Address',
                          subtitle: selectedBusiness.address ?? 'Not set',
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditBusinessDialog(
                              context,
                              selectedBusiness,
                              'address',
                              'Edit Business Address',
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          context,
                          title: 'Phone',
                          subtitle: selectedBusiness.phone ?? 'Not set',
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditBusinessDialog(
                              context,
                              selectedBusiness,
                              'phone',
                              'Edit Business Phone',
                            ),
                          ),
                        ),
                        _buildSettingsTile(
                          context,
                          title: 'GSTIN',
                          subtitle: selectedBusiness.gstin ?? 'Not set',
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditBusinessDialog(
                              context,
                              selectedBusiness,
                              'gstin',
                              'Edit Business GSTIN',
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                      _buildSettingsTile(
                        context,
                        title: 'Delete Business',
                        subtitle: 'Remove a business and all its data',
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            if (businesses.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No businesses to delete'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _showDeleteBusinessDialog(context, businesses);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // About Card
            _buildSettingsCard(
              context,
              title: 'About',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'Version',
                    subtitle: _packageInfo?.version ?? 'Loading...',
                  ),
                  _buildSettingsTile(
                    context,
                    title: 'Build Number',
                    subtitle: _packageInfo?.buildNumber ?? 'Loading...',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Signature
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _regenerateSignature,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CustomPaint(
                          key: _signatureKey,
                          painter: SignaturePainter(
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Crafted with passion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: trailing,
    );
  }
}
