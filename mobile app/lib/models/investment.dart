double _toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class Investment {
  final String id;
  final String userId;
  final String symbol;
  final String name;
  final String assetType;
  final String country;
  final String? sector;
  final String? industry;
  final String? marketCapCategory;
  final String purchaseDate;
  final double purchasePrice;
  final double quantity;
  final String currency;
  final double? dividendYield;
  final double? expenseRatio;
  final String? notes;
  final String? investmentThesis;
  final String? thesisStatus;
  final double? alertThresholdPct;
  final String? accountType;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Investment({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.assetType,
    required this.country,
    this.sector,
    this.industry,
    this.marketCapCategory,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.quantity,
    required this.currency,
    this.dividendYield,
    this.expenseRatio,
    this.notes,
    this.investmentThesis,
    this.thesisStatus,
    this.alertThresholdPct,
    this.accountType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalCost => purchasePrice * quantity;

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      assetType: json['asset_type'] as String,
      country: json['country'] as String? ?? '',
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      marketCapCategory: json['market_cap_category'] as String?,
      purchaseDate: json['purchase_date'] as String,
      purchasePrice: _toDouble(json['purchase_price']),
      quantity: _toDouble(json['quantity']),
      currency: json['currency'] as String? ?? 'USD',
      dividendYield: json['dividend_yield'] != null
          ? _toDouble(json['dividend_yield'])
          : null,
      expenseRatio: json['expense_ratio'] != null
          ? _toDouble(json['expense_ratio'])
          : null,
      notes: json['notes'] as String?,
      investmentThesis: json['investment_thesis'] as String?,
      thesisStatus: json['thesis_status'] as String?,
      alertThresholdPct: json['alert_threshold_pct'] != null
          ? _toDouble(json['alert_threshold_pct'])
          : null,
      accountType: json['account_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'symbol': symbol,
    'name': name,
    'asset_type': assetType,
    'country': country,
    'sector': sector,
    'industry': industry,
    'market_cap_category': marketCapCategory,
    'purchase_date': purchaseDate,
    'purchase_price': purchasePrice,
    'quantity': quantity,
    'currency': currency,
    'dividend_yield': dividendYield,
    'expense_ratio': expenseRatio,
    'notes': notes,
    'investment_thesis': investmentThesis,
    'thesis_status': thesisStatus,
    'alert_threshold_pct': alertThresholdPct,
    'account_type': accountType,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class InvestmentCreate {
  final String accountType;
  final String? tickerSymbol;
  final String? isin;
  final String purchaseDate;
  final double quantity;
  final String? notes;
  final String? investmentThesis;
  final String? thesisStatus;
  final double? alertThresholdPct;

  InvestmentCreate({
    required this.accountType,
    this.tickerSymbol,
    this.isin,
    required this.purchaseDate,
    required this.quantity,
    this.notes,
    this.investmentThesis,
    this.thesisStatus,
    this.alertThresholdPct,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'account_type': accountType,
      'purchase_date': purchaseDate,
      'quantity': quantity,
    };
    if (tickerSymbol != null) map['ticker_symbol'] = tickerSymbol;
    if (isin != null) map['isin'] = isin;
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    if (investmentThesis != null && investmentThesis!.isNotEmpty) {
      map['investment_thesis'] = investmentThesis;
    }
    if (thesisStatus != null) map['thesis_status'] = thesisStatus;
    if (alertThresholdPct != null) map['alert_threshold_pct'] = alertThresholdPct;
    return map;
  }
}

class InvestmentInitialValues {
  final String? accountType;
  final String? tickerSymbol;
  final double? suggestedQuantity;
  final String? investmentThesis;
  final String? notes;
  final double? alertThresholdPct;

  const InvestmentInitialValues({
    this.accountType,
    this.tickerSymbol,
    this.suggestedQuantity,
    this.investmentThesis,
    this.notes,
    this.alertThresholdPct,
  });
}
