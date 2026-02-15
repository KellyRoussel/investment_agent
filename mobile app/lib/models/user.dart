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

  InvestmentProfile({
    required this.currencyPreference,
    required this.riskTolerance,
  });

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    return InvestmentProfile(
      currencyPreference: json['currency_preference'] as String? ?? 'USD',
      riskTolerance: json['risk_tolerance'] as String? ?? 'moderate',
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_preference': currencyPreference,
    'risk_tolerance': riskTolerance,
  };
}

class InvestmentProfileUpdate {
  final String? currencyPreference;
  final String? riskTolerance;

  InvestmentProfileUpdate({this.currencyPreference, this.riskTolerance});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (currencyPreference != null) map['currency_preference'] = currencyPreference;
    if (riskTolerance != null) map['risk_tolerance'] = riskTolerance;
    return map;
  }
}
