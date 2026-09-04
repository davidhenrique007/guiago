import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/scheduler/domain/alarm_id_generator.dart';

void main() {
  group('AlarmIdGenerator.fromOccurrenceId', () {
    test('is deterministic for the same input', () {
      const String occurrenceId = 'occ-123-abc';
      final int first = AlarmIdGenerator.fromOccurrenceId(occurrenceId);
      final int second = AlarmIdGenerator.fromOccurrenceId(occurrenceId);
      expect(first, second);
    });

    test('is always a positive 31-bit int', () {
      for (final String id in <String>[
        'a',
        'occurrence-1',
        '550e8400-e29b-41d4-a716-446655440000',
        '',
      ]) {
        final int hash = AlarmIdGenerator.fromOccurrenceId(id);
        expect(hash, greaterThanOrEqualTo(0));
        expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('different ids very likely produce different hashes', () {
      final int a = AlarmIdGenerator.fromOccurrenceId('occurrence-a');
      final int b = AlarmIdGenerator.fromOccurrenceId('occurrence-b');
      expect(a, isNot(b));
    });
  });
}
