import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/investment.dart';
import '../../models/recommendation.dart';
import '../../providers/investments_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/investment/add_investment_modal.dart';
import '../../widgets/recommendations/workflow_progress.dart';
import '../../widgets/recommendations/recommendation_result.dart';

class _WorkflowCostBanner extends StatelessWidget {
  final WorkflowCost cost;
  const _WorkflowCostBanner({required this.cost});

  @override
  Widget build(BuildContext context) {
    final totalK = (cost.totalTokens / 1000).toStringAsFixed(1);
    final cachedK = (cost.tokensCached / 1000).toStringAsFixed(1);
    final costStr = cost.costUsd < 0.01
        ? '\$${cost.costUsd.toStringAsFixed(4)}'
        : '\$${cost.costUsd.toStringAsFixed(3)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          const Text(
            'Workflow cost',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Chip(label: '${totalK}k tokens', color: AppColors.purple),
                  if (cost.hasCachedTokens) ...[
                    const SizedBox(width: 6),
                    _Chip(label: '${cachedK}k cached', color: AppColors.warning),
                  ],
                  const SizedBox(width: 6),
                  _Chip(label: costStr, color: AppColors.cyan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final InvestmentSuggestion suggestion;
  final VoidCallback onAddToPortfolio;

  const _SuggestionCard({required this.suggestion, required this.onAddToPortfolio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                suggestion.symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: Text(
                  suggestion.accountType,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
              const Spacer(),
              if (suggestion.allocationEur != null)
                Text(
                  '€${suggestion.allocationEur!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
            ],
          ),
          if (suggestion.name != null) ...[
            const SizedBox(height: 2),
            Text(
              suggestion.name!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (suggestion.currentPrice != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${suggestion.currentPrice!.toStringAsFixed(2)} ${suggestion.currency ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (suggestion.suggestedQuantity != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '× ${suggestion.suggestedQuantity!.toStringAsFixed(suggestion.suggestedQuantity! % 1 == 0 ? 0 : 2)} shares',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
          if (suggestion.investmentThesis != null) ...[
            const SizedBox(height: 8),
            Text(
              suggestion.investmentThesis!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToPortfolio,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add to Portfolio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _budgetController = TextEditingController(text: '500');
  final _budgetFocus = FocusNode();
  String? _budgetError;

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  double? get _parsedBudget {
    final v = double.tryParse(_budgetController.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _onGenerate(RecommendationsProvider provider) {
    final budget = _parsedBudget;
    if (budget == null) {
      setState(() => _budgetError = 'Enter a valid amount > 0');
      return;
    }
    setState(() => _budgetError = null);
    _budgetFocus.unfocus();
    provider.generateRecommendation(budgetEur: budget);
  }

  void _showAddFromSuggestion(BuildContext ctx, InvestmentSuggestion suggestion) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddInvestmentModal(
        initialValues: InvestmentInitialValues(
          accountType: suggestion.accountType,
          tickerSymbol: suggestion.symbol,
          suggestedQuantity: suggestion.suggestedQuantity,
          investmentThesis: suggestion.investmentThesis,
          notes: suggestion.notes,
          alertThresholdPct: suggestion.alertThresholdPct,
        ),
        onAdd: (data) async {
          await ctx.read<InvestmentsProvider>().addInvestment(data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationsProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Recommendations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/report-history'),
                    icon: const Icon(Icons.history, size: 16, color: AppColors.textMuted),
                    label: const Text(
                      'History',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Get personalized investment recommendations powered by AI.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Error
              if (provider.error != null) ...[
                ErrorBanner(message: provider.error!),
                const SizedBox(height: 16),
              ],

              // Generate card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientCyanPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Generate Investment Recommendation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our AI analyzes your portfolio, market trends, and your risk profile to provide personalized recommendations.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Budget input
                    TextField(
                      controller: _budgetController,
                      focusNode: _budgetFocus,
                      enabled: !provider.isLoading,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Budget (EUR)',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixText: '€ ',
                        prefixStyle: const TextStyle(color: AppColors.textSecondary),
                        errorText: _budgetError,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Model selector (only shown when models are loaded)
                    if (provider.availableModels.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Model',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: provider.selectedModel,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cyan),
                          ),
                        ),
                        onChanged: provider.isLoading ? null : (v) => provider.selectModel(v!),
                        items: provider.availableModels
                            .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(
                          text: provider.isLoading
                              ? 'Generating...'
                              : 'Ask for Recommendation',
                          icon: Icons.auto_awesome,
                          onPressed: provider.isLoading
                              ? null
                              : () => _onGenerate(provider),
                          isLoading: provider.isLoading,
                        ),
                        if (provider.isLoading) ...[
                          const SizedBox(width: 12),
                          AppButton(
                            text: 'Cancel',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => provider.cancelGeneration(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Workflow progress
              if (provider.workflowSteps.isNotEmpty) ...[
                const WorkflowProgress(),
                const SizedBox(height: 20),
              ],

              // Cost summary
              if (provider.workflowCost != null) ...[
                _WorkflowCostBanner(cost: provider.workflowCost!),
                const SizedBox(height: 16),
              ],

              // Investment suggestions
              if (provider.hasSuggestions) ...[
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      'Investment Suggestions (${provider.suggestions.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.suggestions.map(
                  (s) => _SuggestionCard(
                    suggestion: s,
                    onAddToPortfolio: () => _showAddFromSuggestion(context, s),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Recommendation result
              if (provider.recommendation != null)
                RecommendationResult(recommendation: provider.recommendation!),
            ],
          ),
        );
      },
    );
  }
}
