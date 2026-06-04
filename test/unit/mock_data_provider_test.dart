// test/unit/mock_data_provider_test.dart
//
// Unit tests for the maskNop() privacy utility and relativeTime() helper.

import 'package:flutter_test/flutter_test.dart';
import 'package:integratax/providers/mock_data_provider.dart';

void main() {
  group('maskNop()', () {
    test('standard 7-segment NOP is masked correctly', () {
      const input = '32.04.010.001.001.0001.0';
      final result = maskNop(input);
      // Province (32) and city (04) stay visible; the rest is masked.
      expect(result, equals('32.04.***.***.***.****.*'));
      final parts = result.split('.');
      expect(parts[0], equals('32'));
      expect(parts[1], equals('04'));
      expect(parts[2], equals('***'));
      expect(parts[3], equals('***'));
      expect(parts[4], equals('***'));
      expect(parts[5], equals('****'));
      expect(parts[6], equals('*'));
    });

    test('masked segments contain only asterisks', () {
      final result = maskNop('32.04.010.001.001.0001.0');
      final parts = result.split('.');
      for (final part in parts.skip(2)) {
        expect(
          RegExp(r'^\*+$').hasMatch(part),
          isTrue,
          reason: 'Segment "$part" should contain only asterisks',
        );
      }
    });

    test('masked segment length matches original segment length', () {
      const input = '32.04.010.001.001.0001.0';
      final original = input.split('.');
      final masked = maskNop(input).split('.');
      for (int i = 2; i < original.length; i++) {
        expect(
          masked[i].length,
          equals(original[i].length),
          reason: 'Segment $i: masked length should match original',
        );
      }
    });

    test('short NOP with fewer than 3 segments is returned unchanged', () {
      const input = '32.04';
      expect(maskNop(input), equals('32.04'));
    });

    test('single segment NOP is returned unchanged', () {
      expect(maskNop('32'), equals('32'));
    });

    test('empty string is returned unchanged', () {
      expect(maskNop(''), equals(''));
    });

    test('NOP with non-standard segment lengths is still masked', () {
      const input = '51.71.010.001.001.0019.0';
      final result = maskNop(input);
      expect(result, startsWith('51.71.'));
      final parts = result.split('.');
      expect(parts[2], allOf(isNotEmpty, matches(RegExp(r'^\*+$'))));
    });

    test('province and city codes are preserved exactly', () {
      final result = maskNop('99.88.123.456.789.0001.0');
      expect(result.startsWith('99.88.'), isTrue);
    });
  });

  group('relativeTime()', () {
    test('returns "Baru saja" for timestamps less than 1 minute ago', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      expect(relativeTime(recent), equals('Baru saja'));
    });

    test('returns minutes for timestamps 1–59 minutes ago', () {
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      expect(relativeTime(fiveMinutesAgo), equals('5 menit lalu'));
    });

    test('returns hours for timestamps 1–23 hours ago', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      expect(relativeTime(twoHoursAgo), equals('2 jam lalu'));
    });

    test('returns days for timestamps 24+ hours ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(relativeTime(threeDaysAgo), equals('3 hari lalu'));
    });

    test('returns "Baru saja" for a timestamp exactly now', () {
      expect(relativeTime(DateTime.now()), equals('Baru saja'));
    });
  });
}
