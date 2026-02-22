import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Local backend for API calls (investments, portfolio, recommendations, profile)
  static String get baseUrl => dotenv.env['BASE_URL']!;

  // Production backend for OAuth (Google requires a valid HTTPS domain as redirect URI)
  static String get oauthBaseUrl => dotenv.env['OAUTH_BASE_URL']!;

  static const appName = 'investtrack';

  // Health
  static const health = '/health';

  // Auth (Google OAuth)
  static const googleAuthUrl = '/login/google/$appName';
  static String exchangeCode(String code, String state) =>
      '/auth/exchange/$appName?code=$code&state=$state&service=GOOGLE';
  static const refreshToken = '/auth/refresh-token';

  // Investments
  static const investments = '/investment/investments';
  static const userInvestments = '/investment/investments';
  static String updateInvestment(String id) => '/investment/investments/$id';
  static String deleteInvestment(String id) => '/investment/investments/$id';
  static String priceHistory(String id) =>
      '/investment/investments/$id/price-history';

  // Portfolio
  static const portfolioMetrics = '/investment/portfolio/metrics';
  static const portfolioHistory = '/investment/portfolio/price-history';

  // Recommendations
  static const recommendations = '/investment/recommendations/generate/v2';

  // Profile
  static const investmentProfile = '/investment/profile';
}
