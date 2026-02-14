import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

String formatCurrency(double? amount, [String currency = 'USD']) {
  if (amount == null) return '-';
  final format = NumberFormat.currency(
    symbol: _currencySymbol(currency),
    decimalDigits: 2,
  );
  return format.format(amount);
}

String formatCompactCurrency(double? amount, [String currency = 'USD']) {
  if (amount == null) return '-';
  final format = NumberFormat.compactCurrency(
    symbol: _currencySymbol(currency),
    decimalDigits: 1,
  );
  return format.format(amount);
}

String formatPercentage(double? value) {
  if (value == null) return '-';
  return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
}

String formatDate(String? dateString) {
  if (dateString == null) return '-';
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(date);
  } catch (_) {
    return dateString;
  }
}

String formatShortDate(String? dateString) {
  if (dateString == null) return '-';
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d').format(date);
  } catch (_) {
    return dateString;
  }
}

String formatChartDate(DateTime date) {
  return DateFormat('MMM d').format(date);
}

Color getGainLossColor(double? value) {
  if (value == null || value == 0) return AppColors.textSecondary;
  return value > 0 ? AppColors.success : AppColors.danger;
}

IconData getGainLossIcon(double? value) {
  if (value == null || value == 0) return Icons.remove;
  return value > 0 ? Icons.trending_up : Icons.trending_down;
}

String formatAssetType(String assetType) {
  return assetType.toUpperCase().replaceAll('_', ' ');
}

String _currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '\u20AC';
    case 'GBP':
      return '\u00A3';
    case 'JPY':
      return '\u00A5';
    case 'CAD':
      return 'CA\$';
    case 'AUD':
      return 'A\$';
    default:
      return currency;
  }
}
