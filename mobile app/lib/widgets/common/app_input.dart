import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final String? hintText;
  final bool obscureText;
  final bool required;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;

  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.hintText,
    this.obscureText = false,
    this.required = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          readOnly: readOnly,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
