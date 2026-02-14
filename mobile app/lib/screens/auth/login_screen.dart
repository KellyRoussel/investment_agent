import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
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
              // Logo
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
                'Sign in to your account',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Form card
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
                        textInputAction: TextInputAction.done,
                        validator: (v) => validateRequired(v, 'Password'),
                        hintText: 'Enter your password',
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Sign in',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text(
                      'Sign up',
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
