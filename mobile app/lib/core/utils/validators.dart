String? validateRequired(String? value, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

String? validatePasswordMatch(String? value, String? password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

String? validateMinLength(String? value, int minLength, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  if (value.trim().length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }
  return null;
}

String? validateQuantity(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Quantity is required';
  }
  final num = double.tryParse(value);
  if (num == null || num <= 0) {
    return 'Quantity must be a positive number';
  }
  return null;
}

String? validateIsin(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'ISIN is required';
  }
  final isinRegex = RegExp(r'^[A-Z0-9]{12}$');
  if (!isinRegex.hasMatch(value.trim().toUpperCase())) {
    return 'ISIN must be exactly 12 alphanumeric characters';
  }
  return null;
}

String? validateTicker(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Ticker symbol is required';
  }
  if (value.trim().length > 10) {
    return 'Ticker symbol is too long';
  }
  return null;
}
