import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/design_system/components/app_bottom_sheet.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';
import 'package:guiago/l10n/app_language.dart';
import 'package:guiago/l10n/app_localizations.dart';
import 'package:guiago/l10n/language_provider.dart';

/// A MaterialApp that follows the chosen language, like the real app.
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage language = ref.watch(languageProvider);
    return MaterialApp(
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ProfileScreen(),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {String? languageCode}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await DriftSettingsRepository(db).saveSettings(
      languageCode == null
          ? Settings.initial.copyWith(userName: 'Ana')
          : Settings.initial.copyWith(
              userName: 'Ana',
              languageCode: languageCode,
            ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const _Harness(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Settings> saved() async =>
      (await DriftSettingsRepository(db).getSettings()).valueOrNull!;

  testWidgets('the default language is Portuguese', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('IDIOMA'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Português'), findsOneWidget);
  });

  testWidgets('a saved English setting shows the profile in English', (
    WidgetTester tester,
  ) async {
    await pump(tester, languageCode: 'en');

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('Notification sound'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Perfil'), findsNothing);
  });

  testWidgets('the picker offers both languages, each in its own name', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();

    for (final String label in <String>['Português', 'English']) {
      expect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('choosing English saves it and switches the screen at once', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text('English'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await saved()).languageCode, 'en');
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Perfil'), findsNothing);
  });

  testWidgets('and back to Portuguese', (WidgetTester tester) async {
    await pump(tester, languageCode: 'en');

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text('Português'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await saved()).languageCode, 'pt');
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('the sound and theme names follow the language', (
    WidgetTester tester,
  ) async {
    await pump(tester, languageCode: 'en');

    expect(find.text('System sound'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Som do sistema'), findsNothing);
  });
}
