import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/loading_spinner.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Report History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (provider.reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate your first recommendation to see it here.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.reports.length,
            itemBuilder: (_, i) => _ReportCard(report: provider.reports[i]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final InvestmentReport report;

  const _ReportCard({required this.report});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final date = _formatDate(report.reportDate);

    final (statusColor, statusLabel) = switch (report.status) {
      'completed' => (AppColors.success, 'Completed'),
      'in_progress' => (AppColors.warning, 'In Progress'),
      'failed' => (AppColors.danger, 'Failed'),
      _ => (AppColors.textMuted, report.status),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible, tappable)
          InkWell(
            onTap: report.finalRecommendation != null
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Status badge
                  _SmallBadge(label: statusLabel, color: statusColor),
                  if (report.modelUsed != null) ...[
                    const SizedBox(width: 6),
                    _SmallBadge(
                      label: _shortenModel(report.modelUsed!),
                      color: AppColors.purple,
                    ),
                  ],
                  if (report.costUsd != null) ...[
                    const SizedBox(width: 6),
                    _SmallBadge(
                      label: '\$${report.costUsd!.toStringAsFixed(4)}',
                      color: AppColors.cyan,
                    ),
                  ],
                  if (report.finalRecommendation != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Token counts
          if (report.tokensInput != null || report.tokensOutput != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.token_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _buildTokensLabel(report),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

          // Expanded markdown content
          if (_expanded && report.finalRecommendation != null)
            Container(
              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: MarkdownBody(
                data: report.finalRecommendation!,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  h1: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  h2: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  h3: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  strong: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  em: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary),
                  listBullet: const TextStyle(color: AppColors.cyan),
                  blockquoteDecoration: BoxDecoration(
                    border: const Border(
                        left: BorderSide(color: AppColors.cyan, width: 3)),
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  blockquotePadding: const EdgeInsets.all(10),
                  code: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cyan,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _shortenModel(String model) {
    if (model.contains('opus')) return 'Opus';
    if (model.contains('sonnet')) return 'Sonnet';
    if (model.contains('haiku')) return 'Haiku';
    if (model.contains('gpt')) return model.split('-').take(3).join('-');
    return model.length > 15 ? '${model.substring(0, 12)}…' : model;
  }

  String _buildTokensLabel(InvestmentReport report) {
    final parts = <String>[];
    if (report.tokensInput != null) {
      parts.add('${_formatK(report.tokensInput!)} in');
    }
    if (report.tokensCached != null && report.tokensCached! > 0) {
      parts.add('${_formatK(report.tokensCached!)} cached');
    }
    if (report.tokensOutput != null) {
      parts.add('${_formatK(report.tokensOutput!)} out');
    }
    return parts.join('  ·  ');
  }

  String _formatK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
