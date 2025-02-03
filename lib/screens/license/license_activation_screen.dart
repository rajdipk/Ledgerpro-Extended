// license_activation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../models/license_model.dart';
import '../../providers/license_provider.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _licenseKeyController = TextEditingController();
  final _emailController = TextEditingController();
  LicenseType _selectedType = LicenseType.demo;
  bool _isActivating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedLicenseKey();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  Future<void> _loadSavedLicenseKey() async {
    final savedEmail = await StorageService.instance.getValue('license_email');
    final savedKey = await StorageService.instance.getValue('license_key');
    if (savedEmail != null && savedKey != null) {
      setState(() {
        _emailController.text = savedEmail;
        _licenseKeyController.text = savedKey;
      });
    }
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _activateLicense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isActivating = true);

    try {
        final licenseKey = _licenseKeyController.text.trim();
        final email = _emailController.text.trim();

        debugPrint('Attempting to verify license: $licenseKey for email: $email');

        // First verify the license with backend
        final verifyResult = await ApiService.instance.apiCall(
            '/api/customers/verify-license',  // Changed from /api/admin/verify-license
            method: 'POST',
            body: {
                'licenseKey': licenseKey,
                'email': email,
            },
        );

        debugPrint('Verify result: $verifyResult');

        if (!verifyResult['success']) {
            throw Exception(verifyResult['error'] ?? 'Failed to verify license');
        }

        // Extract license data from response
        final licenseData = verifyResult['data']['license'];
        final licenseType = _getLicenseTypeFromString(licenseData['type']);

        // Activate license locally
        final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
        final success = await licenseProvider.activateLicense(
            licenseKey,
            email,
            licenseType,
            licenseData: licenseData, // Pass the full license data
        );

        if (!mounted) return;

        if (success) {
            // Save the verified credentials
            await StorageService.instance.saveValue('license_email', email);
            await StorageService.instance.saveValue('license_key', licenseKey);

            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('License activated successfully!'),
                    backgroundColor: Colors.green,
                ),
            );

            // Replace current screen with home screen
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) =>  HomeScreen())
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(licenseProvider.error ?? 'Failed to activate license'),
                    backgroundColor: Colors.red,
                ),
            );
        }
    } catch (e) {
        debugPrint('License activation error details: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error activating license: ${e.toString()}'),
                backgroundColor: Colors.red,
            ),
        );
    } finally {
        if (mounted) {
            setState(() => _isActivating = false);
        }
    }
  }

  LicenseType _getLicenseTypeFromString(String type) {
    switch (type.toLowerCase()) {
        case 'demo':
            return LicenseType.demo;
        case 'professional':
            return LicenseType.professional;
        case 'enterprise':
            return LicenseType.enterprise;
        default:
            throw Exception('Invalid license type: $type');
    }
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse('https://rajdipk.github.io/Ledgerpro-Extended/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                        Colors.blue.shade900,
                        Colors.teal.shade700,
                    ],
                ),
            ),
            child: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    children: [
                        _buildAnimatedHeader(),
                        const SizedBox(height: 40),
                        _buildPlanSelector(),
                        const SizedBox(height: 40),
                        _buildLicenseForm(),
                        const SizedBox(height: 30),
                        _buildActivationControls(),
                    ],
                ),
            ),
        ),
    );

  Widget _buildAnimatedHeader() {
    return Center(
      child: AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            'Choose Your Plan',
            textStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            speed: const Duration(milliseconds: 100),
          ),
        ],
        totalRepeatCount: 1,
      ),
    );
  }

  Widget _buildPlanSelector() {
    return SizedBox(
      height: 400,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),  
              _buildPlanCard(
                LicenseType.demo,
                'Demo',
                'Try it out',
                Colors.teal[800]!,
                const [
                  PlanFeature(Icons.people_outline, '10 Customers'),
                  PlanFeature(Icons.inventory_2_outlined, '50 Items'),
                  PlanFeature(Icons.receipt_long_outlined, '20 Invoices'),
                  PlanFeature(Icons.timer_outlined, '30 Days'),
                  PlanFeature(Icons.block_outlined, 'No Export'),
                ],
              ),
              const SizedBox(width: 20),
              _buildPlanCard(
                LicenseType.professional,
                'Professional',
                'Most Popular',
                Colors.teal[900]!,
                const [
                  PlanFeature(Icons.people, '1,000 Customers'),
                  PlanFeature(Icons.inventory_2, '5,000 Items'),
                  PlanFeature(Icons.receipt_long, '1,000 Invoices'),
                  PlanFeature(Icons.picture_as_pdf, 'PDF Export'),
                  PlanFeature(Icons.qr_code_scanner, 'Barcode Scanner'),
                ],
              ),
              const SizedBox(width: 20),
              _buildPlanCard(
                LicenseType.enterprise,
                'Enterprise',
                'Full Power',
                Colors.teal[700]!,
                const [
                  PlanFeature(Icons.all_inclusive, 'Unlimited Everything'),
                  PlanFeature(Icons.api, 'API Access'),
                  PlanFeature(Icons.business, 'Multi-Business'),
                  PlanFeature(Icons.analytics, 'Advanced Analytics'),
                  PlanFeature(Icons.support_agent, 'Priority Support'),
                ],
              ),
              const SizedBox(width: 20),  
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    LicenseType type,
    String title,
    String subtitle,
    Color color,
    List<PlanFeature> features,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: features.map((feature) {
                    return Row(
                      children: [
                        Icon(
                          feature.icon,
                          color: isSelected ? Colors.white : color,
                          size: 28,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            feature.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'License Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.teal[900],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseKeyController,
              onChanged: (value) {
                // Auto-select the plan based on key prefix
                if (value.startsWith('DEMO-')) {
                  setState(() => _selectedType = LicenseType.demo);
                } else if (value.startsWith('PRO-')) {
                  setState(() => _selectedType = LicenseType.professional);
                } else if (value.startsWith('ENT-')) {
                  setState(() => _selectedType = LicenseType.enterprise);
                }
              },
              decoration: InputDecoration(
                labelText: 'License Key',
                hintText: 'Example: PRO-1234-5678-9012',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                LicenseKeyFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your license key';
                }
                
                // Check if key prefix matches selected type
                final prefix = value.split('-').first;
                final expectedPrefix = switch (_selectedType) {
                  LicenseType.demo => 'DEMO',
                  LicenseType.professional => 'PRO',
                  LicenseType.enterprise => 'ENT',
                };
                
                if (prefix != expectedPrefix) {
                  return 'Key must start with $expectedPrefix for ${_selectedType.toString().split('.').last} license';
                }

                // Validate full format
                final validKeyFormat = RegExp(r'^(DEMO|PRO|ENT)-[0-9]{4}-[0-9]{4}-[0-9]{4}$');
                if (!validKeyFormat.hasMatch(value)) {
                  return 'Invalid license key format';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationControls() {
    return ElevatedButton(
      onPressed: _isActivating ? null : _activateLicense,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal[900],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      child: _isActivating
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(),
            )
          : const Text(
              'Activate License',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class PlanFeature {
  final IconData icon;
  final String text;

  const PlanFeature(this.icon, this.text);
}

class LicenseKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert to uppercase
    var text = newValue.text.toUpperCase();
    
    // Remove any extra hyphens
    text = text.replaceAll('-', '');
    
    // Limit to 16 characters (TYPE + 12 numbers)
    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    // Format with hyphens
    final buffer = StringBuffer();
    
    // Handle the license type prefix (DEMO, PRO, ENT)
    if (text.length <= 4) {
      buffer.write(text);
    } else {
      // Add the type prefix
      buffer.write(text.substring(0, 3));
      buffer.write('-');
      
      // Add the remaining numbers in groups of 4
      var remainingDigits = text.substring(3);
      for (var i = 0; i < remainingDigits.length; i++) {
        if (i > 0 && i % 4 == 0 && i <= 12) {
          buffer.write('-');
        }
        buffer.write(remainingDigits[i]);
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
