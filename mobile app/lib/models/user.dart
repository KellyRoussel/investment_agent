class User {
  final String id;
  final String email;
  final String fullName;
  final String currencyPreference;
  final String riskTolerance;
  final bool isActive;
  final bool emailVerified;
  final String? lastLogin;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.currencyPreference,
    required this.riskTolerance,
    required this.isActive,
    required this.emailVerified,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      currencyPreference: json['currency_preference'] as String? ?? 'USD',
      riskTolerance: json['risk_tolerance'] as String? ?? 'moderate',
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      lastLogin: json['last_login'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'currency_preference': currencyPreference,
    'risk_tolerance': riskTolerance,
    'is_active': isActive,
    'email_verified': emailVerified,
    'last_login': lastLogin,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class UserUpdate {
  final String? email;
  final String? fullName;
  final String? currencyPreference;
  final String? riskTolerance;

  UserUpdate({this.email, this.fullName, this.currencyPreference, this.riskTolerance});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (fullName != null) map['full_name'] = fullName;
    if (currencyPreference != null) map['currency_preference'] = currencyPreference;
    if (riskTolerance != null) map['risk_tolerance'] = riskTolerance;
    return map;
  }
}
