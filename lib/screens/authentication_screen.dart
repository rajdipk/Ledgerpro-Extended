// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../database/database_helper.dart';
import '../mannuals/eula_screen.dart';
import '../mannuals/terms_and_conditions_screen.dart';
import '../screens/license/license_activation_screen.dart';
import '../providers/license_provider.dart';
import 'home_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _acceptedTerms = true;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.black),
                  onPressed: () {
                    Navigator.pushNamed(context, '/user-manual');
                  },
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/images/accounting.png',
                                height: 100,
                                width: 100,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(delay: 200.ms)
                                .shimmer(duration: 1000.ms),
                            const SizedBox(height: 20),
                            _buildTitle()
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slide(begin: const Offset(0, 0.2)),
                            const SizedBox(height: 10),
                            _buildSubtitle()
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slide(begin: const Offset(0, 0.2)),
                            const SizedBox(height: 35),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 350),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: FutureBuilder<bool>(
                                future: DatabaseHelper.instance.isPasswordSet(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return _buildShimmerLoading();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return snapshot.data ?? false
                                        ? _buildLoginForm()
                                        : _buildSetPasswordForm();
                                  }
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slide(begin: const Offset(0, 0.2)),
                            if (_canCheckBiometrics) ...[
                              const SizedBox(height: 20),
                              _buildBiometricButton()
                                  .animate()
                                  .fadeIn(delay: 1000.ms)
                                  .scale(delay: 1200.ms),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
      child: AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            'LedgerPro',
            speed: const Duration(milliseconds: 80),
          ),
        ],
        isRepeatingAnimation: false,
      ),
    );
  }

  Widget _buildSubtitle() {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.black87,
      ),
      child: AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            'Ledger management redefined',
            speed: const Duration(milliseconds: 100),
          ),
        ],
        isRepeatingAnimation: false,
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            isConfirmField: false,
          ),
          const SizedBox(height: 10),
          _buildRememberMeRow(),
          const SizedBox(height: 10),
          _buildTermsAndConditionsRow(),
          const SizedBox(height: 20),
          _buildAuthButton(),
        ],
      ),
    );
  }

  Widget _buildSetPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Set Password',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Enter Password',
            isConfirmField: false,
          ),
          const SizedBox(height: 10),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            isConfirmField: true,
          ),
          const SizedBox(height: 10),
          _buildTermsAndConditionsRow(),
          const SizedBox(height: 20),
          _buildAuthButton(),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isConfirmField,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (isConfirmField && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              _passwordFocusNode.hasFocus ? Colors.black87 : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _authenticate(),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, delay: 200.ms);
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value!),
            activeColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const Text('Remember me', style: TextStyle(fontSize: 14)),
        const Spacer(),
        TextButton(
          onPressed: () => _showResetPasswordDialog(),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value!),
                activeColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'I agree to the',
                    style: TextStyle(fontSize: 14),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'and',
                    style: TextStyle(fontSize: 14),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EULAScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'EULA',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, delay: 300.ms);
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          elevation: 5,
          shadowColor: Colors.teal.withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms);
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canAuthenticateWithBiometrics && canAuthenticate;
      });
    } on PlatformException {
      setState(() {
        _canCheckBiometrics = false;
      });
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      final isFirstTime = !(await db.isPasswordSet());

      if (isFirstTime) {
        await db.setPassword(_passwordController.text);
        
        // For first-time users, show license activation
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LicenseActivationScreen(),
            ),
          );
        }
      } else {
        final isValid = await db.checkPassword(_passwordController.text);
        if (!isValid) {
          _showError('Incorrect password');
          return;
        }

        // Check license status before proceeding
        final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
        await licenseProvider.initializeLicense();
        final licenseStatus = await licenseProvider.getLicenseStatus();

        if (mounted) {
          if (licenseStatus['status'] == 'inactive') {
            // No active license, show activation screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LicenseActivationScreen(),
              ),
            );
          } else {
            // Has active license, proceed to home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'Please contact your system administrator to reset your password.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return TextButton.icon(
      onPressed: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                if (await _authenticateWithBiometrics()) {
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      icon: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : const Icon(Icons.fingerprint, size: 28),
      label: Text(_isLoading ? 'Authenticating...' : 'Use Biometric Login'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Colors.black87),
        ),
      ),
    );
  }

  Future<bool> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = await _localAuth.isDeviceSupported();

      if (canAuthenticateWithBiometrics && canAuthenticate) {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access LedgerPro',
          options: const AuthenticationOptions(
            stickyAuth: true,
          ),
        );

        if (authenticated) {
          // Check if password is set in database before proceeding
          final bool isPasswordSet =
              await DatabaseHelper.instance.isPasswordSet();
          if (!isPasswordSet) {
            authenticated = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please set up a password first before using biometric login'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return authenticated;
  }
}
