import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/tasks/domain/occurrence_state_machine.dart';
import 'package:guiago/features/tasks/domain/occurrence_status.dart';

void main() {
  group('OccurrenceStateMachine', () {
    test('allows every transition documented in master spec §11', () {
      const List<(OccurrenceStatus, OccurrenceStatus)> validPairs =
          <(OccurrenceStatus, OccurrenceStatus)>[
        (OccurrenceStatus.scheduled, OccurrenceStatus.triggered),
        (OccurrenceStatus.triggered, OccurrenceStatus.completed),
        (OccurrenceStatus.triggered, OccurrenceStatus.snoozed),
        (OccurrenceStatus.triggered, OccurrenceStatus.declined),
        (OccurrenceStatus.triggered, OccurrenceStatus.missed),
        (OccurrenceStatus.snoozed, OccurrenceStatus.scheduled),
      ];

      for (final (OccurrenceStatus from, OccurrenceStatus to) in validPairs) {
        expect(
          OccurrenceStateMachine.canTransition(from, to),
          isTrue,
          reason: '$from -> $to should be valid',
        );
      }
    });

    test('rejects transitions that skip TRIGGERED', () {
      expect(
        OccurrenceStateMachine.canTransition(
          OccurrenceStatus.scheduled,
          OccurrenceStatus.completed,
        ),
        isFalse,
      );
    });

    test('rejects transitions out of a terminal status', () {
      for (final OccurrenceStatus terminal in <OccurrenceStatus>[
        OccurrenceStatus.completed,
        OccurrenceStatus.declined,
        OccurrenceStatus.missed,
        OccurrenceStatus.cancelled,
      ]) {
        expect(OccurrenceStateMachine.isTerminal(terminal), isTrue);
        expect(
          OccurrenceStateMachine.canTransition(
            terminal,
            OccurrenceStatus.scheduled,
          ),
          isFalse,
        );
      }
    });

    test('transition() returns Success for a valid move', () {
      final result = OccurrenceStateMachine.transition(
        OccurrenceStatus.triggered,
        OccurrenceStatus.completed,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, OccurrenceStatus.completed);
    });

    test('transition() returns Fail(SchedulingFailure) for an invalid move',
        () {
      final result = OccurrenceStateMachine.transition(
        OccurrenceStatus.completed,
        OccurrenceStatus.triggered,
      );
      expect(result.isFailure, isTrue);
    });
  });
}
