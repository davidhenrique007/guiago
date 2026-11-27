import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/l10n/app_language.dart';
import 'package:guiago/l10n/app_localizations.dart';

void main() {
  final AppLocalizations pt = AppLocalizations.forLocale(const Locale('pt'));
  final AppLocalizations en = AppLocalizations.forLocale(const Locale('en'));

  group('AppLanguage', () {
    test('fromCode finds each language and falls back to Portuguese', () {
      for (final AppLanguage language in AppLanguage.values) {
        expect(AppLanguage.fromCode(language.code), language);
      }
      expect(AppLanguage.fromCode('xx'), AppLanguage.portuguese);
      expect(AppLanguage.fromCode(null), AppLanguage.portuguese);
    });

    test('each language is named in itself', () {
      expect(AppLanguage.portuguese.label, 'Português');
      expect(AppLanguage.english.label, 'English');
      expect(AppLanguage.english.locale, const Locale('en'));
    });
  });

  group('AppLocalizations', () {
    test('anything but English is Portuguese', () {
      expect(AppLocalizations.forLocale(const Locale('en')).navHome, 'Home');
      expect(AppLocalizations.forLocale(const Locale('pt')).navHome, 'Início');
      expect(AppLocalizations.forLocale(const Locale('fr')).navHome, 'Início');
    });

    test('both languages are supported by the delegate', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('pt')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
      expect(
        AppLocalizations.delegate.isSupported(const Locale('fr')),
        isFalse,
      );
    });

    test('every text exists in both languages and English differs', () {
      final List<(String, String)> pairs = <(String, String)>[
        (pt.navHome, en.navHome),
        (pt.profileTitle, en.profileTitle),
        (pt.rowSound, en.rowSound),
        (pt.rowLanguage, en.rowLanguage),
        (pt.calendarTitle, en.calendarTitle),
        (pt.viewDay, en.viewDay),
        (pt.newTask, en.newTask),
        (pt.statusMissed, en.statusMissed),
        (pt.detailEditHint, en.detailEditHint),
        (pt.greetingMorning, en.greetingMorning),
        (pt.photoTitle, en.photoTitle),
        (pt.photoGallery, en.photoGallery),
        (pt.photoRemove, en.photoRemove),
      ];
      for (final (String a, String b) in pairs) {
        expect(a, isNotEmpty);
        expect(b, isNotEmpty);
        expect(a, isNot(b));
      }
    });

    test('texts with values', () {
      expect(pt.minutes(10), '10 min');
      expect(en.dayTasks(3), 'Tasks for the day (3)');
      expect(pt.dayTasks(3), 'Tarefas do dia (3)');
      expect(pt.yourDay('07:00–22:00'), 'O teu dia: 07:00–22:00');
      expect(en.yourDay('07:00–22:00'), 'Your day: 07:00–22:00');
      expect(en.soundPreview('Soft'), 'Listen to Soft');
    });

    test('task counts are singular and plural', () {
      expect(pt.taskCount(1), '1 tarefa');
      expect(pt.taskCount(4), '4 tarefas');
      expect(en.taskCount(1), '1 task');
      expect(en.taskCount(4), '4 tasks');
    });
  });

  group('dates', () {
    final DateTime friday = DateTime(2026, 8, 14);

    test('Portuguese keeps the original format', () {
      expect(pt.longDate(friday), 'Sexta-feira, 14 de agosto');
      expect(pt.weekdayShort(7), 'Dom');
      expect(pt.monthName(3), 'Março');
    });

    test('English puts the month first', () {
      expect(en.longDate(friday), 'Friday, August 14');
      expect(en.weekdayShort(1), 'Mon');
      expect(en.monthName(12), 'December');
    });

    test('all weekdays and months have a name', () {
      for (int d = 1; d <= 7; d++) {
        expect(pt.weekdayName(d), isNotEmpty);
        expect(en.weekdayName(d), isNotEmpty);
        expect(en.weekdayShort(d), hasLength(3));
      }
      for (int m = 1; m <= 12; m++) {
        expect(pt.monthName(m), isNotEmpty);
        expect(en.monthName(m), isNotEmpty);
      }
    });
  });

  testWidgets('context.l10n falls back to Portuguese without delegates', (
    WidgetTester tester,
  ) async {
    late AppLocalizations found;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            found = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(found.navHome, 'Início');
  });

  testWidgets('context.l10n follows the installed locale', (
    WidgetTester tester,
  ) async {
    late AppLocalizations found;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (BuildContext context) {
            found = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(found.navHome, 'Home');
  });
}
