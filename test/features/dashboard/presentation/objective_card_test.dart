import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/dashboard/presentation/widgets/objective_card.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: ObjectiveCard())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the saved objective', (WidgetTester tester) async {
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(mainObjective: 'Estudar todos os dias'),
    );
    await pump(tester);

    expect(find.text('OBJETIVO'), findsOneWidget);
    expect(find.text('Estudar todos os dias'), findsOneWidget);
  });

  testWidgets('shows a hint when there is no objective', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    expect(find.text('Ainda sem objetivo definido.'), findsOneWidget);
    expect(find.text('Define o teu objetivo no Perfil.'), findsOneWidget);
  });
}
