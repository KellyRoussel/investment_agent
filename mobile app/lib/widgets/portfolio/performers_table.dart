import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/portfolio.dart';
import '../common/app_card.dart';

class PerformersTable extends StatelessWidget {
  final String title;
  final List<TopPerformer> performers;
  final bool isTop;

  const PerformersTable({
    super.key,
    required this.title,
    required this.performers,
    this.isTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isTop ? AppColors.success : AppColors.danger;
    final trendIcon = isTop ? Icons.trending_up : Icons.trending_down;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (performers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...performers.asMap().entries.map((entry) {
              final index = entry.key;
              final performer = entry.value;
              final color = getGainLossColor(performer.gainLossPercent);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  border: index < performers.length - 1
                      ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Symbol & Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            performer.symbol,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            performer.name,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Percentage
                    Text(
                      formatPercentage(performer.gainLossPercent),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
