import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/success_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currency = 'USD';
  String _riskTolerance = 'moderate';

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  static const _riskLevels = [
    ('conservative', 'Conservative'),
    ('moderate', 'Moderate'),
    ('aggressive', 'Aggressive'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadStoredProfile();
    });
  }

  void _initEditFields(InvestmentProfile? profile) {
    _currency = profile?.currencyPreference ?? 'USD';
    _riskTolerance = profile?.riskTolerance ?? 'moderate';
  }

  Future<void> _savePrefs() async {
    await context.read<ProfileProvider>().updatePreferences(
      InvestmentProfileUpdate(
        currencyPreference: _currency,
        riskTolerance: _riskTolerance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;

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

              // User Information Card (read-only, from Google)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (user.picture != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              user.picture!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                            ),
                          )
                        else
                          const _AvatarPlaceholder(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${user.provider.toLowerCase()} account',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.email,
                      iconColor: AppColors.purple,
                      label: 'Email',
                      value: user.email,
                    ),
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
                          'Investment Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!profileProvider.isEditingPrefs)
                          IconButton(
                            onPressed: () {
                              _initEditFields(profile);
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
                              onPressed: _savePrefs,
                              isLoading: profileProvider.isLoading,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _PrefRow(
                        label: 'Currency',
                        value: profile?.currencyPreference ?? 'USD',
                      ),
                      const SizedBox(height: 8),
                      _PrefRow(
                        label: 'Risk Tolerance',
                        value: _capitalize(profile?.riskTolerance ?? 'moderate'),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.person, color: AppColors.cyan, size: 28),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
