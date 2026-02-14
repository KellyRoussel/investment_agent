import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonPadding = switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    };

    final fontSize = switch (size) {
      AppButtonSize.sm => 12.0,
      AppButtonSize.md => 14.0,
      AppButtonSize.lg => 16.0,
    };

    if (variant == AppButtonVariant.primary || variant == AppButtonVariant.danger) {
      final gradient = variant == AppButtonVariant.primary
          ? AppColors.gradientCyanPurple
          : AppColors.gradientDanger;
      final textColor = variant == AppButtonVariant.primary ? Colors.black : Colors.white;

      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: onPressed != null && !isLoading ? gradient : null,
            color: onPressed == null || isLoading ? AppColors.textMuted.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: buttonPadding,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          height: fontSize + 4,
                          width: fontSize + 4,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor,
                          ),
                        )
                      : Row(
                          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: fontSize + 4, color: textColor),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Secondary and Ghost variants
    final borderColor = variant == AppButtonVariant.secondary ? AppColors.border : Colors.transparent;
    final bgColor = variant == AppButtonVariant.secondary ? AppColors.surface : Colors.transparent;
    final txtColor = AppColors.textPrimary;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null ? Icon(icon, size: fontSize + 4) : const SizedBox.shrink(),
        label: isLoading
            ? SizedBox(
                height: fontSize + 4,
                width: fontSize + 4,
                child: CircularProgressIndicator(strokeWidth: 2, color: txtColor),
              )
            : Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: txtColor,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
