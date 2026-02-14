import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/investment.dart';
import '../../services/investments_service.dart';
import '../charts/price_history_chart.dart';

class InvestmentDetailSheet extends StatelessWidget {
  final Investment investment;
  final InvestmentsService investmentsService;

  const InvestmentDetailSheet({
    super.key,
    required this.investment,
    required this.investmentsService,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.symbol,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            investment.name,
                            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Price History Chart
                    PriceHistoryChart(
                      investmentId: investment.id,
                      purchasePrice: investment.purchasePrice,
                      purchaseDate: investment.purchaseDate,
                      currency: investment.currency,
                      investmentsService: investmentsService,
                    ),
                    const SizedBox(height: 24),

                    // Info grid
                    const Text(
                      'Investment Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailGrid(investment: investment),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final Investment investment;

  const _DetailGrid({required this.investment});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Asset Type', formatAssetType(investment.assetType)),
      ('Country', investment.country),
      ('Sector', investment.sector ?? '-'),
      ('Industry', investment.industry ?? '-'),
      ('Purchase Date', formatDate(investment.purchaseDate)),
      ('Quantity', investment.quantity.toString()),
      ('Purchase Price', formatCurrency(investment.purchasePrice, investment.currency)),
      ('Total Cost', formatCurrency(investment.totalCost, investment.currency)),
      if (investment.dividendYield != null)
        ('Dividend Yield', '${investment.dividendYield!.toStringAsFixed(2)}%'),
      if (investment.marketCapCategory != null)
        ('Market Cap', investment.marketCapCategory!.replaceAll('_', ' ').toUpperCase()),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: index < items.length - 1
                  ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
