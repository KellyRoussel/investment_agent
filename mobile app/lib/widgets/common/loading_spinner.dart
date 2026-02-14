import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum SpinnerSize { sm, md, lg }

class LoadingSpinner extends StatelessWidget {
  final SpinnerSize size;

  const LoadingSpinner({super.key, this.size = SpinnerSize.md});

  @override
  Widget build(BuildContext context) {
    final dimension = switch (size) {
      SpinnerSize.sm => 16.0,
      SpinnerSize.md => 32.0,
      SpinnerSize.lg => 48.0,
    };

    final strokeWidth = switch (size) {
      SpinnerSize.sm => 2.0,
      SpinnerSize.md => 3.0,
      SpinnerSize.lg => 4.0,
    };

    return SizedBox(
      width: dimension,
      height: dimension,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: AppColors.cyan,
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: LoadingSpinner(size: SpinnerSize.lg)),
    );
  }
}
