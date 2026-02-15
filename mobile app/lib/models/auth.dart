import 'user.dart';

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class OAuthExchangeResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final User user;

  OAuthExchangeResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory OAuthExchangeResponse.fromJson(Map<String, dynamic> json) {
    return OAuthExchangeResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
