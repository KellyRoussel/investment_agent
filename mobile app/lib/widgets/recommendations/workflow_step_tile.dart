import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/recommendation.dart';

class WorkflowStepTile extends StatelessWidget {
  final WorkflowStep step;
  final bool isExpanded;
  final VoidCallback onToggle;

  const WorkflowStepTile({
    super.key,
    required this.step,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step header
        InkWell(
          onTap: step.status != WorkflowStepStatus.pending ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                _StatusIcon(status: step.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: step.status == WorkflowStepStatus.pending
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (step.toolCalls.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${step.toolCalls.length} tools',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                if (step.status != WorkflowStepStatus.pending)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),

        // Expanded content
        if (isExpanded) ...[
          // Tool calls
          if (step.toolCalls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8, bottom: 8),
              child: Column(
                children: step.toolCalls.map((tc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.search, color: AppColors.cyan, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tc.toolName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (tc.query.isNotEmpty)
                                Text(
                                  tc.query,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Summary
          if (step.summary != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 8, bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  step.summary!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final WorkflowStepStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WorkflowStepStatus.pending => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textMuted, width: 2),
          ),
        ),
      WorkflowStepStatus.inProgress => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      WorkflowStepStatus.completed => const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        ),
    };
  }
}
