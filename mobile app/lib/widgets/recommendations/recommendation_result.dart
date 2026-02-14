import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../common/app_card.dart';

class RecommendationResult extends StatelessWidget {
  final String recommendation;

  const RecommendationResult({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.success, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Personalized Recommendation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Markdown content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: MarkdownBody(
              data: recommendation,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                em: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                listBullet: const TextStyle(color: AppColors.cyan),
                blockquoteDecoration: BoxDecoration(
                  border: const Border(left: BorderSide(color: AppColors.cyan, width: 3)),
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                blockquotePadding: const EdgeInsets.all(12),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                code: const TextStyle(
                  fontSize: 13,
                  color: AppColors.cyan,
                  backgroundColor: AppColors.surface,
                ),
                horizontalRuleDecoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
