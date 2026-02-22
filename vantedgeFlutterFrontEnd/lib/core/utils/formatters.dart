import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatPhone(String phone) {
    if (phone.isEmpty) return phone;

    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    } else if (phone.startsWith('+')) {
      if (cleaned.length > 10) {
        return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 6)} ${cleaned.substring(6)}';
      }
      return '+$cleaned';
    }

    return phone;
  }

  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    try {
      final formatter = DateFormat(format);
      return formatter.format(date);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDateTime(
    DateTime dateTime, {
    String format = 'MMM dd, yyyy hh:mm a',
  }) {
    return formatDate(dateTime, format: format);
  }

  static String formatCurrency(
    double amount, {
    String symbol = '\$',
    int decimals = 2,
    String locale = 'en_US',
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimals,
      );
      return formatter.format(amount);
    } catch (e) {
      return '$symbol${amount.toStringAsFixed(decimals)}';
    }
  }

  static String formatCompactNumber(num number) {
    try {
      final formatter = NumberFormat.compact();
      return formatter.format(number);
    } catch (e) {
      return number.toString();
    }
  }

  static String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '$username***@$domain';
    }

    final visibleChars = username.substring(0, 2);
    final maskedPart = '*' * (username.length - 2);

    return '$visibleChars$maskedPart@$domain';
  }

  static String maskPhone(String phone) {
    if (phone.isEmpty) return phone;

    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length < 4) return phone;

    final lastFour = cleaned.substring(cleaned.length - 4);
    final masked = '*' * (cleaned.length - 4);

    return '$masked$lastFour';
  }

  static String maskAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) return accountNumber;

    if (accountNumber.length <= 4) {
      return accountNumber;
    }

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final masked = '*' * (accountNumber.length - 4);

    return '$masked$lastFour';
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        final formats = [
          'yyyy-MM-dd',
          'MM/dd/yyyy',
          'dd/MM/yyyy',
          'MMM dd, yyyy',
          'dd MMM yyyy',
        ];

        for (final format in formats) {
          try {
            final formatter = DateFormat(format);
            return formatter.parse(dateStr);
          } catch (_) {
            continue;
          }
        }

        return null;
      } catch (_) {
        return null;
      }
    }
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  static String formatPercentage(double value, {int decimals = 2}) {
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}