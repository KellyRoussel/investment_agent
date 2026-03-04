class User {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final String provider;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    required this.provider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      picture: json['picture'] as String?,
      provider: json['provider'] as String? ?? 'GOOGLE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'picture': picture,
    'provider': provider,
  };
}

class InvestmentProfile {
  final String currencyPreference;
  final String riskTolerance;
  final String? investmentHorizon;
  final String? country;
  final String? ethicalExclusions;
  final String? interests;
  final String? lastMacroContext;

  InvestmentProfile({
    required this.currencyPreference,
    required this.riskTolerance,
    this.investmentHorizon,
    this.country,
    this.ethicalExclusions,
    this.interests,
    this.lastMacroContext,
  });

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    return InvestmentProfile(
      currencyPreference: json['currency_preference'] as String? ?? 'USD',
      riskTolerance: json['risk_tolerance'] as String? ?? 'moderate',
      investmentHorizon: json['investment_horizon'] as String?,
      country: json['country'] as String?,
      ethicalExclusions: json['ethical_exclusions'] as String?,
      interests: json['interests'] as String?,
      lastMacroContext: json['last_macro_context'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_preference': currencyPreference,
    'risk_tolerance': riskTolerance,
    'investment_horizon': investmentHorizon,
    'country': country,
    'ethical_exclusions': ethicalExclusions,
    'interests': interests,
    'last_macro_context': lastMacroContext,
  };
}

class InvestmentProfileUpdate {
  final String? currencyPreference;
  final String? riskTolerance;
  final String? investmentHorizon;
  final String? country;
  final String? ethicalExclusions;
  final String? interests;

  InvestmentProfileUpdate({
    this.currencyPreference,
    this.riskTolerance,
    this.investmentHorizon,
    this.country,
    this.ethicalExclusions,
    this.interests,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (currencyPreference != null) map['currency_preference'] = currencyPreference;
    if (riskTolerance != null) map['risk_tolerance'] = riskTolerance;
    if (investmentHorizon != null) map['investment_horizon'] = investmentHorizon;
    if (country != null) map['country'] = country;
    if (ethicalExclusions != null) map['ethical_exclusions'] = ethicalExclusions;
    if (interests != null) map['interests'] = interests;
    return map;
  }
}
