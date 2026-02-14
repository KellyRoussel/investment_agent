import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/investments_provider.dart';
import '../../services/investments_service.dart';
import '../../widgets/common/loading_spinner.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/investment/investment_card.dart';
import '../../widgets/investment/add_investment_modal.dart';
import '../../widgets/investment/investment_detail_sheet.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestmentsProvider>().fetchInvestments();
    });
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddInvestmentModal(
        onAdd: (data) async {
          await context.read<InvestmentsProvider>().addInvestment(data);
        },
      ),
    );
  }

  void _showDetail(investment) {
    final investmentsService = context.read<InvestmentsService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvestmentDetailSheet(
        investment: investment,
        investmentsService: investmentsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvestmentsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.gradientCyanPurple,
              shape: BoxShape.circle,
            ),
            child: FloatingActionButton(
              onPressed: _showAddModal,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchInvestments(),
            color: AppColors.cyan,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Investments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${provider.investments.length} investments',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                if (provider.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ErrorBanner(message: provider.error!),
                    ),
                  ),

                if (provider.isLoading && provider.investments.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: LoadingSpinner(size: SpinnerSize.lg)),
                  )
                else if (provider.investments.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No investments yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add your first investment',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final investment = provider.investments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InvestmentCard(
                              investment: investment,
                              onTap: () => _showDetail(investment),
                            ),
                          );
                        },
                        childCount: provider.investments.length,
                      ),
                    ),
                  ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }
}
