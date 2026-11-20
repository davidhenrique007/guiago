import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/design_system/components/app_bottom_sheet.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Settings> saved() async =>
      (await DriftSettingsRepository(db).getSettings()).valueOrNull!;

  Future<void> seed() => DriftSettingsRepository(db).saveSettings(
        Settings.initial.copyWith(userName: 'Ana', mainObjective: 'Estudar'),
      );

  testWidgets('edits the name and the objective', (
    WidgetTester tester,
  ) async {
    await seed();
    await pumpProfile(tester);

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bia');
    await tester.enterText(
      find.byType(TextField).last,
      'Correr',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Correr'), findsOneWidget);
    final Settings s = await saved();
    expect(s.userName, 'Bia');
    expect(s.mainObjective, 'Correr');
  });

  testWidgets('an empty name is rejected and nothing is saved', (
    WidgetTester tester,
  ) async {
    await seed();
    await pumpProfile(tester);

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escreve o teu nome.'), findsOneWidget);
    expect((await saved()).userName, 'Ana');
  });

  testWidgets('toggling notifications persists', (WidgetTester tester) async {
    await seed();
    await pumpProfile(tester);
    expect(find.text('Ativadas'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Desativadas'), findsOneWidget);
    expect((await saved()).notificationsEnabled, isFalse);
  });

  testWidgets('picking a new snooze duration persists', (
    WidgetTester tester,
  ) async {
    await seed();
    await pumpProfile(tester);

    await tester.tap(find.text('Snooze padrão'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text('15 min'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await saved()).defaultSnoozeMinutes, 15);
  });
}
