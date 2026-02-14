import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/recommendations_provider.dart';
import '../common/app_card.dart';
import 'workflow_step_tile.dart';

class WorkflowProgress extends StatelessWidget {
  const WorkflowProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationsProvider>(
      builder: (context, provider, _) {
        final steps = provider.workflowSteps;
        if (steps.isEmpty) return const SizedBox();

        final completed = provider.completedSteps;
        final total = steps.length;
        final isLoading = provider.isLoading;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InkWell(
                onTap: provider.toggleActivityExpanded,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build, color: AppColors.purple, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Research Workflow',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoading
                                ? '$completed of $total steps completed \u00B7 Processing...'
                                : '$completed of $total steps completed',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyan,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      provider.activityExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),

              // Progress bar
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  backgroundColor: AppColors.background,
                  color: AppColors.cyan,
                  minHeight: 4,
                ),
              ),

              // Steps
              if (provider.activityExpanded) ...[
                const SizedBox(height: 8),
                ...steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        const Divider(color: AppColors.border, height: 1),
                      WorkflowStepTile(
                        step: step,
                        isExpanded: provider.expandedSteps.contains(index),
                        onToggle: () => provider.toggleStepExpanded(index),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
