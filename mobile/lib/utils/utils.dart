String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

double? parseNumberVn(String input) {
  var value = input.trim();
  if (value.isEmpty) {
    return null;
  }

  final hasDot = value.contains('.');
  final hasComma = value.contains(',');

  if (hasDot && hasComma) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    value = value.replaceAll(',', '.');
  } else if (hasDot) {
    final dotCount = '.'.allMatches(value).length;
    final decimalPart = value.split('.').last;
    final looksLikeThousandsSeparator =
        dotCount > 1 || decimalPart.length == 3;

    if (looksLikeThousandsSeparator) {
      value = value.replaceAll('.', '');
    }
  }

  return double.tryParse(value);
}

String formatNumberVn(double value) {
  if (!value.isFinite) {
    return '0';
  }

  final isInteger = value == value.roundToDouble();
  final parts = value.toStringAsFixed(isInteger ? 0 : 2).split('.');
  final rawIntegerPart = parts[0];
  final isNegative = rawIntegerPart.startsWith('-');
  final digits = isNegative ? rawIntegerPart.substring(1) : rawIntegerPart;
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  final integerPart = isNegative ? '-${buffer.toString()}' : buffer.toString();

  if (parts.length > 1 && parts[1] != '00') {
    return '$integerPart,${parts[1]}';
  }

  return integerPart;
}

String formatNumberVnInput(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9,]'), '');
  if (cleaned.isEmpty) {
    return '';
  }

  final commaIndex = cleaned.indexOf(',');
  final hasComma = commaIndex != -1;
  final rawIntegerPart = hasComma ? cleaned.substring(0, commaIndex) : cleaned;
  final rawDecimalPart = hasComma
      ? cleaned.substring(commaIndex + 1).replaceAll(',', '')
      : '';

  final integerPart = rawIntegerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final normalizedIntegerPart = integerPart.isEmpty ? '0' : integerPart;
  final buffer = StringBuffer();

  for (var i = 0; i < normalizedIntegerPart.length; i++) {
    if (i > 0 && (normalizedIntegerPart.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(normalizedIntegerPart[i]);
  }

  if (!hasComma) {
    return buffer.toString();
  }

  final decimalPart = rawDecimalPart.length > 2
      ? rawDecimalPart.substring(0, 2)
      : rawDecimalPart;

  return '${buffer.toString()},$decimalPart';
}
