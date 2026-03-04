class WatchlistItem {
  final String id;
  final String? symbol;
  final String name;
  final String? sector;
  final String? country;
  final String? reason;
  final String? source; // 'agent_suggestion' or 'manual'
  final String? priority; // 'high', 'normal', 'low'
  final bool isActive;
  final String createdAt;

  WatchlistItem({
    required this.id,
    this.symbol,
    required this.name,
    this.sector,
    this.country,
    this.reason,
    this.source,
    this.priority,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAiSuggested => source == 'agent_suggestion';

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      symbol: json['symbol'] as String?,
      name: json['name'] as String,
      sector: json['sector'] as String?,
      country: json['country'] as String?,
      reason: json['reason'] as String?,
      source: json['source'] as String?,
      priority: json['priority'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
    );
  }
}

class WatchlistItemCreate {
  final String name;
  final String? symbol;
  final String? sector;
  final String? country;
  final String? reason;
  final String? priority;

  WatchlistItemCreate({
    required this.name,
    this.symbol,
    this.sector,
    this.country,
    this.reason,
    this.priority,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name};
    if (symbol != null && symbol!.isNotEmpty) map['symbol'] = symbol;
    if (sector != null && sector!.isNotEmpty) map['sector'] = sector;
    if (country != null && country!.isNotEmpty) map['country'] = country;
    if (reason != null && reason!.isNotEmpty) map['reason'] = reason;
    if (priority != null) map['priority'] = priority;
    return map;
  }
}
