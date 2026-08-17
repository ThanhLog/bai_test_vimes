import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/utils.dart';

void main() {
  group('formatDate', () {
    test('should format date as dd/MM/yyyy', () {
      final date = DateTime(2026, 8, 7);

      expect(formatDate(date), '07/08/2026');
    });
  });

  group('parseNumberVn', () {
    test('should parse integer', () {
      expect(parseNumberVn('1000'), 1000);
    });

    test('should parse Vietnamese thousands separator', () {
      expect(parseNumberVn('1.000'), 1000);
    });

    test('should parse Vietnamese decimal number', () {
      expect(parseNumberVn('1.234,56'), 1234.56);
    });

    test('should return null for empty value', () {
      expect(parseNumberVn(''), isNull);
    });

    test('should return null for invalid value', () {
      expect(parseNumberVn('abc'), isNull);
    });
  });

  group('formatNumberVn', () {
    test('should format integer with thousands separator', () {
      expect(formatNumberVn(1000000), '1.000.000');
    });

    test('should format decimal number', () {
      expect(formatNumberVn(1234.56), '1.234,56');
    });

    test('should format zero', () {
      expect(formatNumberVn(0), '0');
    });
  });

  group('formatNumberVnInput', () {
    test('should format integer input', () {
      expect(
        formatNumberVnInput('1000000'),
        '1.000.000',
      );
    });

    test('should keep decimal input', () {
      expect(
        formatNumberVnInput('1234567,89'),
        '1.234.567,89',
      );
    });

    test('should limit decimal part to two digits', () {
      expect(
        formatNumberVnInput('1234,567'),
        '1.234,56',
      );
    });

    test('should remove invalid characters', () {
      expect(
        formatNumberVnInput('abc123xyz'),
        '123',
      );
    });
  });
}