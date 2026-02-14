/// Safely parse a value that may be num or String to double.
double _toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class PortfolioBreakdownItem {
  final String category;
  final double value;
  final double percentage;
  final int count;

  PortfolioBreakdownItem({
    required this.category,
    required this.value,
    required this.percentage,
    required this.count,
  });

  factory PortfolioBreakdownItem.fromJson(String key, Map<String, dynamic> json) {
    return PortfolioBreakdownItem(
      category: key,
      value: _toDouble(json['value']),
      percentage: _toDouble(json['percentage']),
      count: _toInt(json['count']),
    );
  }
}

class TopPerformer {
  final String investmentId;
  final String symbol;
  final String name;
  final double gainLossPercent;

  TopPerformer({
    required this.investmentId,
    required this.symbol,
    required this.name,
    required this.gainLossPercent,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      investmentId: json['investment_id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      gainLossPercent: _toDouble(json['gain_loss_percent']),
    );
  }
}

class PortfolioMetrics {
  final String userId;
  final double totalValue;
  final double totalCost;
  final double totalGainLoss;
  final double totalGainLossPercent;
  final double diversificationScore;
  final int investmentCount;
  final List<PortfolioBreakdownItem> breakdownByCountry;
  final List<PortfolioBreakdownItem> breakdownBySector;
  final List<PortfolioBreakdownItem> breakdownByAssetType;
  final List<TopPerformer> topPerformers;
  final List<TopPerformer> worstPerformers;
  final String currency;

  PortfolioMetrics({
    required this.userId,
    required this.totalValue,
    required this.totalCost,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.diversificationScore,
    required this.investmentCount,
    required this.breakdownByCountry,
    required this.breakdownBySector,
    required this.breakdownByAssetType,
    required this.topPerformers,
    required this.worstPerformers,
    required this.currency,
  });

  factory PortfolioMetrics.fromJson(Map<String, dynamic> json) {
    return PortfolioMetrics(
      userId: json['user_id'] as String,
      totalValue: _toDouble(json['total_value']),
      totalCost: _toDouble(json['total_cost']),
      totalGainLoss: _toDouble(json['total_gain_loss']),
      totalGainLossPercent: _toDouble(json['total_gain_loss_percent']),
      diversificationScore: _toDouble(json['diversification_score']),
      investmentCount: _toInt(json['investment_count']),
      breakdownByCountry: _parseBreakdown(json['breakdown_by_country']),
      breakdownBySector: _parseBreakdown(json['breakdown_by_sector']),
      breakdownByAssetType: _parseBreakdown(json['breakdown_by_asset_type']),
      topPerformers: (json['top_performers'] as List?)
              ?.map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      worstPerformers: (json['worst_performers'] as List?)
              ?.map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  static List<PortfolioBreakdownItem> _parseBreakdown(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return [];
    return data.entries
        .map((e) => PortfolioBreakdownItem.fromJson(e.key, e.value as Map<String, dynamic>))
        .toList();
  }
}

class PortfolioHistoryPoint {
  final String timestamp;
  final double totalValue;
  final double totalCost;
  final double totalGainLoss;

  PortfolioHistoryPoint({
    required this.timestamp,
    required this.totalValue,
    required this.totalCost,
    required this.totalGainLoss,
  });

  DateTime get date => DateTime.parse(timestamp);

  factory PortfolioHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryPoint(
      timestamp: json['timestamp'] as String,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      totalGainLoss: (json['total_gain_loss'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PortfolioHistoryResponse {
  final String userId;
  final List<PortfolioHistoryPoint> dataPoints;
  final int totalPoints;
  final String? startDate;
  final String? endDate;

  PortfolioHistoryResponse({
    required this.userId,
    required this.dataPoints,
    required this.totalPoints,
    this.startDate,
    this.endDate,
  });

  factory PortfolioHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryResponse(
      userId: json['user_id'] as String,
      dataPoints: (json['data_points'] as List)
          .map((e) => PortfolioHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPoints: json['total_points'] as int,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}
