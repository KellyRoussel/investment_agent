import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hoverable;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.hoverable = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.cyan.withValues(alpha: 0.1),
          highlightColor: AppColors.hover,
          child: card,
        ),
      );
    }

    return card;
  }
}
