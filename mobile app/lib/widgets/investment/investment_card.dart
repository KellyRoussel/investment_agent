import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/investment.dart';
import '../common/app_card.dart';

class InvestmentCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback? onTap;

  const InvestmentCard({
    super.key,
    required this.investment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Symbol + Asset Type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                investment.symbol,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formatAssetType(investment.assetType),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            investment.name,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Stats
          _InfoRow(label: 'Quantity', value: investment.quantity.toString()),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Purchase Price',
            value: formatCurrency(investment.purchasePrice, investment.currency),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Total Cost',
            value: formatCurrency(investment.totalCost, investment.currency),
          ),

          if (investment.sector != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Text(
              investment.sector!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
