import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/success_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _currency = 'USD';
  String _riskTolerance = 'moderate';

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  static const _riskLevels = [
    ('conservative', 'Conservative'),
    ('moderate', 'Moderate'),
    ('aggressive', 'Aggressive'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initEditFields(User user) {
    _nameController.text = user.fullName;
    _emailController.text = user.email;
    _currency = user.currencyPreference;
    _riskTolerance = user.riskTolerance;
  }

  Future<void> _saveInfo(User user) async {
    final profileProvider = context.read<ProfileProvider>();
    final updatedUser = await profileProvider.updateProfile(
      user.id,
      UserUpdate(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
    if (updatedUser != null && mounted) {
      context.read<AuthProvider>().setUser(updatedUser);
    }
  }

  Future<void> _savePrefs(User user) async {
    final profileProvider = context.read<ProfileProvider>();
    final updatedUser = await profileProvider.updateProfile(
      user.id,
      UserUpdate(
        currencyPreference: _currency,
        riskTolerance: _riskTolerance,
      ),
    );
    if (updatedUser != null && mounted) {
      context.read<AuthProvider>().setUser(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your account settings and preferences',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Messages
              if (profileProvider.success != null) ...[
                SuccessBanner(
                  message: profileProvider.success!,
                  onDismiss: () => profileProvider.clearMessages(),
                ),
                const SizedBox(height: 16),
              ],
              if (profileProvider.error != null) ...[
                ErrorBanner(
                  message: profileProvider.error!,
                  onDismiss: () => profileProvider.clearMessages(),
                ),
                const SizedBox(height: 16),
              ],

              // User Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'User Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!profileProvider.isEditingInfo)
                          IconButton(
                            onPressed: () {
                              _initEditFields(user);
                              profileProvider.startEditingInfo();
                            },
                            icon: const Icon(Icons.edit, color: AppColors.cyan, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (profileProvider.isEditingInfo) ...[
                      AppInput(
                        label: 'Full Name',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppInput(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Cancel',
                              variant: AppButtonVariant.secondary,
                              onPressed: () => profileProvider.cancelEditingInfo(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Save',
                              onPressed: () => _saveInfo(user),
                              isLoading: profileProvider.isLoading,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _InfoRow(
                        icon: Icons.person,
                        iconColor: AppColors.cyan,
                        label: 'Full Name',
                        value: user.fullName,
                      ),
                      _InfoRow(
                        icon: Icons.email,
                        iconColor: AppColors.purple,
                        label: 'Email',
                        value: user.email,
                        trailing: user.emailVerified
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Verified',
                                  style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              )
                            : null,
                      ),
                      _InfoRow(
                        icon: Icons.access_time,
                        iconColor: AppColors.pink,
                        label: 'Last Login',
                        value: formatDate(user.lastLogin),
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        iconColor: AppColors.success,
                        label: 'Account Created',
                        value: formatDate(user.createdAt),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!profileProvider.isEditingPrefs)
                          IconButton(
                            onPressed: () {
                              _initEditFields(user);
                              profileProvider.startEditingPrefs();
                            },
                            icon: const Icon(Icons.edit, color: AppColors.cyan, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (profileProvider.isEditingPrefs) ...[
                      AppDropdown(
                        label: 'Currency Preference',
                        value: _currency,
                        items: _currencies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      ),
                      const SizedBox(height: 12),
                      AppDropdown(
                        label: 'Risk Tolerance',
                        value: _riskTolerance,
                        items: _riskLevels
                            .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                            .toList(),
                        onChanged: (v) => setState(() => _riskTolerance = v ?? 'moderate'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Cancel',
                              variant: AppButtonVariant.secondary,
                              onPressed: () => profileProvider.cancelEditingPrefs(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Save',
                              onPressed: () => _savePrefs(user),
                              isLoading: profileProvider.isLoading,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _PrefRow(
                        label: 'Currency',
                        value: user.currencyPreference,
                      ),
                      const SizedBox(height: 8),
                      _PrefRow(
                        label: 'Risk Tolerance',
                        value: user.riskTolerance[0].toUpperCase() + user.riskTolerance.substring(1),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Sign Out',
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout,
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String label;
  final String value;

  const _PrefRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
