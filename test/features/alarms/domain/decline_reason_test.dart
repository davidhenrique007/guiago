import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/alarms/domain/decline_reason.dart';

void main() {
  group('DeclineReasonLabel', () {
    test('every reason from master spec §24 has the exact expected label', () {
      const Map<DeclineReason, String> expected = <DeclineReason, String>{
        DeclineReason.noTime: 'Sem tempo',
        DeclineReason.notAvailable: 'Não disponível',
        DeclineReason.noLongerNeeded: 'Não é mais necessário',
        DeclineReason.forgot: 'Esqueci',
        DeclineReason.other: 'Outro',
      };

      for (final DeclineReason reason in DeclineReason.values) {
        expect(reason.label, expected[reason]);
      }
    });

    test('no two reasons share a label', () {
      final Set<String> labels =
          DeclineReason.values.map((DeclineReason r) => r.label).toSet();
      expect(labels, hasLength(DeclineReason.values.length));
    });
  });
}
