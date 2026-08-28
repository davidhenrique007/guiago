import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/app/app.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  testWidgets(
    'GuiaGoApp boots on Splash, then routes a new user to Welcome',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const GuiaGoApp(),
        ),
      );

      // Splash renders immediately, before the settings lookup resolves.
      expect(find.text('GuiaGo'), findsOneWidget);

      await tester.pumpAndSettle();

      // No settings saved yet -> a first-run user lands on Welcome.
      expect(find.text('Bem-vindo ao GuiaGo'), findsOneWidget);
    },
  );
}
