import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/features/onboarding/domain/day_window.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';

void main() {
  const DayWindow window = DayWindow(startMinutes: 450, endMinutes: 1435);

  test('is built from the settings', () {
    final DayWindow fromSettings = DayWindow.fromSettings(
      Settings.initial.copyWith(dayStartMinutes: 450, dayEndMinutes: 1435),
    );

    expect(fromSettings.startMinutes, 450);
    expect(fromSettings.endMinutes, 1435);
  });

  test('contains is inclusive at both ends', () {
    expect(window.contains(450), isTrue);
    expect(window.contains(1435), isTrue);
    expect(window.contains(449), isFalse);
    expect(window.contains(1436), isFalse);
  });

  test('containsTime uses the hour and the minute', () {
    expect(window.containsTime(DateTime(2030, 1, 1, 7, 30)), isTrue);
    expect(window.containsTime(DateTime(2030, 1, 1, 7, 29)), isFalse);
    expect(window.containsTime(DateTime(2030, 1, 1, 23, 55)), isTrue);
  });

  test('label is HH:MM–HH:MM', () {
    expect(window.label, '07:30–23:55');
  });

  test('suggest keeps a time inside and moves one outside to the edge', () {
    expect(window.suggest(540), 540);
    expect(window.suggest(60), 450);
    expect(window.suggest(1439), 1435);
  });
}
