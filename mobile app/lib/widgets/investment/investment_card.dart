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
          // Header: Symbol + Account Type badge + Asset Type badge
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
              Row(
                children: [
                  if (investment.accountType != null) ...[
                    _Badge(label: investment.accountType!, color: AppColors.cyan),
                    const SizedBox(width: 6),
                  ],
                  _Badge(
                    label: formatAssetType(investment.assetType),
                    color: const Color(0xFF3B82F6),
                  ),
                ],
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
          if (investment.thesisStatus != null) ...[
            const SizedBox(height: 6),
            _ThesisStatusBadge(status: investment.thesisStatus!),
          ],
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

          if (investment.investmentThesis != null) ...[
            const SizedBox(height: 10),
            Text(
              investment.investmentThesis!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (investment.sector != null || investment.alertThresholdPct != null) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            if (investment.sector != null)
              Text(
                investment.sector!,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            if (investment.alertThresholdPct != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Alert at ${investment.alertThresholdPct!.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ThesisStatusBadge extends StatelessWidget {
  final String status;

  const _ThesisStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'valid' => (AppColors.success, 'Valid'),
      'watch' => (AppColors.warning, 'Watch'),
      'reconsider' => (AppColors.danger, 'Reconsider'),
      _ => (AppColors.textMuted, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
