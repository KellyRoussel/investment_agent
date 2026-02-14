import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/portfolio')) return 0;
    if (location.startsWith('/investments')) return 1;
    if (location.startsWith('/recommendations')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/portfolio');
      case 1:
        context.go('/investments');
      case 2:
        context.go('/recommendations');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) => _onTap(context, index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.cyan,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_center_outlined),
              activeIcon: Icon(Icons.business_center),
              label: 'Investments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Recommend',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
