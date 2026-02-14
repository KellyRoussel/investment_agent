import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/recommendations/workflow_progress.dart';
import '../../widgets/recommendations/recommendation_result.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

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
                              : () => provider.generateRecommendation(),
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
