import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PortfolioMetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double? trendValue;
  final bool showTrend;

  const PortfolioMetricsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.trendValue,
    this.showTrend = false,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = (trendValue ?? 0) >= 0 ? AppColors.success : AppColors.danger;
    final trendIcon = (trendValue ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.cyan, size: 16),
              ),
              const Spacer(),
              if (showTrend && trendValue != null) ...[
                Icon(trendIcon, color: trendColor, size: 14),
                const SizedBox(width: 2),
                Text(
                  '${trendValue! >= 0 ? '+' : ''}${trendValue!.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
