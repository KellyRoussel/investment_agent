class PriceHistoryPoint {
  final String timestamp;
  final double price;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? closePrice;
  final double? adjustedClose;
  final int? volume;
  final double? marketCap;
  final double? dividendAmount;
  final double? splitRatio;
  final String source;
  final String dataQuality;

  PriceHistoryPoint({
    required this.timestamp,
    required this.price,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.closePrice,
    this.adjustedClose,
    this.volume,
    this.marketCap,
    this.dividendAmount,
    this.splitRatio,
    required this.source,
    required this.dataQuality,
  });

  DateTime get date => DateTime.parse(timestamp);

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPoint(
      timestamp: json['timestamp'] as String,
      price: (json['price'] as num).toDouble(),
      openPrice: json['open_price'] != null ? (json['open_price'] as num).toDouble() : null,
      highPrice: json['high_price'] != null ? (json['high_price'] as num).toDouble() : null,
      lowPrice: json['low_price'] != null ? (json['low_price'] as num).toDouble() : null,
      closePrice: json['close_price'] != null ? (json['close_price'] as num).toDouble() : null,
      adjustedClose: json['adjusted_close'] != null ? (json['adjusted_close'] as num).toDouble() : null,
      volume: json['volume'] as int?,
      marketCap: json['market_cap'] != null ? (json['market_cap'] as num).toDouble() : null,
      dividendAmount: json['dividend_amount'] != null ? (json['dividend_amount'] as num).toDouble() : null,
      splitRatio: json['split_ratio'] != null ? (json['split_ratio'] as num).toDouble() : null,
      source: json['source'] as String? ?? 'unknown',
      dataQuality: json['data_quality'] as String? ?? 'good',
    );
  }
}

class PriceHistoryResponse {
  final String investmentId;
  final String symbol;
  final List<PriceHistoryPoint> dataPoints;
  final int totalPoints;
  final String? startDate;
  final String? endDate;

  PriceHistoryResponse({
    required this.investmentId,
    required this.symbol,
    required this.dataPoints,
    required this.totalPoints,
    this.startDate,
    this.endDate,
  });

  factory PriceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PriceHistoryResponse(
      investmentId: json['investment_id'] as String,
      symbol: json['symbol'] as String,
      dataPoints: (json['data_points'] as List)
          .map((e) => PriceHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPoints: json['total_points'] as int,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}
