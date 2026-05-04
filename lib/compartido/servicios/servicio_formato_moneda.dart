class CurrencyFormatService {
  CurrencyFormatService._();

  static String money(num value, String currency) {
    final normalizedCurrency = currency.trim().isEmpty ? r'$' : currency.trim();
    final isWhole = value % 1 == 0;
    final fixed = isWhole ? value.round().toString() : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = _groupThousands(parts.first);
    final decimalPart = parts.length > 1 ? ',${parts[1]}' : '';

    return '$normalizedCurrency$integerPart$decimalPart';
  }

  static String compactMoney(num value, String currency) {
    final normalizedCurrency = currency.trim().isEmpty ? r'$' : currency.trim();
    final absValue = value.abs();
    if (absValue >= 1000000) {
      return '$normalizedCurrency${_decimalComma(value / 1000000, 1)}M';
    }
    if (absValue >= 1000) {
      return '$normalizedCurrency${_decimalComma(value / 1000, 0)}K';
    }

    return money(value, normalizedCurrency);
  }

  static String _groupThousands(String value) {
    final isNegative = value.startsWith('-');
    final digits = isNegative ? value.substring(1) : value;
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return isNegative ? '-$buffer' : buffer.toString();
  }

  static String _decimalComma(num value, int decimals) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }
}
