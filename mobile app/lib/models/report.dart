class InvestmentReport {
  final String id;
  final String userId;
  final String reportDate;
  final String? finalRecommendation;
  final String status; // 'in_progress' | 'completed' | 'failed'
  final String createdAt;
  final String? completedAt;
  final int? tokensInput;
  final int? tokensCached;
  final int? tokensOutput;
  final double? costUsd;
  final String? modelUsed;

  InvestmentReport({
    required this.id,
    required this.userId,
    required this.reportDate,
    this.finalRecommendation,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.tokensInput,
    this.tokensCached,
    this.tokensOutput,
    this.costUsd,
    this.modelUsed,
  });

  factory InvestmentReport.fromJson(Map<String, dynamic> json) {
    return InvestmentReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportDate: json['report_date'] as String,
      finalRecommendation: json['final_recommendation'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
      tokensInput: json['tokens_input'] as int?,
      tokensCached: json['tokens_cached'] as int?,
      tokensOutput: json['tokens_output'] as int?,
      costUsd: json['cost_usd'] != null
          ? (json['cost_usd'] as num).toDouble()
          : null,
      modelUsed: json['model_used'] as String?,
    );
  }
}
