// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - Authentication Screen
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/techdaddy_logo.dart';
import '../dashboard/main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final _emailController = TextEditingController(text: 'trader@tdtrader.io');
  final _fullNameController =
      TextEditingController(text: 'Chief Quantitative Trader');
  final _passwordController = TextEditingController(text: 'FintechPro#2026!');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await apiService.register(
          _emailController.text.trim(),
          _fullNameController.text.trim(),
          _passwordController.text,
        );
      } else {
        await apiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiService.formatUserFriendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TechDaddy Official TD Logo
                    const TechDaddyLogo(
                        size: 72, showText: true, showCopyright: false),
                    const SizedBox(height: 6),
                    const Text(
                      'Trade Smarter. Think Faster. Let AI Explain.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bearishRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.bearishRed),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppColors.bearishRed, fontSize: 12),
                        ),
                      ),

                    if (_isSignUp) ...[
                      TextField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon:
                              Icon(Icons.person, color: AppColors.primaryCyan),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon:
                            Icon(Icons.email, color: AppColors.primaryCyan),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            Icon(Icons.lock, color: AppColors.primaryCyan),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(_isSignUp
                                ? 'CREATE ACCOUNT'
                                : 'SECURE SIGN IN'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already registered? Sign in'
                            : "Don't have an account? Create one",
                        style: const TextStyle(
                            color: AppColors.primaryCyan, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Copyright © 2026 TechDaddy. All rights reserved.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
