class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'http://192.168.1.42:8000';

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const me = '/auth/me';

  // Users
  static String updateUser(String userId) => '/users/$userId';

  // Investments
  static const investments = '/investments';
  static String updateInvestment(String id) => '/investments/$id';
  static String deleteInvestment(String id) => '/investments/$id';
  static const userInvestments = '/users/me/investments';
  static String priceHistory(String id) => '/investments/$id/price-history';

  // Portfolio
  static const portfolioMetrics = '/portfolio/me/metrics';
  static const portfolioHistory = '/portfolio/me/price-history';

  // Recommendations
  static const recommendations = '/recommendations/generate';
}
