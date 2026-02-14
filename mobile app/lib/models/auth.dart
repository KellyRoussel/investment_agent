class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? currencyPreference;
  final String? riskTolerance;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.currencyPreference,
    this.riskTolerance,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
    };
    if (currencyPreference != null) map['currency_preference'] = currencyPreference;
    if (riskTolerance != null) map['risk_tolerance'] = riskTolerance;
    return map;
  }
}

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}
