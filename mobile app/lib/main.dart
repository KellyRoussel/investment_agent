import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'core/network/api_client.dart';
import 'services/auth_service.dart';
import 'services/investments_service.dart';
import 'services/portfolio_service.dart';
import 'services/recommendations_service.dart';
import 'services/users_service.dart';
import 'core/constants/api_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/investments_provider.dart';
import 'providers/recommendations_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/warmup_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF151932),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize core dependencies
  final storage = SecureStorage();
  final apiClient = ApiClient(storage);

  // Initialize services
  final authService = AuthService(storage);
  final investmentsService = InvestmentsService(apiClient);
  final portfolioService = PortfolioService(apiClient);
  final recommendationsService = RecommendationsService(apiClient.dio, storage);
  final usersService = UsersService(apiClient, storage);

  // Create warmup provider and start polling
  final warmupProvider = WarmupProvider(ApiConstants.baseUrl);
  warmupProvider.start();

  // Create auth provider and initialize
  final authProvider = AuthProvider(authService);

  // Wire up auth failure callback
  apiClient.onAuthFailure = () => authProvider.handleAuthFailure();

  // Initialize auth state (check stored tokens)
  await authProvider.initAuth();

  // Pre-load investment profile once backend is confirmed ready
  final profileProvider = ProfileProvider(usersService);
  warmupProvider.addListener(() {
    if (warmupProvider.isBackendReady && authProvider.isAuthenticated) {
      profileProvider.loadStoredProfile();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: warmupProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PortfolioProvider(portfolioService)),
        ChangeNotifierProvider(create: (_) => InvestmentsProvider(investmentsService)),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider(recommendationsService)),
        ChangeNotifierProvider.value(value: profileProvider),
        // Provide services directly for widgets that need them
        Provider.value(value: investmentsService),
      ],
      child: const App(),
    ),
  );
}
