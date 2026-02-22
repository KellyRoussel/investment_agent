import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/recommendation.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/recommendations/workflow_progress.dart';
import '../../widgets/recommendations/recommendation_result.dart';

class _WorkflowCostBanner extends StatelessWidget {
  final WorkflowCost cost;
  const _WorkflowCostBanner({required this.cost});

  @override
  Widget build(BuildContext context) {
    final totalK = (cost.totalTokens / 1000).toStringAsFixed(1);
    final cachedK = (cost.tokensCached / 1000).toStringAsFixed(1);
    final costStr = cost.costUsd < 0.01
        ? '\$${cost.costUsd.toStringAsFixed(4)}'
        : '\$${cost.costUsd.toStringAsFixed(3)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          const Text(
            'Workflow cost',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          _Chip(label: '${totalK}k tokens', color: AppColors.purple),
          if (cost.hasCachedTokens) ...[
            const SizedBox(width: 6),
            _Chip(label: '${cachedK}k cached', color: AppColors.warning),
          ],
          const SizedBox(width: 8),
          _Chip(label: costStr, color: AppColors.cyan),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _budgetController = TextEditingController(text: '500');
  final _budgetFocus = FocusNode();
  String? _budgetError;

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  double? get _parsedBudget {
    final v = double.tryParse(_budgetController.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _onGenerate(RecommendationsProvider provider) {
    final budget = _parsedBudget;
    if (budget == null) {
      setState(() => _budgetError = 'Enter a valid amount > 0');
      return;
    }
    setState(() => _budgetError = null);
    _budgetFocus.unfocus();
    provider.generateRecommendation(budgetEur: budget);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationsProvider>(
      builder: (context, provider, _) {
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
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Get personalized investment recommendations powered by AI.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Error
              if (provider.error != null) ...[
                ErrorBanner(message: provider.error!),
                const SizedBox(height: 16),
              ],

              // Generate card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientCyanPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Generate Investment Recommendation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our AI analyzes your portfolio, market trends, and your risk profile to provide personalized recommendations.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Budget input
                    TextField(
                      controller: _budgetController,
                      focusNode: _budgetFocus,
                      enabled: !provider.isLoading,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Budget (EUR)',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixText: '€ ',
                        prefixStyle: const TextStyle(color: AppColors.textSecondary),
                        errorText: _budgetError,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(
                          text: provider.isLoading
                              ? 'Generating...'
                              : 'Ask for Recommendation',
                          icon: Icons.auto_awesome,
                          onPressed: provider.isLoading
                              ? null
                              : () => _onGenerate(provider),
                          isLoading: provider.isLoading,
                        ),
                        if (provider.isLoading) ...[
                          const SizedBox(width: 12),
                          AppButton(
                            text: 'Cancel',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => provider.cancelGeneration(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Workflow progress
              if (provider.workflowSteps.isNotEmpty) ...[
                const WorkflowProgress(),
                const SizedBox(height: 20),
              ],

              // Cost summary
              if (provider.workflowCost != null) ...[
                _WorkflowCostBanner(cost: provider.workflowCost!),
                const SizedBox(height: 16),
              ],

              // Recommendation result
              if (provider.recommendation != null)
                RecommendationResult(recommendation: provider.recommendation!),
            ],
          ),
        );
      },
    );
  }
}
