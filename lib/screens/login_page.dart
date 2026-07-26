import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form Key & Field Input Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _callsignController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _targetNodeController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // Basic verification prior to triggering execution state
    if (_callsignController.text.isEmpty || _passcodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your credentials')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network authentication latency delay safely
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Securely cache a mockup session token to allow session persistency downstream
    await SecureStorageService.saveUserToken(
        "mock_fso_secure_auth_token_xyz123");

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Route forward into the hardware pairing page interface
      Navigator.pushReplacementNamed(context, '/hardware');
    }
  }

  @override
  void dispose() {
    _callsignController.dispose();
    _passcodeController.dispose();
    _targetNodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  const Icon(
                    Icons.lens_blur,
                    color: Colors.cyan,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QUANTUM LINK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Text(
                    'FSO Transceiver Control Interface',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Operator Input Field
                  TextFormField(
                    controller: _callsignController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Operator Callsign',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person, color: Colors.cyan),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF222222)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.cyan),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Passcode Input Field
                  TextFormField(
                    controller: _passcodeController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Secret Passcode',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock, color: Colors.cyan),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF222222)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.cyan),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Execution Action Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'INITIALIZE SESSION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
