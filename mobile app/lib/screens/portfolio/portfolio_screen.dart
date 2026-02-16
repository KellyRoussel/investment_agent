import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/charts/portfolio_history_chart.dart';
import '../../widgets/charts/breakdown_pie_chart.dart';
import '../../widgets/common/loading_spinner.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/portfolio/portfolio_metrics_card.dart';
import '../../widgets/portfolio/performers_table.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<PortfolioProvider>();
    await Future.wait([
      provider.fetchMetrics(),
      provider.fetchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currency = context.watch<ProfileProvider>().profile?.currencyPreference ?? 'USD';

    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Safe area padding for status bar
                SizedBox(height: MediaQuery.of(context).padding.top),

                // Header
                const Text(
                  'Portfolio Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (user != null)
                  Text(
                    'Welcome back, ${user.name}!',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 20),

                if (provider.error != null) ...[
                  ErrorBanner(message: provider.error!),
                  const SizedBox(height: 16),
                ],

                if (provider.isLoading && provider.metrics == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: LoadingSpinner(size: SpinnerSize.lg),
                    ),
                  )
                else if (provider.metrics != null) ...[
                  // Metrics cards - 2x grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      PortfolioMetricsCard(
                        title: 'Total Value',
                        value: formatCurrency(provider.metrics!.totalValue, currency),
                        icon: Icons.account_balance_wallet,
                        subtitle: '${provider.metrics!.investmentCount} investments',
                      ),
                      PortfolioMetricsCard(
                        title: 'Total Cost',
                        value: formatCurrency(provider.metrics!.totalCost, currency),
                        icon: Icons.payments,
                      ),
                      PortfolioMetricsCard(
                        title: 'Total Gain/Loss',
                        value: formatCurrency(provider.metrics!.totalGainLoss, currency),
                        icon: Icons.show_chart,
                        showTrend: true,
                        trendValue: provider.metrics!.totalGainLossPercent,
                      ),
                      PortfolioMetricsCard(
                        title: 'Return',
                        value: formatPercentage(provider.metrics!.totalGainLossPercent),
                        icon: Icons.emoji_events,
                        showTrend: true,
                        trendValue: provider.metrics!.totalGainLossPercent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Portfolio History Chart
                  PortfolioHistoryChart(currency: currency),
                  const SizedBox(height: 20),

                  // Breakdown section - 2 cards per row grid
                  const SectionHeader(title: 'Portfolio Breakdown', icon: Icons.donut_large),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      PortfolioMetricsCard(
                        title: 'Diversification',
                        value: provider.metrics!.diversificationScore.toStringAsFixed(1),
                        icon: Icons.donut_small,
                        subtitle: 'out of 10',
                      ),
                      BreakdownPieChart(
                        title: 'By Asset Type',
                        data: provider.metrics!.breakdownByAssetType,
                        currency: currency,
                      ),
                      BreakdownPieChart(
                        title: 'By Country',
                        data: provider.metrics!.breakdownByCountry,
                        currency: currency,
                      ),
                      BreakdownPieChart(
                        title: 'By Sector',
                        data: provider.metrics!.breakdownBySector,
                        currency: currency,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Performance leaders
                  const SectionHeader(title: 'Performance Leaders', icon: Icons.leaderboard),
                  PerformersTable(
                    title: 'Top Performers',
                    performers: provider.metrics!.topPerformers,
                    isTop: true,
                  ),
                  const SizedBox(height: 16),
                  PerformersTable(
                    title: 'Worst Performers',
                    performers: provider.metrics!.worstPerformers,
                    isTop: false,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
