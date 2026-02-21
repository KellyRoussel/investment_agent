import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/warmup_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final warmupProvider = context.read<WarmupProvider>();
    _router = AppRouter.create(authProvider, warmupProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InvestTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
