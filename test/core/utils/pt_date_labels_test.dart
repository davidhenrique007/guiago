import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/utils/pt_date_labels.dart';

void main() {
  test('longDate capitalises the weekday and keeps the month lower case', () {
    // 2026-08-14 is a Friday.
    expect(
      PtDateLabels.longDate(DateTime(2026, 8, 14)),
      'Sexta-feira, 14 de agosto',
    );
    expect(
      PtDateLabels.longDate(DateTime(2026, 3, 15)),
      'Domingo, 15 de março',
    );
  });

  test('lists have one entry per weekday and month', () {
    expect(PtDateLabels.weekdays, hasLength(7));
    expect(PtDateLabels.weekdaysShort, hasLength(7));
    expect(PtDateLabels.months, hasLength(12));
  });
}
