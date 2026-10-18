import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/auth_repository.dart';
import '../view_models/register_view_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegisterViewModel _viewModel;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(AuthRepository());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = await _viewModel.register(
      username: _usernameController.text,
      email: _emailController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      password: _passwordController.text,
    );

    if (!mounted || username == null) return;

    // Navigate to Home Page and remove all previous routes (so they can't hit 'back' to go to register)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage(email: username)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textColor),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join your local NeighbourShield community.',
                        style: TextStyle(color: AppTheme.mutedColor),
                      ),
                      const SizedBox(height: 26),

                      // Username
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(hintText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 16),

                      // First & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(hintText: 'First Name'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(hintText: 'Last Name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(hintText: 'Unit Address (e.g. A-12-03)', prefixIcon: Icon(Icons.home_outlined)),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                      ),

                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _viewModel.isLoading ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _viewModel.isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}