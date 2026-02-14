import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/error_banner.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _currency = 'USD';
  String _riskTolerance = 'moderate';
  bool _isLoading = false;
  String? _error;

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  static const _riskLevels = [
    ('conservative', 'Conservative'),
    ('moderate', 'Moderate'),
    ('aggressive', 'Aggressive'),
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        currencyPreference: _currency,
        riskTolerance: _riskTolerance,
      );
      if (mounted) context.go('/portfolio');
    } catch (e) {
      setState(() => _error = e.toString());
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.gradientCyanPurple.createShader(bounds),
                child: const Text(
                  'InvestTrack',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        ErrorBanner(
                          message: _error!,
                          onDismiss: () => setState(() => _error = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppInput(
                        label: 'Full Name',
                        controller: _fullNameController,
                        required: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => validateMinLength(v, 2, 'Full name'),
                        hintText: 'Enter your full name',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Email',
                        controller: _emailController,
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: validateEmail,
                        hintText: 'Enter your email',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Password',
                        controller: _passwordController,
                        required: true,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: validatePassword,
                        hintText: 'At least 8 characters',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        required: true,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            validatePasswordMatch(v, _passwordController.text),
                        hintText: 'Confirm your password',
                      ),
                      const SizedBox(height: 16),
                      AppDropdown(
                        label: 'Currency Preference',
                        value: _currency,
                        items: _currencies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      ),
                      const SizedBox(height: 16),
                      AppDropdown(
                        label: 'Risk Tolerance',
                        value: _riskTolerance,
                        items: _riskLevels
                            .map((r) => DropdownMenuItem(
                                  value: r.$1,
                                  child: Text(r.$2),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _riskTolerance = v ?? 'moderate'),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Create Account',
                        onPressed: _handleSignup,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
