import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?)? onChanged;
  final String? errorText;
  final bool required;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.errorText,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.danger, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
