import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../data/auth_repository.dart';
import '../view_models/login_view_model.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final AppSession session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginViewModel _viewModel;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();

    _viewModel = LoginViewModel(AuthRepository());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final user = await _viewModel.signIn(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted || user == null) return;

    // Use the role and profile returned by Django instead of assuming Resident.
    widget.session.signIn(user);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.shield,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'NeighbourShield',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Safer communities, together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.mutedColor,
                        ),
                      ),
                      const SizedBox(height: 42),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your community account.',
                        style: TextStyle(color: AppTheme.mutedColor),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 9),
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Enter your username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 9),
                      TextField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _showMessage(
                              'Password recovery will be added later.',
                            );
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _viewModel.isLoading
                              ? null
                              : _handleSignIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _viewModel.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterPage(session: widget.session),
                                ),
                              );
                            },
                            child: const Text('Create account'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'COMMUNITY SAFETY STARTS WITH US',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedColor,
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
