import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/warmup_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/portfolio/portfolio_screen.dart';
import '../screens/investments/investments_screen.dart';
import '../screens/recommendations/recommendations_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/warmup/warmup_screen.dart';
import 'bottom_nav_shell.dart';

class AppRouter {
  static GoRouter create(
      AuthProvider authProvider, WarmupProvider warmupProvider) {
    return GoRouter(
      initialLocation: '/warmup',
      refreshListenable: Listenable.merge([authProvider, warmupProvider]),
      redirect: (context, state) {
        // Keep user on warmup until backend responds
        if (!warmupProvider.isBackendReady) {
          return state.matchedLocation == '/warmup' ? null : '/warmup';
        }

        final isAuth = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        final isWarmup = state.matchedLocation == '/warmup';
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (isLoading) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && (isAuthRoute || isWarmup)) return '/portfolio';
        return null;
      },
      routes: [
        GoRoute(
          path: '/warmup',
          builder: (context, state) => const WarmupScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => BottomNavShell(child: child),
          routes: [
            GoRoute(
              path: '/portfolio',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PortfolioScreen(),
              ),
            ),
            GoRoute(
              path: '/investments',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: InvestmentsScreen(),
              ),
            ),
            GoRoute(
              path: '/recommendations',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: RecommendationsScreen(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
