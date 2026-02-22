import 'package:email_validator/email_validator.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length < 8) {
      return 'Password meets minimum requirements. Consider using 8+ characters with uppercase, lowercase, numbers and special characters for better security.';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final username = value.trim();

    if (username.length < 4) {
      return 'Username must be at least 4 characters';
    }

    if (username.length > 50) {
      return 'Username must not exceed 50 characters';
    }

    final usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernamePattern.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    if (username.startsWith('_') || username.endsWith('_')) {
      return 'Username cannot start or end with underscore';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim();
    final phonePattern = RegExp(r'^\+?[0-9]\d{1,14}$');

    if (!phonePattern.hasMatch(phone)) {
      return 'Please enter a valid phone number (2-15 digits, optional + prefix)';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }

    final zipCode = value.trim();
    final zipPattern = RegExp(r'^\d{3,10}$');

    if (!zipPattern.hasMatch(zipCode)) {
      return 'Please enter a valid ZIP code (3-10 digits)';
    }

    return null;
  }

  static String? validateAge(DateTime? dateOfBirth, int minAge) {
    if (dateOfBirth == null) {
      return 'Date of birth is required';
    }

    final today = DateTime.now();
    final age = today.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);

    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    if (actualAge < minAge) {
      return 'You must be at least $minAge years old';
    }

    if (dateOfBirth.isAfter(today)) {
      return 'Date of birth cannot be in the future';
    }

    if (actualAge > 150) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirm) {
      return 'Passwords do not match';
    }

    return null;
  }

  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  static int getPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength > 4 ? 4 : strength;
  }

  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value.trim());

    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (min != null && amount < min) {
      return 'Amount must be at least \$$min';
    }

    if (max != null && amount > max) {
      return 'Amount must not exceed \$$max';
    }

    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }

    final accountNumber = value.trim();
    final accountPattern = RegExp(r'^\d{8,16}$');

    if (!accountPattern.hasMatch(accountNumber)) {
      return 'Please enter a valid account number (8-16 digits)';
    }

    return null;
  }
}