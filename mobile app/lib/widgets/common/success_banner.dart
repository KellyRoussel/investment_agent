import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const SuccessBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.success, fontSize: 14),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: AppColors.success, size: 18),
            ),
        ],
      ),
    );
  }
}
